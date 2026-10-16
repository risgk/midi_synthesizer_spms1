/*
 * MIDI Synthesizer SPMS-1 (type-2) offline renderer
 *
 * Runs spms1_main.c, the Spinel output the sketch runs, faster than real time and writes what it
 * puts out to a WAV file. This file stands in for spms1.ino: the MIDI tables and handlers are
 * the sketch's, and the MIDI comes from a patch and a score instead of a cable. The whole synth
 * runs -- the signals bus, the run order, the NRPN table and the CC assignments -- so a patch is
 * heard as the device would play it.
 *
 *   spms1_render [--patch FILE] [--score FILE] [--seconds N] [--out FILE]
 *
 * --patch: MIDI bytes in hex, as the editor copies them with Format "MIDI bytes (hex)"; ';' starts
 *          a comment. Taken before the first sample, after the synth has written its default patch.
 * --score: one MIDI message (or several) a line, after the time in seconds: "1.5 80 3C 40".
 *          Without it, note 60 is played from 0 s to 1 s.
 * --seconds: the length of the render (default 4).
 * --out:   the WAV file (default spms1_render.wav): 48 kHz, 24 bit, stereo, as the I2S DAC gets it.
 *
 * It also checks what the synth relies on to keep time on the device, and exits with 1 if either
 * fails: that nothing is allocated while it plays, which a collection would interrupt, and that
 * no GC root was dropped for want of room in sp_gc_roots (sized for the MCU in sp_gc.h).
 */
#include <ctype.h>
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int Spms1_main(int argc, char **argv);


#if !defined(__APPLE__)
/* sp_str.c's String#crypt calls libc's crypt, which Windows lacks and glibc keeps in libcrypt;
   nothing here reaches it. */
char *crypt(const char *key, const char *salt) {
  (void)key; (void)salt;
  return NULL;
}
#endif

/* ---- MIDI state, the sketch's own ---- */

#include "spms1_midi_state.h"

/* The GC's counters and root stack, watched while the synth plays (see watch_gc) */
#include "sp_gc.h"
extern size_t sp_str_heap_bytes;

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
  for (size_t i = 0; i < g_patch_size; i++) spms1_midi_parse_byte(g_patch[i]);
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

/* The runtime's own counters: the object heap's bytes, the string heap's young bytes, and the
   collections run. Allocating moves the first or the second, and a collection the third, so
   none of them moving while the synth plays means it allocates nothing. Not every allocation
   moves them (the runtime reuses some memory between collections), so the frames counted are a
   lower bound; one that allocates every frame is still caught within a few buffers. */
typedef struct { size_t bytes, str_bytes; int cycle; } GcCounters;
static GcCounters g_gc;
static bool g_gc_started;
static long g_gc_alloc_frames;
static long g_gc_first_alloc_frame = -1;
static int g_gc_nroots_peak;

static GcCounters gc_counters(void) {
  GcCounters c = {sp_gc_bytes, sp_str_heap_bytes, sp_gc_cycle};
  return c;
}

/* Called for each frame. The roots are sampled here, as the sketch's debug print samples them:
   the module process methods push and pop theirs within the frame, so this is a lower bound of
   the peak, where sp_gc_root_overflow is exact. */
static void watch_gc(long frame) {
  GcCounters c = gc_counters();
  if (g_gc_started && (c.bytes != g_gc.bytes || c.str_bytes != g_gc.str_bytes || c.cycle != g_gc.cycle)) {
    if (g_gc_first_alloc_frame < 0) g_gc_first_alloc_frame = frame;
    g_gc_alloc_frames++;
  }
  g_gc = c;
  g_gc_started = true;
  if (sp_gc_nroots > g_gc_nroots_peak) g_gc_nroots_peak = sp_gc_nroots;
}

/* Prints what watch_gc saw, and says whether it passed */
static bool report_gc(void) {
  bool ok = true;
  if (g_gc_alloc_frames == 0) {
    printf("GC: nothing allocated while playing");
  } else {
    printf("GC: FAILED: allocation seen in %ld of %ld frames, from frame %ld on (look for a value "
           "Spinel boxes, e.g. an untyped instance variable, and seed its type in \"sig\")",
           g_gc_alloc_frames, g_frames, g_gc_first_alloc_frame);
    ok = false;
  }
  printf("; roots %d of %d at most (sampled)\n", g_gc_nroots_peak, SP_GC_STACK_MAX);
  if (sp_gc_root_overflow) {
    printf("GC: FAILED: a root did not fit in sp_gc_roots and was dropped: raise SP_GC_STACK_MAX in sp_gc.h\n");
    ok = false;
  }
  return ok;
}

/* The score's messages arrive as the frame they are timed at goes out, so the synth takes them at
   its next buffer, as it takes MIDI on the device. */
void write_to_audio_buffer(float l, float r) {
  watch_gc(g_frames);
  while (g_next_event < g_num_events && g_events[g_next_event].frame <= g_frames) {
    const Event *e = &g_events[g_next_event++];
    for (int i = 0; i < e->size; i++) spms1_midi_parse_byte(e->bytes[i]);
  }

  write_sample(l, 0);
  write_sample(r, 1);
  if (++g_frames < g_total_frames) return;

  fseek(g_wav, 0, SEEK_SET);
  write_wav_header((uint32_t)(g_frames * 2 * 3));
  fclose(g_wav);
  printf("%s: %.3f s, peak L %.1f dBFS, R %.1f dBFS, hash %08x\n", g_out_path,
         (double)g_frames / g_sample_rate, to_dbfs(g_peak[0]), to_dbfs(g_peak[1]), (unsigned)g_hash);
  exit(report_gc() ? 0 : 1);
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
