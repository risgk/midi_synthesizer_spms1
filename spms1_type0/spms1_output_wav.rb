require_relative 'spms1_oscillator'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'
require_relative 'spms1_control_value_smoother'

SAMPLE_RATE = 48000.0
DURATION_SEC = 30.0
NUM_SAMPLES = (SAMPLE_RATE * DURATION_SEC).to_i
FILENAME = "spms1_output.wav"

oscillator = Spms1::Oscillator.new(SAMPLE_RATE)
oscillator_waveform_target = 0.0 * (1.0 / 128.0)
oscillator_waveform_smoother = Spms1::ControlValueSmoother.new(SAMPLE_RATE, 0.0)

filter = Spms1::Filter.new(SAMPLE_RATE)
filter_cutoff_target = 64.0 * (1.0 / 120.0)
filter_resonance_target = 64.0 * (1.0 / 128.0)
filter_modulation_amount_target = 64.0 * (1.0 / 128.0)
filter_cutoff_smoother = Spms1::ControlValueSmoother.new(SAMPLE_RATE, 1.0)
filter_resonance_smoother = Spms1::ControlValueSmoother.new(SAMPLE_RATE, 0.0)
filter_modulation_amount_smoother = Spms1::ControlValueSmoother.new(SAMPLE_RATE, 0.0)

amp = Spms1::Amp.new
amp_gain_target = (100.0 * 100.0) * (1.0 / (127.0 * 127.0))
amp_gain_smoother = Spms1::ControlValueSmoother.new(SAMPLE_RATE, 1.0)

env_gen = Spms1::EnvGen.new(SAMPLE_RATE)

env_gen_attack_target = 0.0 * (1.0 / 128.0)
env_gen_decay_target = 128.0 * (1.0 / 128.0)
env_gen_sustain_target = 0.0 * (1.0 / 128.0)
env_gen_attack_smoother = Spms1::ControlValueSmoother.new(SAMPLE_RATE, 0.0)
env_gen_decay_smoother = Spms1::ControlValueSmoother.new(SAMPLE_RATE, 0.0)
env_gen_sustain_smoother = Spms1::ControlValueSmoother.new(SAMPLE_RATE, 1.0)

puts "Generating stereo waveform data..."

pcm_bytes = []

NUM_SAMPLES.times do |i|
  oscillator_waveform = oscillator_waveform_smoother.process(oscillator_waveform_target)
  filter_cutoff = filter_cutoff_smoother.process(filter_cutoff_target)
  filter_resonance = filter_resonance_smoother.process(filter_resonance_target)
  filter_modulation_amount = filter_modulation_amount_smoother.process(filter_modulation_amount_target)
  amp_gain = amp_gain_smoother.process(amp_gain_target)
  env_gen_attack = env_gen_attack_smoother.process(env_gen_attack_target)
  env_gen_decay = env_gen_decay_smoother.process(env_gen_decay_target)
  env_gen_sustain = env_gen_sustain_smoother.process(env_gen_sustain_target)

  env_gen_output = env_gen.process(1.0, env_gen_attack, env_gen_decay, env_gen_sustain)
  oscillator_output = oscillator.process(60.0 * (1.0 / 120.0) - 0.5, oscillator_waveform)
  filter_output = filter.process(oscillator_output * 0.5, env_gen_output, filter_cutoff, filter_resonance, filter_modulation_amount)
  amp_output = amp.process(filter_output, env_gen_output, amp_gain)

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
