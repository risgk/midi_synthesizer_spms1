/*
 * MIDI Synthesizer SPMS-1 (type-1)
 */

#pragma GCC optimize ("O3")
#if defined(ARDUINO_ARCH_RP2040)
#pragma GCC target ("thumb")
#pragma GCC section text=".time_critical"
#endif  // defined(ARDUINO_ARCH_RP2040)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-function"

#define SPMS1_USE_DEBUG_PRINT
#define SPMS1_USE_USB_MIDI                  // Select USB Mode: "USB-OTG (TinyUSB)" (ESP32-S3) or USB Stack: "Adafruit TinyUSB" (RP2350) in the Arduino IDE "Tools" menu
#define SPMS1_USE_UART_MIDI

#define SPMS1_UART_MIDI_SPEED               (31250)

#if defined(ARDUINO_ARCH_ESP32)

// for M5Stack AtomS3 Lite
// The board "M5AtomS3" covers the AtomS3 too, which has no RGB LED, so the LED is switched here.
#define SPMS1_M5STACK_ATOMS3_LITE
// PWM levels, 0-255, picked by eye to read as Ruby, #E0115F. The LED's primaries are not sRGB's,
// so converting the colour does not land on it.
#define SPMS1_LED_LEVEL_R                   (48)
#define SPMS1_LED_LEVEL_G                   (0)
#define SPMS1_LED_LEVEL_B                   (16)

#define SPMS1_DEBUG_PRINT_SERIAL            Serial  // USB CDC, next to USB MIDI

#define SPMS1_UART_MIDI_SERIAL              Serial2
#define SPMS1_UART_MIDI_TX_PIN              (2)     // Grove
#define SPMS1_UART_MIDI_RX_PIN              (1)     // Grove

// for M5Stack Atomic Audio-3.5 Base
#define SPMS1_I2S_DATA_PIN                  (5)
#define SPMS1_I2S_BCLK_PIN                  (8)
#define SPMS1_I2S_LRCK_PIN                  (6)
#define SPMS1_I2C_SDA_PIN                   (38)
#define SPMS1_I2C_SCL_PIN                   (39)
#define SPMS1_ES8311_DAC_VOLUME             (0xBF)  // 0.5 dB steps, 0xBF = 0 dB

#define SPMS1_SYNTH_TASK_STACK_SIZE         (16384)

#else  // defined(ARDUINO_ARCH_ESP32)

#define SPMS1_DEBUG_PRINT_SERIAL            Serial1
#define SPMS1_DEBUG_PRINT_TX_PIN            (0)
#define SPMS1_DEBUG_PRINT_RX_PIN            (1)

#define SPMS1_UART_MIDI_SERIAL              Serial2
#define SPMS1_UART_MIDI_TX_PIN              (4)
#define SPMS1_UART_MIDI_RX_PIN              (5)

// for Pimoroni Pico Audio Pack (PIM544)
#define SPMS1_I2S_DATA_PIN                  (9)
#define SPMS1_I2S_BCLK_PIN                  (10)
#define SPMS1_I2S_SWAP_LEFT_AND_RIGHT       (false)

#endif  // defined(ARDUINO_ARCH_ESP32)

////////////////////////////////////////////////////////////////

#include <algorithm>
#include <cmath>

#include <MIDI.h>
struct MySettings : public midi::DefaultSettings {
  static const long BaudRate = SPMS1_UART_MIDI_SPEED;
  static const bool HandleNullVelocityNoteOnAsNoteOff = false;
};

#if defined(SPMS1_USE_USB_MIDI)
#if defined(ARDUINO_ARCH_ESP32)
#if ARDUINO_USB_MODE
#error Select USB Mode: "USB-OTG (TinyUSB)" in the Arduino IDE "Tools" menu
#endif  // ARDUINO_USB_MODE
#include <USB.h>
#include <USBMIDI.h>
USBMIDI g_usb_midi("SPMS-1 (type-1)");
#else  // defined(ARDUINO_ARCH_ESP32)
#include <Adafruit_TinyUSB.h>
Adafruit_USBD_MIDI usbd_midi;
MIDI_CREATE_CUSTOM_INSTANCE(Adafruit_USBD_MIDI, usbd_midi, USB_MIDI, MySettings);
#endif  // defined(ARDUINO_ARCH_ESP32)
#endif  // defined(SPMS1_USE_USB_MIDI)

