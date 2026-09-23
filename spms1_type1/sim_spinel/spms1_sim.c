/*
 * MIDI Synthesizer SPMS-1 (type-1) PC simulator
 *
 * Runs spms1_main.c, the Spinel output the sketch runs, on Windows or macOS. This file stands in
 * for spms1_type1.ino: the MIDI tables and handlers are the sketch's, audio goes out through
 * PortAudio, loaded at run time, and MIDI comes in through WinMM or CoreMIDI.
 *
 *   spms1_sim [--list] [--midi-in N|NAME] [--frames N] [--host wasapi|mme|ds|default]
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
#include <windows.h>
#include <mmsystem.h>
#else
#include <dlfcn.h>
#include <time.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreMIDI/CoreMIDI.h>
#endif

extern int Spms1_main(int argc, char **argv);

/* ---- MIDI state, as in spms1_type1.ino ---- */

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

/* ---- MIDI input ---- */

#if defined(_WIN32)

static HMIDIIN g_midi_in;

static int midi_in_count(void) { return (int)midiInGetNumDevs(); }

static void midi_in_name(int i, char *buf, size_t size) {
  MIDIINCAPSA caps;
  if (midiInGetDevCapsA((UINT)i, &caps, sizeof(caps)) == MMSYSERR_NOERROR) {
    snprintf(buf, size, "%s", caps.szPname);
  } else {
    snprintf(buf, size, "?");
  }
}

/* WinMM delivers each short message whole, with running status already resolved. */
static void CALLBACK midi_in_proc(HMIDIIN h, UINT msg, DWORD_PTR inst, DWORD_PTR p1, DWORD_PTR p2) {
  (void)h; (void)inst; (void)p2;
  if (msg == MIM_DATA) {
    handle_midi_message((uint8_t)(p1 & 0xFF), (uint8_t)((p1 >> 8) & 0x7F), (uint8_t)((p1 >> 16) & 0x7F));
  }
}

static int midi_in_open(int i) {
  if (midiInOpen(&g_midi_in, (UINT)i, (DWORD_PTR)midi_in_proc, 0, CALLBACK_FUNCTION) != MMSYSERR_NOERROR) {
    return 0;
  }
  midiInStart(g_midi_in);
  return 1;
}

#else

static MIDIClientRef g_midi_client;
static MIDIPortRef g_midi_port;
static uint8_t g_parse_status;
static uint8_t g_parse_data[2];
static int g_parse_count;
static int g_parse_in_sysex;

static int midi_in_count(void) { return (int)MIDIGetNumberOfSources(); }

static void midi_in_name(int i, char *buf, size_t size) {
  CFStringRef name = NULL;
  snprintf(buf, size, "?");
  if (MIDIObjectGetStringProperty(MIDIGetSource((ItemCount)i), kMIDIPropertyDisplayName, &name) == noErr && name) {
    CFStringGetCString(name, buf, (CFIndex)size, kCFStringEncodingUTF8);
    CFRelease(name);
  }
}

/* CoreMIDI hands over a byte stream, so running status is resolved here. Real-time bytes may
   arrive anywhere and are skipped, and so is SysEx. */
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

static void midi_read_proc(const MIDIPacketList *list, void *ref, void *src) {
  (void)ref; (void)src;
  const MIDIPacket *p = &list->packet[0];
  for (UInt32 i = 0; i < list->numPackets; i++) {
    for (UInt16 j = 0; j < p->length; j++) midi_parse_byte(p->data[j]);
    p = MIDIPacketNext(p);
  }
}

static int midi_in_open(int i) {
  if (MIDIClientCreate(CFSTR("SPMS-1 (type-1) simulator"), NULL, NULL, &g_midi_client) != noErr) return 0;
  if (MIDIInputPortCreate(g_midi_client, CFSTR("MIDI In"), midi_read_proc, NULL, &g_midi_port) != noErr) return 0;
  return MIDIPortConnectSource(g_midi_port, MIDIGetSource((ItemCount)i), NULL) == noErr;
}

#endif

/* ---- PortAudio, declared here and loaded at run time so that no headers or import library are
   needed to build ---- */

typedef int PaError;
typedef void PaStream;

