/*
 * MIDI Synthesizer SPMS-1 (type-2)
 */

#pragma GCC optimize ("O3")
#if defined(ARDUINO_ARCH_RP2040)
#pragma GCC target ("thumb")
#pragma GCC section text=".time_critical"
#endif  // defined(ARDUINO_ARCH_RP2040)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-function"

#define SPMS1_USE_DEBUG_PRINT
#define SPMS1_USE_USB_MIDI                  // Select USB Stack: "Adafruit TinyUSB" in the Arduino IDE "Tools" menu
#define SPMS1_USE_UART_MIDI

#define SPMS1_UART_MIDI_SPEED               (31250)

#define SPMS1_DEBUG_PRINT_USE_USB_SERIAL    // USB CDC, next to USB MIDI; comment out for UART0 on GP0 and GP1

#if defined(SPMS1_DEBUG_PRINT_USE_USB_SERIAL)
#define SPMS1_DEBUG_PRINT_SERIAL            g_debug_print_buffer  // Transferred to USB CDC by loop()
#else  // defined(SPMS1_DEBUG_PRINT_USE_USB_SERIAL)
#define SPMS1_DEBUG_PRINT_SERIAL            Serial1
#define SPMS1_DEBUG_PRINT_TX_PIN            (0)
#define SPMS1_DEBUG_PRINT_RX_PIN            (1)
#endif  // defined(SPMS1_DEBUG_PRINT_USE_USB_SERIAL)

#define SPMS1_UART_MIDI_SERIAL              Serial2
#define SPMS1_UART_MIDI_TX_PIN              (4)
#define SPMS1_UART_MIDI_RX_PIN              (5)

// for Pimoroni Pico Audio Pack (PIM544)
#define SPMS1_I2S_DAC_MUTE_OFF_PIN          (22)  // Comment out if GP22 is used for something else
#define SPMS1_I2S_DATA_PIN                  (9)
#define SPMS1_I2S_BCLK_PIN                  (10)  // LRCLK is SPMS1_I2S_BCLK_PIN + 1
#define SPMS1_I2S_SWAP_LEFT_AND_RIGHT       (false)

//#define SPMS1_USE_PWM_AUDIO_INSTEAD_OF_I2S

// for Pimoroni Pico VGA Demo Base (PIM553)
#define SPMS1_PWM_AUDIO_L_PIN               (28)
#define SPMS1_PWM_AUDIO_R_PIN               (27)

////////////////////////////////////////////////////////////////

#include <algorithm>
#include <cmath>

#include <MIDI.h>
struct MySettings : public midi::DefaultSettings {
  static const long BaudRate = SPMS1_UART_MIDI_SPEED;
  static const bool HandleNullVelocityNoteOnAsNoteOff = false;
};

#if defined(SPMS1_USE_USB_MIDI)
#include <Adafruit_TinyUSB.h>
#include <pico/mutex.h>
Adafruit_USBD_MIDI usbd_midi;
// __usb_mutex is internal to the Adafruit TinyUSB Library (Adafruit_TinyUSB_rp2040.cpp), not its
// API. The library's IRQ on core 0 runs tud_task() only when it can take this mutex, but
// Adafruit_USBD_MIDI and Adafruit_USBD_CDC call TinyUSB without it. An IRQ that lands while one
// of them holds a TinyUSB internal mutex waits for it forever, so loop() holds __usb_mutex
// around them to make the IRQ skip. A rename in the library shows up as a link error.
extern mutex_t __usb_mutex;
MIDI_CREATE_CUSTOM_INSTANCE(Adafruit_USBD_MIDI, usbd_midi, USB_MIDI, MySettings);
#endif  // defined(SPMS1_USE_USB_MIDI)

#if defined(SPMS1_USE_UART_MIDI)
MIDI_CREATE_CUSTOM_INSTANCE(HardwareSerial, SPMS1_UART_MIDI_SERIAL, UART_MIDI, MySettings);
#endif