#if defined(SPMS1_USE_UART_MIDI)
MIDI_CREATE_CUSTOM_INSTANCE(HardwareSerial, SPMS1_UART_MIDI_SERIAL, UART_MIDI, MySettings);
#endif

#if defined(ARDUINO_ARCH_ESP32)
#include <Wire.h>
#include <driver/i2s_std.h>
i2s_chan_handle_t g_i2s_output = NULL;
int32_t*          g_i2s_frames = NULL;
uint32_t          g_i2s_frame_index = 0;
TaskHandle_t      g_synth_task = NULL;
#else  // defined(ARDUINO_ARCH_ESP32)
#include <I2S.h>
I2S g_i2s_output(OUTPUT);
#endif  // defined(ARDUINO_ARCH_ESP32)

uint32_t g_debug_measurement_start_us = 0;
uint32_t g_debug_measurement_min_us   = UINT32_MAX;
uint32_t g_debug_measurement_max_us   = 0;
uint32_t g_debug_measurement_counted  = 0;  // 0 until the first buffer has been measured

void handleNoteOn(byte channel, byte pitch, byte velocity);
void handleNoteOff(byte channel, byte pitch, byte velocity);
void handleControlChange(byte channel, byte number, byte value);
void handlePitchBend(byte channel, int bend);

#if defined(ARDUINO_ARCH_ESP32)

static void write_i2c_register(uint8_t address, uint8_t reg, uint8_t value) {
  Wire.beginTransmission(address);
  Wire.write(reg);
  Wire.write(value);
  Wire.endTransmission();
}

static uint8_t read_i2c_register(uint8_t address, uint8_t reg) {
  Wire.beginTransmission(address);
  Wire.write(reg);
  Wire.endTransmission(false);
  Wire.requestFrom(address, static_cast<uint8_t>(1));
  return Wire.read();
}

// Follows es8311_init() in M5Atomic-EchoBase, minus the microphone. The ES8311 takes its master
// clock from SCLK, so the dividers are for SCLK = 48 kHz x 64 = 3.072 MHz: 48 kHz and 32-bit
// slots only.
static void start_es8311() {
  const uint8_t ES8311 = 0x18;
  write_i2c_register(ES8311, 0x00, 0x1F);  // Reset
  delay(20);
  write_i2c_register(ES8311, 0x00, 0x00);
  write_i2c_register(ES8311, 0x00, 0x80);  // Power on, slave
  write_i2c_register(ES8311, 0x01, 0xBF);  // All clocks on, MCLK from SCLK
  write_i2c_register(ES8311, 0x02, (read_i2c_register(ES8311, 0x02) & 0x07) | (2 << 3));  // Pre-multiply x4
  write_i2c_register(ES8311, 0x03, 0x10);  // ADC OSR
  write_i2c_register(ES8311, 0x04, 0x10);  // DAC OSR
  write_i2c_register(ES8311, 0x05, 0x00);  // ADC and DAC dividers 1
  write_i2c_register(ES8311, 0x06, (read_i2c_register(ES8311, 0x06) & 0xC0) | 0x03);  // SCLK not inverted, divider 4
  write_i2c_register(ES8311, 0x07, read_i2c_register(ES8311, 0x07) & 0xC0);  // LRCK divider 0x00FF
  write_i2c_register(ES8311, 0x08, 0xFF);
  write_i2c_register(ES8311, 0x09, 0x10);  // SDP in, I2S, 32-bit
  write_i2c_register(ES8311, 0x0A, 0x10);  // SDP out, I2S, 32-bit
  write_i2c_register(ES8311, 0x0D, 0x01);  // Analog power up
  write_i2c_register(ES8311, 0x0E, 0x02);
  write_i2c_register(ES8311, 0x12, 0x00);  // DAC power up
  write_i2c_register(ES8311, 0x13, 0x10);  // Output to HP drive
  write_i2c_register(ES8311, 0x1C, 0x6A);
  write_i2c_register(ES8311, 0x37, 0x08);  // DAC equalizer bypassed
  write_i2c_register(ES8311, 0x32, SPMS1_ES8311_DAC_VOLUME);
}

