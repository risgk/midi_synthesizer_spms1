/*
 * MIDI Synthesizer SPMS-1 (type-2) offline renderer
 *
 * Runs spms1_main.c, the Spinel output the sketch runs, faster than real time and writes what it
 * puts out to a WAV file. This file stands in for spms1_type2.ino: the MIDI tables and handlers are
 * the sketch's, and the MIDI comes from a patch and a score instead of a cable. Unlike
 * sim_offline/spms1_output_wav.rb, the whole synth runs -- the signals bus, the run order, the NRPN
 * table and the CC assignments -- so a patch is heard as the device would play it.
 *
 *   spms1_render [--patch FILE] [--score FILE] [--seconds N] [--out FILE]
 *
 * --patch: MIDI bytes in hex, as the editor copies them with Format "MIDI bytes (hex)"; ';' starts
 *          a comment. Taken before the first sample, after the synth has written its default patch.
 * --score: one MIDI message (or several) a line, after the time in seconds: "1.5 80 3C 40".
 *          Without it, note 60 is played from 0 s to 1 s.
 * --seconds: the length of the render (default 4).
 * --out:   the WAV file (default spms1_render.wav): 48 kHz, 24 bit, stereo, as the I2S DAC gets it.
 */
#include <ctype.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int Spms1_main(int argc, char **argv);

/* The linker keeps runtime code that the synth never calls but that refers to these, which
   upstream define in files the sketch does not vendor. urandom fails closed on the 0. */
bool sp_convert_soft;
bool sp_convert_failed;
int sp_crypto_entropy(unsigned char *out, int nbytes) { (void)out; (void)nbytes; return 0; }

#if !defined(__APPLE__)
/* sp_str.c's String#crypt calls libc's crypt, which Windows lacks and glibc keeps in libcrypt;
   nothing here reaches it. */
char *crypt(const char *key, const char *salt) {
  (void)key; (void)salt;
  return NULL;
}
#endif

/* ---- MIDI state, as in spms1_type2.ino ---- */

#define SPMS1_NRPN_SIZE (512)

static uint8_t g_midi_note_on_pitch[16] = {60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60};
static uint8_t g_midi_note_on_state[16];
static uint8_t g_midi_cc_values[16][128];
static int16_t g_midi_pitch_bend[16];
static uint8_t g_midi_nrpn_values[16][SPMS1_NRPN_SIZE];
static uint8_t g_midi_nrpn_msb[16];
static uint8_t g_midi_nrpn_lsb[16];
static uint8_t g_midi_nrpn_selected[16];

void set_midi_note_on_pitch(uint8_t ch, uint8_t v) { if (ch < 16) g_midi_note_on_pitch[ch] = v; }
uint8_t get_midi_note_on_pitch(uint8_t ch) { return (ch < 16) ? g_midi_note_on_pitch[ch] : 0; }
void set_midi_note_on_state(uint8_t ch, uint8_t v) { if (ch < 16) g_midi_note_on_state[ch] = v; }
uint8_t get_midi_note_on_state(uint8_t ch) { return (ch < 16) ? g_midi_note_on_state[ch] : 0; }
void set_midi_pitch_bend(uint8_t ch, int32_t v) { if (ch < 16) g_midi_pitch_bend[ch] = (int16_t)v; }
int32_t get_midi_pitch_bend(uint8_t ch) { return (ch < 16) ? g_midi_pitch_bend[ch] : 0; }

void set_midi_cc_value(uint8_t ch, uint8_t n, uint8_t v) {
  if (ch < 16 && n < 128) g_midi_cc_values[ch][n] = v;
}
uint8_t get_midi_cc_value(uint8_t ch, uint8_t n) {
  return (ch < 16 && n < 128) ? g_midi_cc_values[ch][n] : 0;
}

void set_midi_nrpn_value(uint8_t ch, int32_t i, uint8_t v) {
  if (ch < 16 && i >= 0 && i < SPMS1_NRPN_SIZE) g_midi_nrpn_values[ch][i] = v;
}
uint8_t get_midi_nrpn_value(uint8_t ch, int32_t i) {
  return (ch < 16 && i >= 0 && i < SPMS1_NRPN_SIZE) ? g_midi_nrpn_values[ch][i] : 0;
}