#if defined(SPMS1_USE_PWM_AUDIO_INSTEAD_OF_I2S)
#include "spms1_pico2_pwm_audio.h"
SPMS1_PWMAudioOutput g_pwm_output(SPMS1_PWM_AUDIO_L_PIN, SPMS1_PWM_AUDIO_R_PIN);
#else  // defined(SPMS1_USE_PWM_AUDIO_INSTEAD_OF_I2S)
#include "spms1_pico2_i2s.h"
SPMS1_I2SOutput g_i2s_output;
#endif  // defined(SPMS1_USE_PWM_AUDIO_INSTEAD_OF_I2S)

#if defined(SPMS1_USE_DEBUG_PRINT) && defined(SPMS1_DEBUG_PRINT_USE_USB_SERIAL)
// Collects one report so that it goes to USB CDC whole or not at all. A plain Serial.print would
// wait for room in the CDC FIFO, and with __usb_mutex held nothing would ever make that room.
class SPMS1_DebugPrintBuffer : public Print {
  uint8_t m_buffer[256];  // A report must fit, and so must CFG_TUD_CDC_TX_BUFSIZE (256)
  size_t  m_length = 0;

public:
  virtual size_t write(uint8_t c) {
    if (m_length == sizeof(m_buffer)) {
      return 0;
    }
    m_buffer[m_length++] = c;
    return 1;
  }

  using Print::write;

  // Drops the report if the host is not reading
  template <typename T>
  void transfer_to(T& output) {
    if (output.availableForWrite() >= static_cast<int>(m_length)) {
      output.write(m_buffer, m_length);
      output.flush();
    }
    m_length = 0;
  }
};
SPMS1_DebugPrintBuffer g_debug_print_buffer;
#endif  // defined(SPMS1_USE_DEBUG_PRINT) && defined(SPMS1_DEBUG_PRINT_USE_USB_SERIAL)

uint32_t g_debug_measurement_start_us = 0;
uint32_t g_debug_measurement_min_us   = UINT32_MAX;
uint32_t g_debug_measurement_max_us   = 0;
uint32_t g_debug_measurement_counted  = 0;  // 0 until the first buffer has been measured

void handleNoteOn(byte channel, byte pitch, byte velocity);
void handleNoteOff(byte channel, byte pitch, byte velocity);
void handleControlChange(byte channel, byte number, byte value);
void handlePitchBend(byte channel, int bend);

// Arduino's prototype generator puts its prototypes before the first function defined, so one must
// come before extern "C", or setup() and loop() get C linkage and Arduino.h rejects them.
[[maybe_unused]] static void keep_prototypes_out_of_extern_c() {}

extern "C" {

extern int Spms1_main(int argc, char **argv);

// How many GC roots the synth actually has pushed. sp_gc_roots is sized by SP_GC_STACK_MAX in
// sp_gc.h and costs 4 bytes a slot whether used or not, so this says how much of it is real.
// A plain global, not thread-local, because SP_THREADS is not defined: core 0 sees what core 1
// writes. Diagnostic only.
extern int sp_gc_nroots;

uint8_t  g_midi_note_on_pitch[16]  = {60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60};
uint8_t  g_midi_note_on_state[16]  = {};
uint8_t  g_midi_cc_values[16][128] = {};
// Pitch bend arrives 14-bit and centred, and the MIDI library hands it over already signed,
// so it is kept that way rather than folded into the 7-bit tables above.
int16_t  g_midi_pitch_bend[16]     = {};

// NRPN parameter numbers are (MSB << 7) | LSB; the synth uses MSB 0-3 as categories, so 512
// entries cover it. Values are 7-bit, filled from CC 6.
#define SPMS1_NRPN_SIZE (512)
uint8_t  g_midi_nrpn_values[16][SPMS1_NRPN_SIZE] = {};
uint8_t  g_midi_nrpn_msb[16]            = {};
uint8_t  g_midi_nrpn_lsb[16]            = {};
uint8_t  g_midi_nrpn_selected[16]       = {};  // 0 until CC 99 or 98 arrives, and again after an RPN

uint32_t g_sample_rate             = 48000;
uint32_t g_audio_buffers           = 2;
uint32_t g_audio_buffer_words      = 64;

void set_midi_note_on_pitch(uint8_t midi_ch, uint8_t midi_note_on_pitch) {
  if (midi_ch >= 16) {
    return;
  }

  g_midi_note_on_pitch[midi_ch] = midi_note_on_pitch;
}

uint8_t get_midi_note_on_pitch(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return 0;
  }

  return g_midi_note_on_pitch[midi_ch];
}

