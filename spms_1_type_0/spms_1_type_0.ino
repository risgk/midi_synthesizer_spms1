/*
 * Music Synth SPMS-1 (type-0)
 */

#define SPMS_1_USE_DEBUG_PRINT
#define SPMS_1_USE_USB_MIDI                 // Select USB Stack: "Adafruit TinyUSB" in the Arduino IDE "Tools" menu
#define SPMS_1_USE_UART_MIDI

#define SPMS_1_MIDI_BASIC_CH_0_BASED        (0)

#define SPMS_1_DEBUG_PRINT_SERIAL           Serial1
#define SPMS_1_DEBUG_PRINT_TX_PIN           (0)
#define SPMS_1_DEBUG_PRINT_RX_PIN           (1)

#define SPMS_1_UART_MIDI_SPEED              (31250)
#define SPMS_1_UART_MIDI_SERIAL             Serial2
#define SPMS_1_UART_MIDI_TX_PIN             (4)
#define SPMS_1_UART_MIDI_RX_PIN             (5)

// for Pimoroni Pico Audio Pack (PIM544)
#define SPMS_1_I2S_DATA_PIN                 (9)
#define SPMS_1_I2S_BCLK_PIN                 (10)
#define SPMS_1_I2S_SWAP_LEFT_AND_RIGHT      (false)

#define SPMS_1_SAMPLE_RATE                  (48000)
#define SPMS_1_I2S_BUFFERS                  (4)
#define SPMS_1_I2S_BUFFER_WORDS             (64)

////////////////////////////////////////////////////////////////

#include <algorithm>

#include <MIDI.h>
struct MySettings : public midi::DefaultSettings {
  static const long BaudRate = SPMS_1_UART_MIDI_SPEED;
  static const bool HandleNullVelocityNoteOnAsNoteOff = false;
};

#if defined(SPMS_1_USE_USB_MIDI)
#include <Adafruit_TinyUSB.h>
Adafruit_USBD_MIDI usbd_midi;
MIDI_CREATE_CUSTOM_INSTANCE(Adafruit_USBD_MIDI, usbd_midi, USB_MIDI, MySettings);
#endif  // defined(SPMS_1_USE_USB_MIDI)

#if defined(SPMS_1_USE_UART_MIDI)
MIDI_CREATE_CUSTOM_INSTANCE(HardwareSerial, SPMS_1_UART_MIDI_SERIAL, UART_MIDI, MySettings);
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

int32_t g_sample_rate           = SPMS_1_SAMPLE_RATE;
int32_t g_audio_buffer_words    = SPMS_1_I2S_BUFFER_WORDS;
uint8_t g_midi_basic_ch_0_based = SPMS_1_MIDI_BASIC_CH_0_BASED;
uint8_t g_midi_note_on_pitch    = 60;
uint8_t g_midi_note_on_state    = 0;
uint8_t g_midi_cc_values[128]   = {};

int32_t get_sample_rate() {
  return g_sample_rate;
}

int32_t get_audio_buffer_words() {
  return g_audio_buffer_words;
}

uint8_t get_midi_note_on_pitch() {
  return g_midi_note_on_pitch;
}

uint8_t get_midi_note_on_state() {
  return g_midi_note_on_state;
}

uint8_t get_midi_cc_value(uint8_t cc_number) {
  const int32_t length = static_cast<int32_t>(sizeof(g_midi_cc_values) / sizeof(g_midi_cc_values[0]));

  if (cc_number < 0 || cc_number >= length) { 
    return 0.0; 
  }

  return g_midi_cc_values[cc_number];
}

void audio_out_write(float l, float r) {
  int32_t clamped_l = static_cast<int32_t>(std::lround(l * 0.5f * 8388607.0f));
  int32_t clamped_r = static_cast<int32_t>(std::lround(r * 0.5f * 8388607.0f));
  clamped_l = std::clamp(clamped_l, static_cast<int32_t>(-8388608), static_cast<int32_t>(8388607));
  clamped_r = std::clamp(clamped_r, static_cast<int32_t>(-8388608), static_cast<int32_t>(8388607));
  g_i2s_output.write24(clamped_l << 8, clamped_r << 8);
}

void debug_measure_begin(void) {
#if defined(SPMS_1_USE_DEBUG_PRINT)
  g_debug_measurement_start_us = micros();
#endif  // defined(SPMS_1_USE_DEBUG_PRINT)
}

void debug_measure_end(void) {
#if defined(SPMS_1_USE_DEBUG_PRINT)
  uint32_t debug_measurement_end_us = micros();
  g_debug_measurement_elapsed_us = debug_measurement_end_us - g_debug_measurement_start_us;
  g_debug_measurement_max_us += (g_debug_measurement_elapsed_us > g_debug_measurement_max_us) *
                                (g_debug_measurement_elapsed_us - g_debug_measurement_max_us);
#endif  // defined(SPMS_1_USE_DEBUG_PRINT)
}

}

