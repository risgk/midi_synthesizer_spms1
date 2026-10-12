/*
 * MIDI Synthesizer SPMS-1 (type-2) Web: the C API for the AudioWorkletProcessor
 * (spms1_web_synth_processor.js)
 *
 * Runs spms1_main.c, the Spinel output the sketch runs, as WebAssembly. This file stands in for
 * spms1_type2.ino: the MIDI tables and handlers are the sketch's, and write_to_audio_buffer hands
 * the samples to the AudioWorkletProcessor.
 *
 * Spms1_main never returns: its `loop do` writes each sample out and, on the device, blocks while
 * the output is full. Here the build runs Binaryen's Asyncify on the WebAssembly, so that
 * spms1_web_yield, imported from the AudioWorkletProcessor, can unwind Spms1_main out to it once
 * a block is filled, and rewind it back to the same place for the next block.
 */
#include <stdint.h>

#include <emscripten/emscripten.h>

extern int Spms1_main(int argc, char **argv);

/* The MinGW linker of the PC simulator keeps runtime code that refers to these; so may this
   one. urandom fails closed on the 0. */
#include <stdbool.h>
bool sp_convert_soft;
bool sp_convert_failed;
int sp_crypto_entropy(unsigned char *out, int nbytes) { (void)out; (void)nbytes; return 0; }

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

/* The editor sends several messages in one send() (an NRPN is three CCs), so the bytes are parsed
   as a stream, running status included. Real-time bytes may arrive anywhere and are skipped, and
   so is SysEx. */
static uint8_t g_parse_status;
static uint8_t g_parse_data[2];
static int g_parse_count;
static int g_parse_in_sysex;

EMSCRIPTEN_KEEPALIVE void spms1_web_midi_byte(int byte) {
  uint8_t b = (uint8_t)byte;
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

/* ---- Audio, the sketch's side of the ffi_func interface ---- */

#define SPMS1_WEB_MAX_BLOCK_SIZE (1024)

static uint32_t g_sample_rate = 48000;
static uint32_t g_audio_buffers = 2;
static uint32_t g_audio_buffer_words = 64;

static float g_left[SPMS1_WEB_MAX_BLOCK_SIZE];
static float g_right[SPMS1_WEB_MAX_BLOCK_SIZE];
static int g_block_size = 128;
static int g_block_frames;

void set_sample_rate(int32_t v) { g_sample_rate = (uint32_t)v; }
int32_t get_sample_rate(void) { return (int32_t)g_sample_rate; }
void set_audio_buffers(int32_t v) { g_audio_buffers = (uint32_t)v; }
int32_t get_audio_buffers(void) { return (int32_t)g_audio_buffers; }
void set_audio_buffer_words(int32_t v) { g_audio_buffer_words = (uint32_t)v; }
int32_t get_audio_buffer_words(void) { return (int32_t)g_audio_buffer_words; }

void start_audio(void) {}
void stop_audio(void) {}
void start_debug_measure(void) {}
void stop_debug_measure(void) {}

/* Imported from the AudioWorkletProcessor, which unwinds Spms1_main here (Asyncify) and rewinds
   it back for the next block. */
__attribute__((import_module("env"), import_name("spms1_web_yield"))) void spms1_web_yield(void);

/* Returns once the block is full, as the I2S driver returns once the output has room. */
void write_to_audio_buffer(float l, float r) {
  g_left[g_block_frames] = l;
  g_right[g_block_frames] = r;
  if (++g_block_frames >= g_block_size) {
    spms1_web_yield();
  }
}

/* ---- The C API ---- */

/* The data of Asyncify: the start and the end of the buffer that keeps the unwound call stack
   (Spms1_main and write_to_audio_buffer), followed by the buffer itself. */
#define SPMS1_WEB_ASYNCIFY_STACK_SIZE (64 * 1024)

static struct {
  uint32_t start;
  uint32_t end;
  uint8_t stack[SPMS1_WEB_ASYNCIFY_STACK_SIZE];
} g_asyncify_data;

EMSCRIPTEN_KEEPALIVE int spms1_web_max_block_size(void) { return SPMS1_WEB_MAX_BLOCK_SIZE; }
EMSCRIPTEN_KEEPALIVE float *spms1_web_left(void) { return g_left; }
EMSCRIPTEN_KEEPALIVE float *spms1_web_right(void) { return g_right; }
EMSCRIPTEN_KEEPALIVE int spms1_web_sample_rate(void) { return (int)g_sample_rate; }

/* Resets the buffer of Asyncify, before it unwinds Spms1_main. */
EMSCRIPTEN_KEEPALIVE void *spms1_web_asyncify_data(void) {
  g_asyncify_data.start = (uint32_t)(uintptr_t)g_asyncify_data.stack;
  g_asyncify_data.end = (uint32_t)(uintptr_t)(g_asyncify_data.stack + SPMS1_WEB_ASYNCIFY_STACK_SIZE);
  return &g_asyncify_data;
}

/* Sets how many frames (1 to spms1_web_max_block_size()) the next spms1_web_run() renders to
   spms1_web_left() and spms1_web_right(). */
EMSCRIPTEN_KEEPALIVE void spms1_web_begin_block(int numFrames) {
  if (numFrames < 1) numFrames = 1;
  if (numFrames > SPMS1_WEB_MAX_BLOCK_SIZE) numFrames = SPMS1_WEB_MAX_BLOCK_SIZE;
  g_block_size = numFrames;
  g_block_frames = 0;
}

/* Starts Spms1_main the first time, and is called again to rewind it after that. */
EMSCRIPTEN_KEEPALIVE void spms1_web_run(void) {
  Spms1_main(0, NULL);
}