void set_midi_note_on_state(uint8_t midi_ch, uint8_t midi_note_on_state) {
  if (midi_ch >= 16) {
    return;
  }

  g_midi_note_on_state[midi_ch] = midi_note_on_state;
}

void set_midi_pitch_bend(uint8_t midi_ch, int32_t midi_pitch_bend) {
  if (midi_ch >= 16) {
    return;
  }

  g_midi_pitch_bend[midi_ch] = static_cast<int16_t>(midi_pitch_bend);
}

int32_t get_midi_pitch_bend(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return 0;
  }

  return g_midi_pitch_bend[midi_ch];
}

uint8_t get_midi_note_on_state(uint8_t midi_ch) {
  if (midi_ch >= 16) {
    return 0;
  }

  return g_midi_note_on_state[midi_ch];
}

void set_midi_cc_value(uint8_t midi_ch, uint8_t cc_number, uint8_t cc_value) {
  if (midi_ch >= 16) {
    return;
  }

  if (cc_number >= 128) {
    return;
  }

  g_midi_cc_values[midi_ch][cc_number] = cc_value;
}

uint8_t get_midi_cc_value(uint8_t midi_ch, uint8_t cc_number) {
  if (midi_ch >= 16) {
    return 0;
  }

  if (cc_number >= 128) {
    return 0;
  }

  return g_midi_cc_values[midi_ch][cc_number];
}

void set_midi_nrpn_value(uint8_t midi_ch, int32_t index, uint8_t value) {
  if (midi_ch >= 16) {
    return;
  }

  if (index < 0 || index >= SPMS1_NRPN_SIZE) {
    return;
  }

  g_midi_nrpn_values[midi_ch][index] = value;
}

uint8_t get_midi_nrpn_value(uint8_t midi_ch, int32_t index) {
  if (midi_ch >= 16) {
    return 0;
  }

  if (index < 0 || index >= SPMS1_NRPN_SIZE) {
    return 0;
  }

  return g_midi_nrpn_values[midi_ch][index];
}

// CC 99 and 98 select a parameter, in either order, and CC 6 commits a value to it. CC 38 is
// ignored because every value here is 7-bit, and CC 96/97 are not implemented. CC 101 and 100
// select an RPN instead, which must not leave a following CC 6 looking like NRPN data. The CCs
// are still stored by set_midi_cc_value as well, so a patch may read them as ordinary controls.
void handle_midi_nrpn_cc(uint8_t midi_ch, uint8_t number, uint8_t value) {
  if (midi_ch >= 16) {
    return;
  }

  if (number == 99) {
    g_midi_nrpn_msb[midi_ch] = value;
    g_midi_nrpn_selected[midi_ch] = 1;
  } else if (number == 98) {
    g_midi_nrpn_lsb[midi_ch] = value;
    g_midi_nrpn_selected[midi_ch] = 1;
  } else if (number == 101 || number == 100) {
    g_midi_nrpn_selected[midi_ch] = 0;
  } else if (number == 6 && g_midi_nrpn_selected[midi_ch]) {
    set_midi_nrpn_value(midi_ch, (((int32_t)g_midi_nrpn_msb[midi_ch]) << 7) | g_midi_nrpn_lsb[midi_ch], value);
  }
}

void set_sample_rate(uint32_t sample_rate) {
  g_sample_rate = sample_rate;
}

