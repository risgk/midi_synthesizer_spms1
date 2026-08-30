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

uint32_t g_debug_measurement_start_us   = 0;
uint32_t g_debug_measurement_elapsed_us = 0;
uint32_t g_debug_measurement_max_us     = 0;

void handleNoteOn(byte channel, byte pitch, byte velocity);
void handleNoteOff(byte channel, byte pitch, byte velocity);
void handleControlChange(byte channel, byte number, byte value);

extern "C" {

extern int Spms1_main(int argc, char **argv);

uint8_t  g_midi_basic_ch_0_based = 0;
uint8_t  g_midi_note_on_pitch    = 60;
uint8_t  g_midi_note_on_state    = 0;
uint8_t  g_midi_cc_values[128]   = {};
uint32_t g_sample_rate           = 48000;
uint32_t g_audio_buffers         = 2;
uint32_t g_audio_buffer_words    = 128;

void set_midi_note_on_pitch(uint8_t midi_note_on_pitch) {
  g_midi_note_on_pitch = midi_note_on_pitch;
}

uint8_t get_midi_note_on_pitch() {
  return g_midi_note_on_pitch;
}

void set_midi_note_on_state(uint8_t midi_note_on_state) {
  g_midi_note_on_state = midi_note_on_state;
}

uint8_t get_midi_note_on_state() {
  return g_midi_note_on_state;
}

void set_midi_cc_value(uint8_t cc_number, uint8_t cc_value) {
  if (cc_number >= 128) {
    return;
  }

  g_midi_cc_values[cc_number] = cc_value;
}

uint8_t get_midi_cc_value(uint8_t cc_number) {
  if (cc_number >= 128) {
    return 0;
  }

  return g_midi_cc_values[cc_number];
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
  int32_t clamped_l = static_cast<int32_t>(std::lroundf(l * 0.5f * 8388607.0f));
  int32_t clamped_r = static_cast<int32_t>(std::lroundf(r * 0.5f * 8388607.0f));
  clamped_l = std::clamp(clamped_l, static_cast<int32_t>(-8388608), static_cast<int32_t>(8388607));
  clamped_r = std::clamp(clamped_r, static_cast<int32_t>(-8388608), static_cast<int32_t>(8388607));
  g_i2s_output.write24(clamped_l << 8, clamped_r << 8);
}

void debug_measure_begin(void) {
#if defined(SPMS1_USE_DEBUG_PRINT)
  g_debug_measurement_start_us = micros();
#endif  // defined(SPMS1_USE_DEBUG_PRINT)
}

void debug_measure_end(void) {
#if defined(SPMS1_USE_DEBUG_PRINT)
  uint32_t debug_measurement_end_us = micros();
  g_debug_measurement_elapsed_us = debug_measurement_end_us - g_debug_measurement_start_us;
  g_debug_measurement_max_us += (g_debug_measurement_elapsed_us > g_debug_measurement_max_us) *
                                (g_debug_measurement_elapsed_us - g_debug_measurement_max_us);
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
    SPMS1_DEBUG_PRINT_SERIAL.print(g_debug_measurement_elapsed_us);
    SPMS1_DEBUG_PRINT_SERIAL.print("\e[2;1H\e[K");
    SPMS1_DEBUG_PRINT_SERIAL.print(g_debug_measurement_max_us);
  }

  delay(1);
}

void handleNoteOn(byte channel, byte pitch, byte velocity)
{
  if (channel == g_midi_basic_ch_0_based + 1) {
    set_midi_note_on_pitch(pitch);
    set_midi_note_on_state(1);
  }
}

void handleNoteOff(byte channel, byte pitch, byte velocity)
{
  if (channel == g_midi_basic_ch_0_based + 1) {
    if (pitch == g_midi_note_on_pitch) {
      set_midi_note_on_state(0);
    }
  }
}

void handleControlChange(byte channel, byte number, byte value)
{
  if (channel == g_midi_basic_ch_0_based + 1) {
    set_midi_cc_value(number, value);
  }
}