typedef struct {
  int structVersion;
  int type;
  const char *name;
  int deviceCount;
  int defaultInputDevice;
  int defaultOutputDevice;
} PaHostApiInfo;

typedef struct {
  int structVersion;
  const char *name;
  int hostApi;
  int maxInputChannels;
  int maxOutputChannels;
  double defaultLowInputLatency;
  double defaultLowOutputLatency;
  double defaultHighInputLatency;
  double defaultHighOutputLatency;
  double defaultSampleRate;
} PaDeviceInfo;

typedef struct {
  int device;
  int channelCount;
  unsigned long sampleFormat;
  double suggestedLatency;
  void *hostApiSpecificStreamInfo;
} PaStreamParameters;

#define PA_FLOAT32            (0x00000001UL)
#define PA_CLIP_OFF           (0x00000001UL)
#define PA_OUTPUT_UNDERFLOWED (-9980)
#define PA_DIRECTSOUND        (1)
#define PA_MME                (2)
#define PA_WASAPI             (13)

static PaError (*Pa_Initialize)(void);
static PaError (*Pa_Terminate)(void);
static const char *(*Pa_GetErrorText)(PaError);
static const char *(*Pa_GetVersionText)(void);
static int (*Pa_GetDefaultOutputDevice)(void);
static int (*Pa_HostApiTypeIdToHostApiIndex)(int);
static const PaHostApiInfo *(*Pa_GetHostApiInfo)(int);
static const PaDeviceInfo *(*Pa_GetDeviceInfo)(int);
static PaError (*Pa_OpenStream)(PaStream **, const PaStreamParameters *, const PaStreamParameters *,
                                double, unsigned long, unsigned long, void *, void *);
static PaError (*Pa_StartStream)(PaStream *);
static PaError (*Pa_WriteStream)(PaStream *, const void *, unsigned long);

static void *load_symbol(void *lib, const char *name) {
#if defined(_WIN32)
  void *p = (void *)GetProcAddress((HMODULE)lib, name);
#else
  void *p = dlsym(lib, name);
#endif
  if (!p) {
    fprintf(stderr, "PortAudio has no %s\n", name);
    exit(1);
  }
  return p;
}

static void load_portaudio(void) {
  static const char *candidates[] = {
#if defined(_WIN32)
    "portaudio.dll", "libportaudio.dll", "libportaudio-2.dll", "portaudio_x64.dll",
    "C:\\Program Files\\Audacity\\portaudio_x64.dll",
#else
    "libportaudio.dylib", "libportaudio.2.dylib", "/opt/homebrew/lib/libportaudio.dylib",
    "/usr/local/lib/libportaudio.dylib",
#endif
  };
  void *lib = NULL;
  const char *env = getenv("SPMS1_PORTAUDIO_DLL");
  for (int i = -1; i < (int)(sizeof(candidates) / sizeof(candidates[0])) && !lib; i++) {
    const char *path = (i < 0) ? env : candidates[i];
    if (!path) continue;
#if defined(_WIN32)
    lib = (void *)LoadLibraryA(path);
#else
    lib = dlopen(path, RTLD_NOW);
#endif
  }
  if (!lib) {
    fprintf(stderr, "PortAudio not found; set SPMS1_PORTAUDIO_DLL to its path\n");
    exit(1);
  }

  *(void **)&Pa_Initialize = load_symbol(lib, "Pa_Initialize");
  *(void **)&Pa_Terminate = load_symbol(lib, "Pa_Terminate");
  *(void **)&Pa_GetErrorText = load_symbol(lib, "Pa_GetErrorText");
  *(void **)&Pa_GetVersionText = load_symbol(lib, "Pa_GetVersionText");
  *(void **)&Pa_GetDefaultOutputDevice = load_symbol(lib, "Pa_GetDefaultOutputDevice");
  *(void **)&Pa_HostApiTypeIdToHostApiIndex = load_symbol(lib, "Pa_HostApiTypeIdToHostApiIndex");
  *(void **)&Pa_GetHostApiInfo = load_symbol(lib, "Pa_GetHostApiInfo");
  *(void **)&Pa_GetDeviceInfo = load_symbol(lib, "Pa_GetDeviceInfo");
  *(void **)&Pa_OpenStream = load_symbol(lib, "Pa_OpenStream");
  *(void **)&Pa_StartStream = load_symbol(lib, "Pa_StartStream");
  *(void **)&Pa_WriteStream = load_symbol(lib, "Pa_WriteStream");
}