void setup1() {
  g_i2s_output.setSysClk(SPMS_1_SAMPLE_RATE);
  g_i2s_output.setFrequency(SPMS_1_SAMPLE_RATE);
  g_i2s_output.setDATA(SPMS_1_I2S_DATA_PIN);
  g_i2s_output.setBCLK(SPMS_1_I2S_BCLK_PIN);
  g_i2s_output.setBitsPerSample(24);
  g_i2s_output.setBuffers(SPMS_1_I2S_BUFFERS, SPMS_1_I2S_BUFFER_WORDS);
  g_i2s_output.begin();

  g_midi_cc_values[20] = 0;   // Oscillator Waveform
  g_midi_cc_values[74] = 127; // Filter Cutoff
  g_midi_cc_values[71] = 80;  // Filter Resonance
  g_midi_cc_values[24] = 48;  // Filter EG Amt
  g_midi_cc_values[15] = 100; // Amp Gain
  g_midi_cc_values[73] = 32;  // EG Attack
  g_midi_cc_values[75] = 104; // EG Decay/Release
  g_midi_cc_values[30] = 0;   // EG Sustain
}

void loop1() {
  Spms1_main(0, NULL);
}

void setup() {
  delay(100);

#if defined(SPMS_1_USE_DEBUG_PRINT)
  pinMode(SPMS_1_DEBUG_PRINT_RX_PIN, INPUT_PULLUP);
  SPMS_1_DEBUG_PRINT_SERIAL.setTX(SPMS_1_DEBUG_PRINT_TX_PIN);
  SPMS_1_DEBUG_PRINT_SERIAL.setRX(SPMS_1_DEBUG_PRINT_RX_PIN);
  SPMS_1_DEBUG_PRINT_SERIAL.begin(115200);
#endif  // defined(SPMS_1_USE_DEBUG_PRINT)

#if defined(SPMS_1_USE_USB_MIDI)
  TinyUSB_Device_Init(0);
  USBDevice.setManufacturerDescriptor("ISGK Instruments");
  USBDevice.setProductDescriptor("SPMS-1 (type-0)");
  USB_MIDI.setHandleNoteOn(handleNoteOn);
  USB_MIDI.setHandleNoteOff(handleNoteOff);
  USB_MIDI.setHandleControlChange(handleControlChange);
  USB_MIDI.begin(MIDI_CHANNEL_OMNI);
  USB_MIDI.turnThruOff();
#endif  // defined(SPMS_1_USE_USB_MIDI)

#if defined(SPMS_1_USE_UART_MIDI)
  pinMode(SPMS_1_UART_MIDI_RX_PIN, INPUT_PULLUP);
  SPMS_1_UART_MIDI_SERIAL.setTX(SPMS_1_UART_MIDI_TX_PIN);
  SPMS_1_UART_MIDI_SERIAL.setRX(SPMS_1_UART_MIDI_RX_PIN);
  UART_MIDI.setHandleNoteOn(handleNoteOn);
  UART_MIDI.setHandleNoteOff(handleNoteOff);
  UART_MIDI.setHandleControlChange(handleControlChange);
  UART_MIDI.begin(MIDI_CHANNEL_OMNI);
  UART_MIDI.turnThruOff();
  SPMS_1_UART_MIDI_SERIAL.begin(SPMS_1_UART_MIDI_SPEED);
#endif  // defined(SPMS_1_USE_UART_MIDI)

#if defined(ARDUINO_RASPBERRY_PI_PICO) || defined(ARDUINO_RASPBERRY_PI_PICO_2)
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  pinMode(23, OUTPUT);  // RT6150 (PMIC) Power Save Pin
  digitalWrite(23, HIGH);
#endif  // defined(ARDUINO_RASPBERRY_PI_PICO) || defined(ARDUINO_RASPBERRY_PI_PICO_2)
}

void loop() {
#if defined(SPMS_1_USE_USB_MIDI)
  USB_MIDI.read();
#endif  // defined(SPMS_1_USE_USB_MIDI)

#if defined(SPMS_1_USE_UART_MIDI)
  UART_MIDI.read();
#endif

  static uint8_t s_loop_counter = 0;
  if (++s_loop_counter == 0) {
    SPMS_1_DEBUG_PRINT_SERIAL.print("\e[1;1H\e[K");
    SPMS_1_DEBUG_PRINT_SERIAL.print(g_debug_measurement_elapsed_us);
    SPMS_1_DEBUG_PRINT_SERIAL.print("\e[2;1H\e[K");
    SPMS_1_DEBUG_PRINT_SERIAL.print(g_debug_measurement_max_us);
  }

  delay(1);
}

void handleNoteOn(byte channel, byte pitch, byte velocity)
{
  if (channel == g_midi_basic_ch_0_based + 1) {
    g_midi_note_on_pitch = pitch;
    g_midi_note_on_state = 1;
  }
}

void handleNoteOff(byte channel, byte pitch, byte velocity)
{
  if (channel == g_midi_basic_ch_0_based + 1) {
    if (pitch == g_midi_note_on_pitch) {
      g_midi_note_on_state = 0;
    }
  }
}

void handleControlChange(byte channel, byte number, byte value)
{
  if (channel == g_midi_basic_ch_0_based + 1) {
    g_midi_cc_values[number] = value;
  }
}
