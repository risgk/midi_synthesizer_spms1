/*
 * MIDI Synthesizer SPMS-1 (type-2)
 */

#pragma GCC optimize ("O3")
#if defined(ARDUINO_ARCH_RP2040)
#pragma GCC target ("thumb")
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

// SerialPIO takes any two pins, where a hardware UART fixes TX to one and RX to the other
#define SPMS1_UART_MIDI_SERIAL              g_uart_midi_serial
#define SPMS1_UART_MIDI_TX_PIN              (4)
#define SPMS1_UART_MIDI_RX_PIN              (5)

// for Pimoroni Pico VGA Demo Base (PIM553)
#define SPMS1_PWM_AUDIO_L_PIN               (28)
#define SPMS1_PWM_AUDIO_R_PIN               (27)

//#define SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO

// for Pimoroni Pico Audio Pack (PIM544)
#define SPMS1_I2S_DAC_MUTE_OFF_PIN          (22)  // Comment out if GP22 is used for something else
#define SPMS1_I2S_DATA_PIN                  (9)
#define SPMS1_I2S_BCLK_PIN                  (10)  // LRCLK is SPMS1_I2S_BCLK_PIN + 1
#define SPMS1_I2S_SWAP_LEFT_AND_RIGHT       (false)

////////////////////////////////////////////////////////////////

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
SerialPIO g_uart_midi_serial(SPMS1_UART_MIDI_TX_PIN, SPMS1_UART_MIDI_RX_PIN, 256);  // FIFO: 256 bytes, to absorb bursts
MIDI_CREATE_CUSTOM_INSTANCE(HardwareSerial, SPMS1_UART_MIDI_SERIAL, UART_MIDI, MySettings);
#endif

#if !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)
#include "spms1_pico2_pwm_audio.h"
SPMS1_PWMAudioOutput g_pwm_output(SPMS1_PWM_AUDIO_L_PIN, SPMS1_PWM_AUDIO_R_PIN);
#else  // !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)
#include "spms1_pico2_i2s.h"
SPMS1_I2SOutput g_i2s_output;
#endif  // !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)

// The patch kept by Save (NRPN 117/2), in the 4 KB sector the core reserves for EEPROM, at the end
// of the flash.
#include <EEPROM.h>

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
void handleSystemExclusive(byte* array, unsigned size);

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

// What core 1 calls from the synth while it plays goes in RAM, as Spms1_main does
// (spinel_rt_mcu_head.h). From flash it would be fetched through the XIP cache, which core 0's
// MIDI and USB code shares: a burst of MIDI evicts it, and the misses land on the synth's buffer.
#if defined(ARDUINO_ARCH_RP2040)
#define SPMS1_RAM_FUNC __attribute__((section(".time_critical.spms1")))
#else
#define SPMS1_RAM_FUNC
#endif

// The MIDI tables the synth reads, and the handlers that fill them, shared with the simulators.
// The patch image is kept in the EEPROM here, below, not in RAM.
#define SPMS1_STORAGE_PROVIDED
#include "spms1_midi_state.h"

// The EEPROM's copy in RAM, read where it is. getConstDataPtr, not getDataPtr, which marks the
// EEPROM as changed, so that the next commit would write the flash whether or not anything did.
const uint8_t* spms1_storage_data(void) {
  return EEPROM.getConstDataPtr();
}

// Called by the synth on core 1, with the output faded out, to write the patch to the flash: the
// whole ring buffer and a little more of silence first, since the DMA keeps playing the ring
// while the flash is written; then the EEPROM, written only where it differs, and committed only
// if anything did, which stops core 0 (the MIDI) for the erase and the program, about 50-100 ms;
// and the writer resynced after, as it stopped longer than the ring lasts.
void spms1_storage_write(const uint8_t* image) {
#if !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)
  SPMS1_AudioRingBuffer& output = g_pwm_output;
#else  // !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)
  SPMS1_AudioRingBuffer& output = g_i2s_output;
#endif  // !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)
  for (uint32_t i = 0; i < output.getBufferFrames() + 8; ++i) {
    output.writeSilence();
  }
  for (int32_t i = 0; i < SPMS1_PATCH_IMAGE_SIZE; ++i) {
    EEPROM.write(i, image[i]);
  }
  EEPROM.commit();
  output.resync();
}

uint32_t g_sample_rate             = 48000;
uint32_t g_audio_buffers           = 2;
uint32_t g_audio_buffer_words      = 64;

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

#if !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)

void start_audio() {
  g_pwm_output.setSysClk(g_sample_rate);
  pinMode(SPMS1_PWM_AUDIO_L_PIN, OUTPUT_12MA);
  pinMode(SPMS1_PWM_AUDIO_R_PIN, OUTPUT_12MA);
  g_pwm_output.setBufferFrames(g_audio_buffers * g_audio_buffer_words);
  g_pwm_output.begin(g_sample_rate);
}

void stop_audio() {
}

SPMS1_RAM_FUNC void write_to_audio_buffer(float l, float r) {
  // Clamped, where fminf and fmaxf are an instruction each, then truncated, which is one too where
  // a rounding is a call to lroundf; the half bit of a 24-bit sample it gives away is below anything
  // the output shows.
  int32_t clamped_l = static_cast<int32_t>(std::fminf(std::fmaxf(l * 8388607.0f, -8388608.0f), 8388607.0f));
  int32_t clamped_r = static_cast<int32_t>(std::fminf(std::fmaxf(r * 8388607.0f, -8388608.0f), 8388607.0f));
  g_pwm_output.write24(clamped_l << 8, clamped_r << 8);
}