uint32_t get_sample_rate() {
  return g_sample_rate;
}

void set_audio_buffers(uint32_t audio_buffers) {
  g_audio_buffers = audio_buffers;
}

uint32_t get_audio_buffers() {
  return g_audio_buffers;
}

void set_audio_buffer_words(uint32_t audio_buffer_words) {
  g_audio_buffer_words = audio_buffer_words;
}

uint32_t get_audio_buffer_words() {
  return g_audio_buffer_words;
}

#if defined(SPMS1_USE_PWM_AUDIO_INSTEAD_OF_I2S)

void start_audio() {
  g_pwm_output.setSysClk(g_sample_rate);
  pinMode(SPMS1_PWM_AUDIO_L_PIN, OUTPUT_12MA);
  pinMode(SPMS1_PWM_AUDIO_R_PIN, OUTPUT_12MA);
  g_pwm_output.setBufferFrames(g_audio_buffers * g_audio_buffer_words);
  g_pwm_output.begin(g_sample_rate);
}

void stop_audio() {
}

void write_to_audio_buffer(float l, float r) {
  int32_t clamped_l = static_cast<int32_t>(std::lroundf(l * 8388607.0f));
  int32_t clamped_r = static_cast<int32_t>(std::lroundf(r * 8388607.0f));
  clamped_l = std::clamp(clamped_l, static_cast<int32_t>(-8388608), static_cast<int32_t>(8388607));
  clamped_r = std::clamp(clamped_r, static_cast<int32_t>(-8388608), static_cast<int32_t>(8388607));
  g_pwm_output.write24(clamped_l << 8, clamped_r << 8);
}

#else  // defined(SPMS1_USE_PWM_AUDIO_INSTEAD_OF_I2S)

void start_audio() {
  g_i2s_output.setSysClk(g_sample_rate);
  g_i2s_output.setFrequency(g_sample_rate);
  g_i2s_output.setDATA(SPMS1_I2S_DATA_PIN);
  g_i2s_output.setBCLK(SPMS1_I2S_BCLK_PIN);
  g_i2s_output.setBufferFrames(g_audio_buffers * g_audio_buffer_words);
  g_i2s_output.begin();

#if defined(SPMS1_I2S_DAC_MUTE_OFF_PIN)
  pinMode(SPMS1_I2S_DAC_MUTE_OFF_PIN, OUTPUT);
  digitalWrite(SPMS1_I2S_DAC_MUTE_OFF_PIN, HIGH);
#endif  // defined(SPMS1_I2S_DAC_MUTE_OFF_PIN)
}

void stop_audio() {
  g_i2s_output.end();
}

void write_to_audio_buffer(float l, float r) {
  int32_t clamped_l = static_cast<int32_t>(std::lroundf(l * 8388607.0f));
  int32_t clamped_r = static_cast<int32_t>(std::lroundf(r * 8388607.0f));
  clamped_l = std::clamp(clamped_l, static_cast<int32_t>(-8388608), static_cast<int32_t>(8388607));
  clamped_r = std::clamp(clamped_r, static_cast<int32_t>(-8388608), static_cast<int32_t>(8388607));
  g_i2s_output.write24(clamped_l << 8, clamped_r << 8);
}

#endif  // defined(SPMS1_USE_PWM_AUDIO_INSTEAD_OF_I2S)

void start_debug_measure(void) {
#if defined(SPMS1_USE_DEBUG_PRINT)
  g_debug_measurement_start_us = micros();
#endif  // defined(SPMS1_USE_DEBUG_PRINT)
}

