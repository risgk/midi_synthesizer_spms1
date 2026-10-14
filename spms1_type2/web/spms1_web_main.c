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

/* The MinGW linker of the PC simulator keeps runtime code that refers to these, which upstream
   define in sp_cold.c, left out with SPINEL_BARE_METAL; so may this one. */
#include <stdbool.h>
bool sp_convert_soft;
bool sp_convert_failed;

/* ---- MIDI state, the sketch's own ---- */

#include "spms1_midi_state.h"

/* The editor sends several messages in one send() (an NRPN is three CCs), so the bytes are parsed
   as a stream. */
EMSCRIPTEN_KEEPALIVE void spms1_web_midi_byte(int byte) {
  spms1_midi_parse_byte((uint8_t)byte);
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