/* ---- Audio, the sketch's side of the ffi_func interface ---- */

static uint32_t g_sample_rate = 48000;
static uint32_t g_audio_buffers = 2;
static uint32_t g_audio_buffer_words = 64;

static unsigned long g_frames = 256;
static int g_host_api_type = -1;
static PaStream *g_stream;
static float *g_out;
static unsigned long g_out_frames;
static unsigned long g_underflows;

void set_sample_rate(int32_t v) { g_sample_rate = (uint32_t)v; }
int32_t get_sample_rate(void) { return (int32_t)g_sample_rate; }
void set_audio_buffers(int32_t v) { g_audio_buffers = (uint32_t)v; }
int32_t get_audio_buffers(void) { return (int32_t)g_audio_buffers; }
void set_audio_buffer_words(int32_t v) { g_audio_buffer_words = (uint32_t)v; }
int32_t get_audio_buffer_words(void) { return (int32_t)g_audio_buffer_words; }

static PaError open_stream(int device) {
  const PaDeviceInfo *info = Pa_GetDeviceInfo(device);
  PaStreamParameters params;
  params.device = device;
  params.channelCount = 2;
  params.sampleFormat = PA_FLOAT32;
  params.suggestedLatency = info->defaultLowOutputLatency;
  params.hostApiSpecificStreamInfo = NULL;
  PaError err = Pa_OpenStream(&g_stream, NULL, &params, (double)g_sample_rate, g_frames, PA_CLIP_OFF, NULL, NULL);
  fprintf(stderr, "%s %s, %s: %s\n", (err < 0) ? "Could not open" : "Audio out:",
          Pa_GetHostApiInfo(info->hostApi)->name, info->name,
          (err < 0) ? Pa_GetErrorText(err) : "open");
  return err;
}

void start_audio(void) {
  load_portaudio();
  PaError err = Pa_Initialize();
  if (err < 0) {
    fprintf(stderr, "Pa_Initialize: %s\n", Pa_GetErrorText(err));
    exit(1);
  }
  fprintf(stderr, "%s\n", Pa_GetVersionText());

  /* WASAPI in shared mode opens only at the device's own rate; the default API resamples. */
  err = -1;
  if (g_host_api_type >= 0) {
    int api = Pa_HostApiTypeIdToHostApiIndex(g_host_api_type);
    if (api >= 0 && Pa_GetHostApiInfo(api)->defaultOutputDevice >= 0) {
      err = open_stream(Pa_GetHostApiInfo(api)->defaultOutputDevice);
    }
  }
  if (err < 0) err = open_stream(Pa_GetDefaultOutputDevice());
  if (err < 0) exit(1);

  g_out = (float *)calloc(g_frames * 2, sizeof(float));
  Pa_StartStream(g_stream);
  fprintf(stderr, "%u Hz, %lu frames per write\n", (unsigned)g_sample_rate, g_frames);
}

void stop_audio(void) {}

/* Blocks in Pa_WriteStream while the output is full, which is what paces the synth loop, the way
   the I2S driver paces it on the device. */
void write_to_audio_buffer(float l, float r) {
  g_out[g_out_frames * 2] = l;
  g_out[g_out_frames * 2 + 1] = r;
  if (++g_out_frames < g_frames) return;
  g_out_frames = 0;
  PaError err = Pa_WriteStream(g_stream, g_out, g_frames);
  if (err == PA_OUTPUT_UNDERFLOWED) {
    g_underflows++;
  } else if (err < 0) {
    fprintf(stderr, "\nPa_WriteStream: %s\n", Pa_GetErrorText(err));
    exit(1);
  }
}

/* ---- Load measurement: main brackets one buffer's DSP with these ---- */

static double now_seconds(void) {
#if defined(_WIN32)
  static LARGE_INTEGER freq;
  LARGE_INTEGER t;
  if (!freq.QuadPart) QueryPerformanceFrequency(&freq);
  QueryPerformanceCounter(&t);
  return (double)t.QuadPart / (double)freq.QuadPart;
#else
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
#endif
}