void stop_debug_measure(void) {
#if defined(SPMS1_USE_DEBUG_PRINT)
  uint32_t debug_measurement_end_us = micros();
  uint32_t debug_measurement_elapsed_us = debug_measurement_end_us - g_debug_measurement_start_us;
  // The first buffer runs cold and would fix a maximum that never comes down again, so it is
  // multiplied out rather than skipped, keeping both updates branchless.
  g_debug_measurement_min_us -= g_debug_measurement_counted *
                                (debug_measurement_elapsed_us < g_debug_measurement_min_us) *
                                (g_debug_measurement_min_us - debug_measurement_elapsed_us);
  g_debug_measurement_max_us += g_debug_measurement_counted *
                                (debug_measurement_elapsed_us > g_debug_measurement_max_us) *
                                (debug_measurement_elapsed_us - g_debug_measurement_max_us);
  g_debug_measurement_counted = 1;
#endif  // defined(SPMS1_USE_DEBUG_PRINT)
}

}

void setup1() {
}

void loop1() {
  Spms1_main(0, NULL);
}

void setup() {
  delay(100);

#if defined(SPMS1_USE_DEBUG_PRINT) && !defined(SPMS1_DEBUG_PRINT_USE_USB_SERIAL)
  pinMode(SPMS1_DEBUG_PRINT_RX_PIN, INPUT_PULLUP);
  SPMS1_DEBUG_PRINT_SERIAL.setTX(SPMS1_DEBUG_PRINT_TX_PIN);
  SPMS1_DEBUG_PRINT_SERIAL.setRX(SPMS1_DEBUG_PRINT_RX_PIN);
  SPMS1_DEBUG_PRINT_SERIAL.begin(115200);
#endif  // defined(SPMS1_USE_DEBUG_PRINT) && !defined(SPMS1_DEBUG_PRINT_USE_USB_SERIAL)

#if defined(SPMS1_USE_USB_MIDI)
  TinyUSB_Device_Init(0);
#if defined(SPMS1_USE_DEBUG_PRINT) && defined(SPMS1_DEBUG_PRINT_USE_USB_SERIAL)
  TinyUSBDevice.addInterface(Serial);  // TinyUSB_Device_Init() clears the configuration, Serial included
#endif  // defined(SPMS1_USE_DEBUG_PRINT) && defined(SPMS1_DEBUG_PRINT_USE_USB_SERIAL)
  USBDevice.setManufacturerDescriptor("ISGK Instruments");
  USBDevice.setProductDescriptor("SPMS-1 (type-2)");
  USB_MIDI.setHandleNoteOn(handleNoteOn);
  USB_MIDI.setHandleNoteOff(handleNoteOff);
  USB_MIDI.setHandleControlChange(handleControlChange);
  USB_MIDI.setHandlePitchBend(handlePitchBend);
  USB_MIDI.begin(MIDI_CHANNEL_OMNI);
  USB_MIDI.turnThruOff();
#endif  // defined(SPMS1_USE_USB_MIDI)

#if defined(SPMS1_USE_UART_MIDI)
  pinMode(SPMS1_UART_MIDI_RX_PIN, INPUT_PULLUP);
  SPMS1_UART_MIDI_SERIAL.setTX(SPMS1_UART_MIDI_TX_PIN);
  SPMS1_UART_MIDI_SERIAL.setRX(SPMS1_UART_MIDI_RX_PIN);
  UART_MIDI.setHandleNoteOn(handleNoteOn);
  UART_MIDI.setHandleNoteOff(handleNoteOff);
  UART_MIDI.setHandleControlChange(handleControlChange);
  UART_MIDI.setHandlePitchBend(handlePitchBend);
  UART_MIDI.begin(MIDI_CHANNEL_OMNI);
  UART_MIDI.turnThruOff();
  SPMS1_UART_MIDI_SERIAL.begin(SPMS1_UART_MIDI_SPEED);
#endif  // defined(SPMS1_USE_UART_MIDI)

#if defined(ARDUINO_RASPBERRY_PI_PICO) || defined(ARDUINO_RASPBERRY_PI_PICO_2)
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  pinMode(23, OUTPUT);  // RT6150 (PMIC) Power Save Pin
  digitalWrite(23, HIGH);
#endif  // defined(ARDUINO_RASPBERRY_PI_PICO) || defined(ARDUINO_RASPBERRY_PI_PICO_2)
}