// The PI4IOE5V6408 drives the power amplifier's enable from P0.
static void start_pi4ioe() {
  const uint8_t PI4IOE = 0x43;
  read_i2c_register(PI4IOE, 0x00);
  write_i2c_register(PI4IOE, 0x07, 0x00);  // Outputs high-impedance
  write_i2c_register(PI4IOE, 0x0D, 0xFF);  // Pull-ups
  write_i2c_register(PI4IOE, 0x03, 0x6F);  // Directions
  write_i2c_register(PI4IOE, 0x05, 0xFF);  // Outputs high
}

#endif  // defined(ARDUINO_ARCH_ESP32)

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

#if defined(ARDUINO_ARCH_ESP32)

void start_audio() {
  g_i2s_frames = static_cast<int32_t*>(calloc(g_audio_buffer_words * 2, sizeof(int32_t)));
  g_i2s_frame_index = 0;

  i2s_chan_config_t chan_cfg = I2S_CHANNEL_DEFAULT_CONFIG(I2S_NUM_0, I2S_ROLE_MASTER);
  chan_cfg.dma_desc_num  = g_audio_buffers;
  chan_cfg.dma_frame_num = g_audio_buffer_words;
  chan_cfg.auto_clear    = true;
  i2s_new_channel(&chan_cfg, &g_i2s_output, NULL);

  i2s_std_config_t std_cfg = {
    .clk_cfg  = I2S_STD_CLK_DEFAULT_CONFIG(g_sample_rate),
    .slot_cfg = I2S_STD_PHILIPS_SLOT_DEFAULT_CONFIG(I2S_DATA_BIT_WIDTH_32BIT, I2S_SLOT_MODE_STEREO),
    .gpio_cfg = {
      .mclk = I2S_GPIO_UNUSED,
      .bclk = static_cast<gpio_num_t>(SPMS1_I2S_BCLK_PIN),
      .ws   = static_cast<gpio_num_t>(SPMS1_I2S_LRCK_PIN),
      .dout = static_cast<gpio_num_t>(SPMS1_I2S_DATA_PIN),
      .din  = I2S_GPIO_UNUSED,
      .invert_flags = {
        .mclk_inv = false,
        .bclk_inv = false,
        .ws_inv   = false,
      },
    },
  };
  i2s_channel_init_std_mode(g_i2s_output, &std_cfg);
  i2s_channel_enable(g_i2s_output);

  Wire.begin(SPMS1_I2C_SDA_PIN, SPMS1_I2C_SCL_PIN, 100000U);
  start_es8311();
  start_pi4ioe();

#if defined(ARDUINO_M5STACK_ATOMS3) && defined(SPMS1_M5STACK_ATOMS3_LITE)
  rgbLedWrite(RGB_BUILTIN, SPMS1_LED_LEVEL_R, SPMS1_LED_LEVEL_G, SPMS1_LED_LEVEL_B);
#endif  // defined(ARDUINO_M5STACK_ATOMS3) && defined(SPMS1_M5STACK_ATOMS3_LITE)
}

void stop_audio() {
  i2s_channel_disable(g_i2s_output);
  i2s_del_channel(g_i2s_output);
  g_i2s_output = NULL;
  free(g_i2s_frames);
  g_i2s_frames = NULL;
}

// One i2s_channel_write per buffer, not per frame: each call takes the channel's lock.
IRAM_ATTR void write_to_audio_buffer(float l, float r) {
  int32_t clamped_l = static_cast<int32_t>(std::lroundf(l * 8388607.0f));
  int32_t clamped_r = static_cast<int32_t>(std::lroundf(r * 8388607.0f));
  clamped_l = std::clamp(clamped_l, static_cast<int32_t>(-8388608), static_cast<int32_t>(8388607));
  clamped_r = std::clamp(clamped_r, static_cast<int32_t>(-8388608), static_cast<int32_t>(8388607));
  g_i2s_frames[g_i2s_frame_index * 2]     = clamped_l << 8;
  g_i2s_frames[g_i2s_frame_index * 2 + 1] = clamped_r << 8;
  if (++g_i2s_frame_index == g_audio_buffer_words) {
    size_t bytes_written;
    i2s_channel_write(g_i2s_output, g_i2s_frames, g_audio_buffer_words * 2 * sizeof(int32_t), &bytes_written, portMAX_DELAY);
    g_i2s_frame_index = 0;
  }
}

