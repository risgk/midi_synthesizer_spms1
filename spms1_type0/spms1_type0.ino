/*
 * MIDI Synthesizer SPMS-1 (type-0)
 */

#pragma GCC optimize ("O3")
#pragma GCC target ("thumb")
#pragma GCC section text=".time_critical"
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-function"

#define SPMS1_USE_DEBUG_PRINT
#define SPMS1_USE_USB_MIDI                  // Select USB Stack: "Adafruit TinyUSB" in the Arduino IDE "Tools" menu
#define SPMS1_USE_UART_MIDI

#define SPMS1_DEBUG_PRINT_SERIAL            Serial1
#define SPMS1_DEBUG_PRINT_TX_PIN            (0)
#define SPMS1_DEBUG_PRINT_RX_PIN            (1)

#define SPMS1_UART_MIDI_SPEED               (31250)
#define SPMS1_UART_MIDI_SERIAL              Serial2
#define SPMS1_UART_MIDI_TX_PIN              (4)
#define SPMS1_UART_MIDI_RX_PIN              (5)

// for Pimoroni Pico Audio Pack (PIM544)
#define SPMS1_I2S_DATA_PIN                  (9)
#define SPMS1_I2S_BCLK_PIN                  (10)
#define SPMS1_I2S_SWAP_LEFT_AND_RIGHT       (false)

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
Adafruit_USBD_MIDI usbd_midi;
MIDI_CREATE_CUSTOM_INSTANCE(Adafruit_USBD_MIDI, usbd_midi, USB_MIDI, MySettings);
#endif  // defined(SPMS1_USE_USB_MIDI)

#if defined(SPMS1_USE_UART_MIDI)
MIDI_CREATE_CUSTOM_INSTANCE(HardwareSerial, SPMS1_UART_MIDI_SERIAL, UART_MIDI, MySettings);
#endif

#include <I2S.h>
I2S g_i2s_output(OUTPUT);

uint32_t g_debug_measurement_start_us = 0;
uint32_t g_debug_measurement_min_us   = UINT32_MAX;
uint32_t g_debug_measurement_max_us   = 0;
uint32_t g_debug_measurement_counted  = 0;  // 0 until the first buffer has been measured

void handleNoteOn(byte channel, byte pitch, byte velocity);
void handleNoteOff(byte channel, byte pitch, byte velocity);
void handleControlChange(byte channel, byte number, byte value);

extern "C" {

extern int Spms1_main(int argc, char **argv);

uint8_t  g_midi_note_on_pitch[16]  = {60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60};
uint8_t  g_midi_note_on_state[16]  = {};
uint8_t  g_midi_cc_values[16][128] = {};

// NRPN parameter numbers are (MSB << 7) | LSB; the synth uses MSB 0-3 as categories, so 512
// entries cover it. Values are 7-bit, filled from CC 6.
#define SPMS1_NRPN_SIZE (512)
uint8_t  g_midi_nrpn_values[16][SPMS1_NRPN_SIZE] = {};
uint8_t  g_midi_nrpn_msb[16]            = {};
uint8_t  g_midi_nrpn_lsb[16]            = {};
uint8_t  g_midi_nrpn_selected[16]       = {};  // 0 until CC 99 or 98 arrives, and again after an RPN

uint32_t g_sample_rate             = 96000;
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

void start_audio() {
  g_i2s_output.setSysClk(g_sample_rate);
  g_i2s_output.setFrequency(g_sample_rate);
  g_i2s_output.setDATA(SPMS1_I2S_DATA_PIN);
  g_i2s_output.setBCLK(SPMS1_I2S_BCLK_PIN);
  g_i2s_output.setBitsPerSample(24);
  g_i2s_output.setBuffers(g_audio_buffers, g_audio_buffer_words);
  g_i2s_output.begin();
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

#if defined(SPMS1_USE_DEBUG_PRINT)
  pinMode(SPMS1_DEBUG_PRINT_RX_PIN, INPUT_PULLUP);
  SPMS1_DEBUG_PRINT_SERIAL.setTX(SPMS1_DEBUG_PRINT_TX_PIN);
  SPMS1_DEBUG_PRINT_SERIAL.setRX(SPMS1_DEBUG_PRINT_RX_PIN);
  SPMS1_DEBUG_PRINT_SERIAL.begin(115200);
#endif  // defined(SPMS1_USE_DEBUG_PRINT)

#if defined(SPMS1_USE_USB_MIDI)
  TinyUSB_Device_Init(0);
  USBDevice.setManufacturerDescriptor("ISGK Instruments");
  USBDevice.setProductDescriptor("SPMS-1 (type-0)");
  USB_MIDI.setHandleNoteOn(handleNoteOn);
  USB_MIDI.setHandleNoteOff(handleNoteOff);
  USB_MIDI.setHandleControlChange(handleControlChange);
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
  USB_MIDI.read();
#endif  // defined(SPMS1_USE_USB_MIDI)

#if defined(SPMS1_USE_UART_MIDI)
  UART_MIDI.read();
#endif

  static uint8_t s_loop_counter = 0;
  if (++s_loop_counter == 0) {
    SPMS1_DEBUG_PRINT_SERIAL.print("\e[1;1H\e[K");
    SPMS1_DEBUG_PRINT_SERIAL.print(g_debug_measurement_min_us);
    SPMS1_DEBUG_PRINT_SERIAL.print("\e[2;1H\e[K");
    SPMS1_DEBUG_PRINT_SERIAL.print(g_debug_measurement_max_us);
    // Both cleared on every report, so the pair brackets the buffers since the last one rather
    // than since boot. min is the uncontended compute time, max is what the deadline is about,
    // and the gap between them is interference from core0 and interrupts.
    g_debug_measurement_min_us = UINT32_MAX;
    g_debug_measurement_max_us = 0;
  }

  delay(1);
}

void handleNoteOn(byte channel, byte pitch, byte velocity)
{
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