static void handle_midi_nrpn_cc(uint8_t ch, uint8_t number, uint8_t value) {
  if (number == 99) {
    g_midi_nrpn_msb[ch] = value;
    g_midi_nrpn_selected[ch] = 1;
  } else if (number == 98) {
    g_midi_nrpn_lsb[ch] = value;
    g_midi_nrpn_selected[ch] = 1;
  } else if (number == 101 || number == 100) {
    g_midi_nrpn_selected[ch] = 0;
  } else if (number == 6 && g_midi_nrpn_selected[ch]) {
    set_midi_nrpn_value(ch, ((int32_t)g_midi_nrpn_msb[ch] << 7) | g_midi_nrpn_lsb[ch], value);
  }
}

/* A note-on of velocity 0 is a note-off, as the MIDI library the sketch uses treats it. */
static void handle_midi_message(uint8_t status, uint8_t d1, uint8_t d2) {
  uint8_t ch = status & 0x0F;
  switch (status & 0xF0) {
  case 0x90:
    if (d2 != 0) {
      set_midi_note_on_pitch(ch, d1);
      set_midi_note_on_state(ch, 1);
      break;
    }
    /* fall through */
  case 0x80:
    if (d1 == g_midi_note_on_pitch[ch]) set_midi_note_on_state(ch, 0);
    break;
  case 0xB0:
    set_midi_cc_value(ch, d1, d2);
    handle_midi_nrpn_cc(ch, d1, d2);
    break;
  case 0xE0:
    set_midi_pitch_bend(ch, (((int32_t)d2 << 7) | d1) - 8192);
    break;
  }
}

/* The bytes are parsed as a stream, running status included, so a line may carry several
   messages. Real-time bytes are skipped, and so is SysEx. */
static uint8_t g_parse_status;
static uint8_t g_parse_data[2];
static int g_parse_count;
static int g_parse_in_sysex;

static void midi_parse_byte(uint8_t b) {
  if (b >= 0xF8) {
    return;
  } else if (b == 0xF0) {
    g_parse_in_sysex = 1;
  } else if (b >= 0x80) {
    g_parse_in_sysex = 0;
    g_parse_status = (b < 0xF0) ? b : 0;
    g_parse_count = 0;
  } else if (!g_parse_in_sysex && g_parse_status) {
    int length = ((g_parse_status & 0xE0) == 0xC0) ? 1 : 2;
    g_parse_data[g_parse_count++] = b;
    if (g_parse_count == length) {
      handle_midi_message(g_parse_status, g_parse_data[0], (length == 2) ? g_parse_data[1] : 0);
      g_parse_count = 0;
    }
  }
}

/* ---- The patch and the score ---- */

typedef struct {
  long frame;
  size_t order;  /* the place in the score, which keeps messages at the same time in order */
  int size;
  uint8_t bytes[64];
} Event;

static uint8_t *g_patch;
static size_t g_patch_size;
static Event *g_events;
static size_t g_num_events;
static size_t g_next_event;

static void die(const char *message, const char *detail) {
  fprintf(stderr, "%s%s\n", message, detail ? detail : "");
  exit(1);
}

static char *read_file(const char *path) {
  FILE *f = fopen(path, "rb");
  if (!f) die("Could not open ", path);
  fseek(f, 0, SEEK_END);
  long size = ftell(f);
  fseek(f, 0, SEEK_SET);
  char *text = (char *)malloc((size_t)size + 1);
  if (fread(text, 1, (size_t)size, f) != (size_t)size) die("Could not read ", path);
  text[size] = '\0';
  fclose(f);
  return text;
}