#else  // defined(ARDUINO_ARCH_ESP32)

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

#endif  // defined(ARDUINO_ARCH_ESP32)

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

#if defined(ARDUINO_ARCH_ESP32)

void control_loop();

void synth_task(void* parameter) {
  Spms1_main(0, NULL);
  vTaskDelete(NULL);
}

void control_task(void* parameter) {
  for (;;) {
    control_loop();
  }
}

#if defined(SPMS1_USE_USB_MIDI)
// Stands in for the MIDI library, which has no transport for the core's USBMIDI. Dispatches the
// same four messages, with pitch bend signed as the library would hand it over.
void read_usb_midi() {
  midiEventPacket_t packet;
  while (g_usb_midi.readPacket(&packet)) {
    byte channel = (packet.byte1 & 0x0F) + 1;
    switch (packet.header & 0x0F) {
    case 0x8:
      handleNoteOff(channel, packet.byte2, packet.byte3);
      break;
    case 0x9:
      handleNoteOn(channel, packet.byte2, packet.byte3);
      break;
    case 0xB:
      handleControlChange(channel, packet.byte2, packet.byte3);
      break;
    case 0xE:
      handlePitchBend(channel, ((packet.byte3 << 7) | packet.byte2) - 8192);
      break;
    }
  }
}
#endif  // defined(SPMS1_USE_USB_MIDI)

#else  // defined(ARDUINO_ARCH_ESP32)

void setup1() {
}

void loop1() {
  Spms1_main(0, NULL);
}

#endif  // defined(ARDUINO_ARCH_ESP32)

void setup() {
  delay(100);

#if defined(SPMS1_USE_DEBUG_PRINT)
#if !defined(ARDUINO_ARCH_ESP32)
  pinMode(SPMS1_DEBUG_PRINT_RX_PIN, INPUT_PULLUP);
  SPMS1_DEBUG_PRINT_SERIAL.setTX(SPMS1_DEBUG_PRINT_TX_PIN);
  SPMS1_DEBUG_PRINT_SERIAL.setRX(SPMS1_DEBUG_PRINT_RX_PIN);
#endif  // !defined(ARDUINO_ARCH_ESP32)
  SPMS1_DEBUG_PRINT_SERIAL.begin(115200);
#endif  // defined(SPMS1_USE_DEBUG_PRINT)

#if defined(SPMS1_USE_USB_MIDI)
#if defined(ARDUINO_ARCH_ESP32)
  // Both names are ignored with USB CDC On Boot enabled, which starts USB before setup(). The
  // MIDI interface keeps the name given to g_usb_midi either way.
  USB.manufacturerName("ISGK Instruments");
  USB.productName("SPMS-1 (type-1)");
  g_usb_midi.begin();
  USB.begin();
#else  // defined(ARDUINO_ARCH_ESP32)
  TinyUSB_Device_Init(0);
  USBDevice.setManufacturerDescriptor("ISGK Instruments");
  USBDevice.setProductDescriptor("SPMS-1 (type-1)");
  USB_MIDI.setHandleNoteOn(handleNoteOn);
  USB_MIDI.setHandleNoteOff(handleNoteOff);
  USB_MIDI.setHandleControlChange(handleControlChange);
  USB_MIDI.setHandlePitchBend(handlePitchBend);
  USB_MIDI.begin(MIDI_CHANNEL_OMNI);
  USB_MIDI.turnThruOff();
#endif  // defined(ARDUINO_ARCH_ESP32)
#endif  // defined(SPMS1_USE_USB_MIDI)

#if defined(SPMS1_USE_UART_MIDI)
#if defined(ARDUINO_ARCH_ESP32)
  // Started on its pins before UART_MIDI.begin(), whose pinless begin() keeps the pins already
  // set. Left to itself, that begin() would put UART2 on its default pins, GPIO19 and GPIO20,
  // which are the ESP32-S3's USB D- and D+.
  SPMS1_UART_MIDI_SERIAL.begin(SPMS1_UART_MIDI_SPEED, SERIAL_8N1, SPMS1_UART_MIDI_RX_PIN, SPMS1_UART_MIDI_TX_PIN);
#else  // defined(ARDUINO_ARCH_ESP32)
  pinMode(SPMS1_UART_MIDI_RX_PIN, INPUT_PULLUP);
  SPMS1_UART_MIDI_SERIAL.setTX(SPMS1_UART_MIDI_TX_PIN);
  SPMS1_UART_MIDI_SERIAL.setRX(SPMS1_UART_MIDI_RX_PIN);
#endif  // defined(ARDUINO_ARCH_ESP32)
  UART_MIDI.setHandleNoteOn(handleNoteOn);
  UART_MIDI.setHandleNoteOff(handleNoteOff);
  UART_MIDI.setHandleControlChange(handleControlChange);
  UART_MIDI.setHandlePitchBend(handlePitchBend);
  UART_MIDI.begin(MIDI_CHANNEL_OMNI);
  UART_MIDI.turnThruOff();
#if !defined(ARDUINO_ARCH_ESP32)
  SPMS1_UART_MIDI_SERIAL.begin(SPMS1_UART_MIDI_SPEED);
#endif  // !defined(ARDUINO_ARCH_ESP32)
#endif  // defined(SPMS1_USE_UART_MIDI)

#if defined(ARDUINO_RASPBERRY_PI_PICO) || defined(ARDUINO_RASPBERRY_PI_PICO_2)
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, HIGH);

  pinMode(23, OUTPUT);  // RT6150 (PMIC) Power Save Pin
  digitalWrite(23, HIGH);