#else  // !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)

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

SPMS1_RAM_FUNC void write_to_audio_buffer(float l, float r) {
  // Clamped, where fminf and fmaxf are an instruction each, then truncated, which is one too where
  // a rounding is a call to lroundf; the half bit of a 24-bit sample it gives away is below anything
  // the output shows.
  int32_t clamped_l = static_cast<int32_t>(std::fminf(std::fmaxf(l * 8388607.0f, -8388608.0f), 8388607.0f));
  int32_t clamped_r = static_cast<int32_t>(std::fminf(std::fmaxf(r * 8388607.0f, -8388608.0f), 8388607.0f));
  g_i2s_output.write24(clamped_l << 8, clamped_r << 8);
}

#endif  // !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)

SPMS1_RAM_FUNC void start_debug_measure(void) {
#if defined(SPMS1_USE_DEBUG_PRINT)
  g_debug_measurement_start_us = time_us_32();  // micros() is in flash
#endif  // defined(SPMS1_USE_DEBUG_PRINT)
}

SPMS1_RAM_FUNC void stop_debug_measure(void) {
#if defined(SPMS1_USE_DEBUG_PRINT)
  uint32_t debug_measurement_end_us = time_us_32();
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
  // The synth runs on this core, with flush-to-zero: a denormal result is 0.0, so a smoothing stage
  // or a decaying state heading for 0.0 lands on it rather than sinking into the denormals (see
  // Dsp.smooth in spms1_dsp.rb). FPSCR is per core, so it is set here, ahead of Spms1_main.
  uint32_t fpscr;
  __asm volatile("vmrs %0, fpscr" : "=r"(fpscr));
  fpscr |= (1u << 24);  // FZ
  __asm volatile("vmsr fpscr, %0" : : "r"(fpscr));

  // The patch kept, read from the flash before the synth loads it at power-up.
  EEPROM.begin(SPMS1_PATCH_IMAGE_SIZE);
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
  USB_MIDI.setHandleSystemExclusive(handleSystemExclusive);
  USB_MIDI.begin(MIDI_CHANNEL_OMNI);
  USB_MIDI.turnThruOff();
#endif  // defined(SPMS1_USE_USB_MIDI)

#if defined(SPMS1_USE_UART_MIDI)
  UART_MIDI.setHandleNoteOn(handleNoteOn);
  UART_MIDI.setHandleNoteOff(handleNoteOff);
  UART_MIDI.setHandleControlChange(handleControlChange);
  UART_MIDI.setHandlePitchBend(handlePitchBend);
  UART_MIDI.setHandleSystemExclusive(handleSystemExclusive);
  UART_MIDI.begin(MIDI_CHANNEL_OMNI);  // Begins the serial too, and only once: SerialPIO cannot take a second begin
  UART_MIDI.turnThruOff();
  gpio_pull_up(SPMS1_UART_MIDI_RX_PIN);  // After the begin, which leaves the RX pin without pulls
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
  // 1 byte per read(), as UART_MIDI below: 4 bytes per loop (1 ms or a little more) keep up with
  // what 31250 bps brings, about 3.2 bytes, so USB MIDI is at least as fast as the UART
  mutex_enter_blocking(&__usb_mutex);
  for (uint32_t i = 0; i < 4; i++) {
    USB_MIDI.read();
  }
  mutex_exit(&__usb_mutex);
#endif  // defined(SPMS1_USE_USB_MIDI)

#if defined(SPMS1_USE_UART_MIDI)
  // The MIDI Library parses 1 byte per read(), and up to about 3.2 bytes arrive per loop (1 ms or
  // a little more) at 31250 bps, so read 8 bytes per loop not to overflow the receive FIFO
  for (uint32_t i = 0; i < 8; i++) {
    UART_MIDI.read();
  }
#endif  // defined(SPMS1_USE_UART_MIDI)

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

    // The output's DMA passing the writer, since the start: a click each, while anything sounds.
    // The writes to the output come after the span min and max measure, so they show up here first.
    SPMS1_DEBUG_PRINT_SERIAL.print("\e[4;1H\e[K");
    SPMS1_DEBUG_PRINT_SERIAL.print("underruns ");
#if !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)
    SPMS1_DEBUG_PRINT_SERIAL.print(g_pwm_output.getUnderruns());
#else  // !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)
    SPMS1_DEBUG_PRINT_SERIAL.print(g_i2s_output.getUnderruns());
#endif  // !defined(SPMS1_USE_I2S_INSTEAD_OF_PWM_AUDIO)
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

void handleNoteOn(byte channel, byte pitch, byte velocity)
{
  spms1_handle_note_on(channel - 1, pitch, velocity);
}

void handleNoteOff(byte channel, byte pitch, byte velocity)
{
  spms1_handle_note_off(channel - 1, pitch);
}

void handleControlChange(byte channel, byte number, byte value)
{
  spms1_handle_control_change(channel - 1, number, value);
}

void handlePitchBend(byte channel, int bend)
{
  spms1_handle_pitch_bend(channel - 1, bend);
}

// The whole message, F0 and F7 included. One longer than the library takes comes in parts, which
// spms1_handle_sysex ignores, as none ends in F7 with the header before it.
void handleSystemExclusive(byte* array, unsigned size)
{
  spms1_handle_sysex(array, size);
}