/* Parses hex bytes up to the end of the line or a ';', appending them to *bytes. */
static const char *parse_hex_bytes(const char *p, uint8_t **bytes, size_t *size, size_t *capacity) {
  while (*p && *p != '\n' && *p != ';') {
    if (isspace((unsigned char)*p) || *p == ',') {
      p++;
      continue;
    }
    char *end;
    long v = strtol(p, &end, 16);
    if (end == p || v < 0 || v > 0xFF) die("Not a hex byte: ", p);
    if (*size == *capacity) {
      *capacity = *capacity ? *capacity * 2 : 256;
      *bytes = (uint8_t *)realloc(*bytes, *capacity);
    }
    (*bytes)[(*size)++] = (uint8_t)v;
    p = end;
  }
  while (*p && *p != '\n') p++;
  return p;
}

static void load_patch(const char *path) {
  char *text = read_file(path);
  size_t capacity = 0;
  for (const char *p = text; *p; ) {
    p = parse_hex_bytes(p, &g_patch, &g_patch_size, &capacity);
    if (*p) p++;
  }
  free(text);
}

static int compare_events(const void *a, const void *b) {
  const Event *ea = (const Event *)a, *eb = (const Event *)b;
  if (ea->frame != eb->frame) return (ea->frame > eb->frame) ? 1 : -1;
  return (ea->order > eb->order) - (ea->order < eb->order);
}

static void add_event(double seconds, const uint8_t *bytes, size_t size) {
  if (size > sizeof(g_events[0].bytes)) die("Too many bytes on a line of the score", NULL);
  g_events = (Event *)realloc(g_events, (g_num_events + 1) * sizeof(Event));
  Event *e = &g_events[g_num_events++];
  e->frame = lround(seconds * 48000.0);
  e->order = g_num_events - 1;
  e->size = (int)size;
  memcpy(e->bytes, bytes, size);
}

static void load_score(const char *path) {
  char *text = read_file(path);
  for (const char *p = text; *p; ) {
    while (*p == ' ' || *p == '\t' || *p == '\r') p++;
    if (*p == '\n') { p++; continue; }
    if (*p == ';' || !*p) {
      while (*p && *p != '\n') p++;
      continue;
    }
    char *end;
    double seconds = strtod(p, &end);
    if (end == p || seconds < 0.0) die("A line of the score must start with the time in seconds: ", p);
    uint8_t *bytes = NULL;
    size_t size = 0, capacity = 0;
    p = parse_hex_bytes(end, &bytes, &size, &capacity);
    add_event(seconds, bytes, size);
    free(bytes);
  }
  free(text);
  qsort(g_events, g_num_events, sizeof(Event), compare_events);
}

/* ---- Audio, the sketch's side of the ffi_func interface ---- */

static uint32_t g_sample_rate = 48000;
static uint32_t g_audio_buffers = 2;
static uint32_t g_audio_buffer_words = 64;

static const char *g_out_path = "spms1_render.wav";
static long g_total_frames = 4 * 48000;
static long g_frames;
static FILE *g_wav;
static float g_peak[2];
static uint32_t g_hash = 2166136261u;  /* FNV-1a over the PCM bytes, to tell two renders apart */

void set_sample_rate(int32_t v) { g_sample_rate = (uint32_t)v; }
int32_t get_sample_rate(void) { return (int32_t)g_sample_rate; }
void set_audio_buffers(int32_t v) { g_audio_buffers = (uint32_t)v; }
int32_t get_audio_buffers(void) { return (int32_t)g_audio_buffers; }
void set_audio_buffer_words(int32_t v) { g_audio_buffer_words = (uint32_t)v; }
int32_t get_audio_buffer_words(void) { return (int32_t)g_audio_buffer_words; }
void start_debug_measure(void) {}
void stop_debug_measure(void) {}
void stop_audio(void) {}

static void write_u32(uint32_t v) {
  uint8_t b[4] = {(uint8_t)v, (uint8_t)(v >> 8), (uint8_t)(v >> 16), (uint8_t)(v >> 24)};
  fwrite(b, 1, 4, g_wav);
}

static void write_u16(uint16_t v) {
  uint8_t b[2] = {(uint8_t)v, (uint8_t)(v >> 8)};
  fwrite(b, 1, 2, g_wav);
}

