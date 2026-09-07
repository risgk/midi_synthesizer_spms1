require_relative 'spms1_oscillator'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'
require_relative 'spms1_control_value_smoother'
require_relative 'spms1_signal_index'

include Spms1
include SignalIndex

SAMPLE_RATE = 48000.0
DURATION_SEC = 30.0
NUM_SAMPLES = (SAMPLE_RATE * DURATION_SEC).to_i
FILENAME = "spms1_output.wav"

oscillator = Oscillator.new(SAMPLE_RATE)
filter = Filter.new(SAMPLE_RATE)
amp = Amp.new
env_gen = EnvGen.new(SAMPLE_RATE)

# ControlValueSmoothers act as the knobs for their module's parameter: main sets the target from
# MIDI CC, and reads back the smoothed current value to feed into the module's process().
oscillator_waveform_smoother = ControlValueSmoother.new(SAMPLE_RATE, 0.0)
filter_cutoff_smoother = ControlValueSmoother.new(SAMPLE_RATE, 1.0)
filter_resonance_smoother = ControlValueSmoother.new(SAMPLE_RATE, 0.0)
filter_env_gen_mod_amount_smoother = ControlValueSmoother.new(SAMPLE_RATE, 0.0)
amp_gain_smoother = ControlValueSmoother.new(SAMPLE_RATE, 1.0)
env_gen_attack_smoother = ControlValueSmoother.new(SAMPLE_RATE, 0.0)
env_gen_decay_smoother = ControlValueSmoother.new(SAMPLE_RATE, 0.0)
env_gen_sustain_smoother = ControlValueSmoother.new(SAMPLE_RATE, 1.0)

# Shared bus that modules are wired through; see SignalIndex for what each slot holds.
signals = Array.new(SIGNALS_SIZE, 0.0)

signals[PITCH] = 60.0 * (1.0 / 120.0) - 0.5
signals[GATE] = 1.0

signals[OSCILLATOR_WAVEFORM_TARGET] = 0.0 * (1.0 / 128.0)
signals[FILTER_CUTOFF_TARGET] = 64.0 * (1.0 / 120.0)
signals[FILTER_RESONANCE_TARGET] = 64.0 * (1.0 / 128.0)
signals[FILTER_ENV_GEN_MOD_AMOUNT_TARGET] = 64.0 * (1.0 / 128.0)
signals[AMP_GAIN_TARGET] = (100.0 * 100.0) * (1.0 / (127.0 * 127.0))
signals[ENV_GEN_ATTACK_TARGET] = 0.0 * (1.0 / 128.0)
signals[ENV_GEN_DECAY_TARGET] = 128.0 * (1.0 / 128.0)
signals[ENV_GEN_SUSTAIN_TARGET] = 0.0 * (1.0 / 128.0)

puts "Generating stereo waveform data..."

pcm_bytes = []

NUM_SAMPLES.times do |i|
  signals[OSCILLATOR_WAVEFORM] = oscillator_waveform_smoother.process(signals[OSCILLATOR_WAVEFORM_TARGET])
  signals[FILTER_CUTOFF] = filter_cutoff_smoother.process(signals[FILTER_CUTOFF_TARGET])
  signals[FILTER_RESONANCE] = filter_resonance_smoother.process(signals[FILTER_RESONANCE_TARGET])
  signals[FILTER_ENV_GEN_MOD_AMOUNT] = filter_env_gen_mod_amount_smoother.process(signals[FILTER_ENV_GEN_MOD_AMOUNT_TARGET])
  signals[AMP_GAIN] = amp_gain_smoother.process(signals[AMP_GAIN_TARGET])
  signals[ENV_GEN_ATTACK] = env_gen_attack_smoother.process(signals[ENV_GEN_ATTACK_TARGET])
  signals[ENV_GEN_DECAY] = env_gen_decay_smoother.process(signals[ENV_GEN_DECAY_TARGET])
  signals[ENV_GEN_SUSTAIN] = env_gen_sustain_smoother.process(signals[ENV_GEN_SUSTAIN_TARGET])

  signals[ENV_GEN_OUTPUT] = env_gen.process(signals[GATE], signals[ENV_GEN_ATTACK], signals[ENV_GEN_DECAY], signals[ENV_GEN_SUSTAIN])
  signals[OSCILLATOR_OUTPUT] = oscillator.process(signals[PITCH], signals[OSCILLATOR_WAVEFORM])
  signals[FILTER_OUTPUT] = filter.process(signals[OSCILLATOR_OUTPUT] * 0.5, signals[ENV_GEN_OUTPUT], signals[FILTER_CUTOFF],
    signals[FILTER_RESONANCE], signals[FILTER_ENV_GEN_MOD_AMOUNT])
  signals[AMP_OUTPUT] = amp.process(signals[FILTER_OUTPUT], signals[ENV_GEN_OUTPUT], signals[AMP_GAIN])

  amp_output = signals[AMP_OUTPUT]

  [amp_output, amp_output].each do |ch_sample|
    clamped_sample = (ch_sample * 8388607.0).round
    clamped_sample = [8388607, [clamped_sample, -8388608].max].min

    pcm_bytes << (clamped_sample & 0xFF)
    pcm_bytes << ((clamped_sample >> 8) & 0xFF)
    pcm_bytes << ((clamped_sample >> 16) & 0xFF)
  end
end

sub_chunk_2_size = pcm_bytes.size
chunk_size = 36 + sub_chunk_2_size
num_channels = 2
bytes_per_sample = 3

byte_rate = (SAMPLE_RATE.to_i) * num_channels * bytes_per_sample
block_align = num_channels * bytes_per_sample

header_bytes = [
  82, 73, 70, 70,
  chunk_size & 0xFF, (chunk_size >> 8) & 0xFF, (chunk_size >> 16) & 0xFF, (chunk_size >> 24) & 0xFF,
  87, 65, 86, 69,
  102, 109, 116, 32,
  16, 0, 0, 0,
  1, 0, 2, 0,
  48000 & 0xFF, (48000 >> 8) & 0xFF, (48000 >> 16) & 0xFF, (48000 >> 24) & 0xFF,
  byte_rate & 0xFF, (byte_rate >> 8) & 0xFF, (byte_rate >> 16) & 0xFF, (byte_rate >> 24) & 0xFF,
  block_align & 0xFF, (block_align >> 8) & 0xFF, 24, 0,
  100, 97, 116, 97,
  sub_chunk_2_size & 0xFF, (sub_chunk_2_size >> 8) & 0xFF, (sub_chunk_2_size >> 16) & 0xFF, (sub_chunk_2_size >> 24) & 0xFF
]

puts "Saving to #{FILENAME}..."
File.open(FILENAME, "wb") do |file|
  header_bytes.each { |b| file.putc(b) }
  pcm_bytes.each { |b| file.putc(b) }
end

puts "Done!"
