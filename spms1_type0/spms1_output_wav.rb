require_relative 'spms1_oscillator'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'
require_relative 'spms1_smoother'

SAMPLE_RATE = 48000.0
DURATION_SEC = 30.0
NUM_SAMPLES = (SAMPLE_RATE * DURATION_SEC).to_i
FILENAME = "spms1_output.wav"

oscillator = Spms1::Oscillator.new(SAMPLE_RATE)
waveform_target = 0.0 * (1.0 / 128.0)
waveform_smoother = Spms1::Smoother.new(SAMPLE_RATE, 0.0)

filter = Spms1::Filter.new(SAMPLE_RATE)
cutoff_target = 64.0 * (1.0 / 120.0)
resonance_target = 64.0 * (1.0 / 128.0)
modulation_amount_target = 64.0 * (1.0 / 128.0)
cutoff_smoother = Spms1::Smoother.new(SAMPLE_RATE, 1.0)
resonance_smoother = Spms1::Smoother.new(SAMPLE_RATE, 0.0)
modulation_amount_smoother = Spms1::Smoother.new(SAMPLE_RATE, 0.0)

amp = Spms1::Amp.new
gain_target = (100.0 * 100.0) * (1.0 / (127.0 * 127.0))
gain_smoother = Spms1::Smoother.new(SAMPLE_RATE, 1.0)

env_gen = Spms1::EnvGen.new(SAMPLE_RATE)

attack = 0.0 * (1.0 / 128.0)
decay = 128.0 * (1.0 / 128.0)
sustain = 0.0 * (1.0 / 128.0)

puts "Generating stereo waveform data..."

pcm_bytes = []

NUM_SAMPLES.times do |i|
  waveform = waveform_smoother.process(waveform_target)
  cutoff = cutoff_smoother.process(cutoff_target)
  resonance = resonance_smoother.process(resonance_target)
  modulation_amount = modulation_amount_smoother.process(modulation_amount_target)
  gain = gain_smoother.process(gain_target)

  env_gen_output = env_gen.process(1.0, attack, decay, sustain)
  oscillator_output = oscillator.process(60.0 * (1.0 / 120.0) - 0.5, waveform)
  filter_output = filter.process(oscillator_output * 0.5, env_gen_output, cutoff, resonance, modulation_amount)
  amp_output = amp.process(filter_output, env_gen_output, gain)

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