static void write_wav_header(uint32_t data_size) {
  fwrite("RIFF", 1, 4, g_wav);
  write_u32(36 + data_size);
  fwrite("WAVEfmt ", 1, 8, g_wav);
  write_u32(16);
  write_u16(1);                      /* PCM */
  write_u16(2);                      /* stereo */
  write_u32(g_sample_rate);
  write_u32(g_sample_rate * 2 * 3);  /* byte rate */
  write_u16(2 * 3);                  /* block align */
  write_u16(24);                     /* bits per sample */
  fwrite("data", 1, 4, g_wav);
  write_u32(data_size);
}

/* Called once the synth has written its default patch and its default CC values, so the patch
   given here replaces them, as one sent from the editor after power-up does. */
void start_audio(void) {
  for (size_t i = 0; i < g_patch_size; i++) midi_parse_byte(g_patch[i]);
  g_wav = fopen(g_out_path, "wb");
  if (!g_wav) die("Could not open ", g_out_path);
  write_wav_header(0);
}

static void write_sample(float v, int channel) {
  float a = fabsf(v);
  if (a > g_peak[channel]) g_peak[channel] = a;
  long s = lroundf(v * 8388607.0f);
  if (s > 8388607) s = 8388607;
  if (s < -8388608) s = -8388608;
  uint8_t b[3] = {(uint8_t)s, (uint8_t)(s >> 8), (uint8_t)(s >> 16)};
  for (int i = 0; i < 3; i++) g_hash = (g_hash ^ b[i]) * 16777619u;
  fwrite(b, 1, 3, g_wav);
}

static double to_dbfs(float v) { return (v > 0.0f) ? 20.0 * log10(v) : -INFINITY; }

/* The score's messages arrive as the frame they are timed at goes out, so the synth takes them at
   its next buffer, as it takes MIDI on the device. */
void write_to_audio_buffer(float l, float r) {
  while (g_next_event < g_num_events && g_events[g_next_event].frame <= g_frames) {
    const Event *e = &g_events[g_next_event++];
    for (int i = 0; i < e->size; i++) midi_parse_byte(e->bytes[i]);
  }

  write_sample(l, 0);
  write_sample(r, 1);
  if (++g_frames < g_total_frames) return;

  fseek(g_wav, 0, SEEK_SET);
  write_wav_header((uint32_t)(g_frames * 2 * 3));
  fclose(g_wav);
  printf("%s: %.3f s, peak L %.1f dBFS, R %.1f dBFS, hash %08x\n", g_out_path,
         (double)g_frames / g_sample_rate, to_dbfs(g_peak[0]), to_dbfs(g_peak[1]), (unsigned)g_hash);
  exit(0);
}

/* ---- Entry ---- */

static void usage(const char *name) {
  fprintf(stderr, "usage: %s [--patch FILE] [--score FILE] [--seconds N] [--out FILE]\n", name);
  exit(1);
}

int main(int argc, char **argv) {
  const char *score = NULL;
  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "--patch") && i + 1 < argc) {
      load_patch(argv[++i]);
    } else if (!strcmp(argv[i], "--score") && i + 1 < argc) {
      score = argv[++i];
    } else if (!strcmp(argv[i], "--seconds") && i + 1 < argc) {
      double seconds = strtod(argv[++i], NULL);
      if (!(seconds > 0.0)) usage(argv[0]);
      g_total_frames = lround(seconds * 48000.0);
      if (g_total_frames < 1) g_total_frames = 1;
    } else if (!strcmp(argv[i], "--out") && i + 1 < argc) {
      g_out_path = argv[++i];
    } else {
      usage(argv[0]);
    }
  }

  if (score) {
    load_score(score);
  } else {
    static const uint8_t note_on[] = {0x90, 60, 100};
    static const uint8_t note_off[] = {0x80, 60, 64};
    add_event(0.0, note_on, sizeof(note_on));
    add_event(1.0, note_off, sizeof(note_off));
  }

  char *spinel_argv[] = {argv[0], NULL};
  return Spms1_main(1, spinel_argv);
}