void loop() {
#if defined(SPMS1_USE_USB_MIDI)
  mutex_enter_blocking(&__usb_mutex);
  USB_MIDI.read();
  mutex_exit(&__usb_mutex);
#endif  // defined(SPMS1_USE_USB_MIDI)

#if defined(SPMS1_USE_UART_MIDI)
  UART_MIDI.read();
#endif

#if defined(SPMS1_USE_DEBUG_PRINT)
  static uint8_t s_loop_counter = 0;
  if (++s_loop_counter == 0) {
    SPMS1_DEBUG_PRINT_SERIAL.print("\e[1;1H\e[K");
    SPMS1_DEBUG_PRINT_SERIAL.print("min ");
    SPMS1_DEBUG_PRINT_SERIAL.print(g_debug_measurement_min_us);
    SPMS1_DEBUG_PRINT_SERIAL.print("\e[2;1H\e[K");
    SPMS1_DEBUG_PRINT_SERIAL.print("max ");
    SPMS1_DEBUG_PRINT_SERIAL.print(g_debug_measurement_max_us);

    // Sampled rather than a true high-water mark: tracking the peak would mean a compare and a
    // store inside _sp_gc_root_push, which the module process methods sit on. The count is stable
    // once the synth is running, so sampling it from here is enough to size sp_gc_roots.
    static int s_gc_nroots_max = 0;
    if (sp_gc_nroots > s_gc_nroots_max) { s_gc_nroots_max = sp_gc_nroots; }
    SPMS1_DEBUG_PRINT_SERIAL.print("\e[3;1H\e[K");
    SPMS1_DEBUG_PRINT_SERIAL.print("gc roots ");
    SPMS1_DEBUG_PRINT_SERIAL.print(sp_gc_nroots);
    SPMS1_DEBUG_PRINT_SERIAL.print(" peak ");
    SPMS1_DEBUG_PRINT_SERIAL.print(s_gc_nroots_max);
    SPMS1_DEBUG_PRINT_SERIAL.println();
#if defined(SPMS1_DEBUG_PRINT_USE_USB_SERIAL)
#if defined(SPMS1_USE_USB_MIDI)
    mutex_enter_blocking(&__usb_mutex);
#endif  // defined(SPMS1_USE_USB_MIDI)
    g_debug_print_buffer.transfer_to(Serial);
#if defined(SPMS1_USE_USB_MIDI)
    mutex_exit(&__usb_mutex);
#endif  // defined(SPMS1_USE_USB_MIDI)
#endif  // defined(SPMS1_DEBUG_PRINT_USE_USB_SERIAL)
    // Both cleared on every report, so the pair brackets the buffers since the last one rather
    // than since boot. min is the uncontended compute time, max is what the deadline is about,
    // and the gap between them is interference from core0 and interrupts.
    g_debug_measurement_min_us = UINT32_MAX;
    g_debug_measurement_max_us = 0;
  }
#endif  // defined(SPMS1_USE_DEBUG_PRINT)

  delay(1);
}

// A note on at velocity 0 is a note off, at the default velocity of 64.
void handleNoteOn(byte channel, byte pitch, byte velocity)
{
  if (velocity == 0) {
    handleNoteOff(channel, pitch, 64);
    return;
  }

  set_midi_note_on_pitch(channel - 1, pitch);
  set_midi_note_on_state(channel - 1, 1);
}

void handleNoteOff(byte channel, byte pitch, byte velocity)
{
  if (pitch == g_midi_note_on_pitch[channel - 1]) {
    set_midi_note_on_state(channel - 1, 0);
  }
}

void handleControlChange(byte channel, byte number, byte value)
{
  set_midi_cc_value(channel - 1, number, value);
  handle_midi_nrpn_cc(channel - 1, number, value);
}

void handlePitchBend(byte channel, int bend)
{
  set_midi_pitch_bend(channel - 1, bend);
}