static double g_measure_start;
static double g_measure_total;
static double g_measure_max;
static unsigned long g_measure_buffers;
static double g_report_at;

void start_debug_measure(void) { g_measure_start = now_seconds(); }

void stop_debug_measure(void) {
  double t = now_seconds();
  double dt = t - g_measure_start;
  g_measure_total += dt;
  if (dt > g_measure_max) g_measure_max = dt;
  g_measure_buffers++;
  if (g_report_at == 0.0) g_report_at = t + 1.0;
  if (t < g_report_at) return;

  double budget = (double)g_audio_buffer_words / (double)g_sample_rate;
  double avg = g_measure_total / (double)g_measure_buffers;
  fprintf(stderr, "\rDSP %5.1f us avg (%4.1f%%), %6.1f us max / %4.0f us, underflows %lu   ",
          avg * 1e6, avg / budget * 100.0, g_measure_max * 1e6, budget * 1e6, g_underflows);
  g_measure_total = 0.0;
  g_measure_max = 0.0;
  g_measure_buffers = 0;
  g_report_at += 1.0;
}

#if defined(_WIN32)
/* sp_str.c's String#crypt calls libc's crypt, which Windows lacks; nothing here reaches it. */
char *crypt(const char *key, const char *salt) {
  (void)key; (void)salt;
  return NULL;
}
#endif

/* ---- Entry ---- */

static void list_midi_inputs(void) {
  char name[256];
  int n = midi_in_count();
  for (int i = 0; i < n; i++) {
    midi_in_name(i, name, sizeof(name));
    fprintf(stderr, "%d: %s\n", i, name);
  }
  if (n == 0) fprintf(stderr, "No MIDI input found.\n");
}

static int find_midi_input(const char *spec) {
  char name[256];
  char *end;
  long index = strtol(spec, &end, 10);
  if (*spec && !*end) return (index >= 0 && index < midi_in_count()) ? (int)index : -1;
  for (int i = 0; i < midi_in_count(); i++) {
    midi_in_name(i, name, sizeof(name));
    if (strstr(name, spec)) return i;
  }
  return -1;
}

int main(int argc, char **argv) {
  const char *midi_spec = NULL;
  char line[256];
#if defined(_WIN32)
  g_host_api_type = PA_WASAPI;
#endif

  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "--list")) {
      list_midi_inputs();
      return 0;
    } else if (!strcmp(argv[i], "--midi-in") && i + 1 < argc) {
      midi_spec = argv[++i];
    } else if (!strcmp(argv[i], "--frames") && i + 1 < argc) {
      g_frames = strtoul(argv[++i], NULL, 10);
    } else if (!strcmp(argv[i], "--host") && i + 1 < argc) {
      const char *h = argv[++i];
      g_host_api_type = !strcmp(h, "wasapi") ? PA_WASAPI : !strcmp(h, "mme") ? PA_MME :
                        !strcmp(h, "ds") ? PA_DIRECTSOUND : -1;
    } else {
      fprintf(stderr, "usage: %s [--list] [--midi-in N|NAME] [--frames N] [--host wasapi|mme|ds|default]\n", argv[0]);
      return 1;
    }
  }

  if (!midi_spec && midi_in_count() > 0) {
    list_midi_inputs();
    fprintf(stderr, "MIDI input (Enter for none): ");
    if (fgets(line, sizeof(line), stdin)) {
      line[strcspn(line, "\r\n")] = '\0';
      if (*line) midi_spec = line;
    }
  }
  if (midi_spec) {
    int i = find_midi_input(midi_spec);
    char name[256];
    if (i < 0 || !midi_in_open(i)) {
      fprintf(stderr, "Could not open MIDI input %s\n", midi_spec);
      return 1;
    }
    midi_in_name(i, name, sizeof(name));
    fprintf(stderr, "MIDI in: %s\n", name);
  } else {
    fprintf(stderr, "Running without MIDI input.\n");
  }

  char *spinel_argv[] = {argv[0], NULL};
  return Spms1_main(1, spinel_argv);
}