#endif  // defined(ARDUINO_RASPBERRY_PI_PICO) || defined(ARDUINO_RASPBERRY_PI_PICO_2)

#if defined(ARDUINO_ARCH_ESP32)
  // The synth gets core 1 to itself, as on the RP2350, and blocks in i2s_channel_write for the
  // rest of each buffer. MIDI moves to core 0, whose idle task the task watchdog watches, so the
  // synth must not go there. loopTask shares core 1 and is deleted from loop().
  xTaskCreatePinnedToCore(synth_task, "spms1_synth", SPMS1_SYNTH_TASK_STACK_SIZE, NULL, configMAX_PRIORITIES - 2, &g_synth_task, 1);
  xTaskCreatePinnedToCore(control_task, "spms1_control", 4096, NULL, 1, NULL, 0);
#endif  // defined(ARDUINO_ARCH_ESP32)
}

#if defined(ARDUINO_ARCH_ESP32)

void loop() {
  vTaskDelete(NULL);
}

void control_loop() {
#else  // defined(ARDUINO_ARCH_ESP32)

void loop() {
#endif  // defined(ARDUINO_ARCH_ESP32)
#if defined(SPMS1_USE_USB_MIDI)
#if defined(ARDUINO_ARCH_ESP32)
  read_usb_midi();
#else  // defined(ARDUINO_ARCH_ESP32)
  USB_MIDI.read();
#endif  // defined(ARDUINO_ARCH_ESP32)
#endif  // defined(SPMS1_USE_USB_MIDI)

#if defined(SPMS1_USE_UART_MIDI)
  UART_MIDI.read();
#endif

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
#if defined(ARDUINO_ARCH_ESP32)
    // What is left of SPMS1_SYNTH_TASK_STACK_SIZE at the deepest point so far.
    SPMS1_DEBUG_PRINT_SERIAL.print("\e[4;1H\e[K");
    SPMS1_DEBUG_PRINT_SERIAL.print("stack free ");
    SPMS1_DEBUG_PRINT_SERIAL.print(uxTaskGetStackHighWaterMark(g_synth_task));
#endif  // defined(ARDUINO_ARCH_ESP32)
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

void handlePitchBend(byte channel, int bend)
{
  set_midi_pitch_bend(channel - 1, bend);
}
