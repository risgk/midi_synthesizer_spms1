require_relative 'spms_1_oscillator'
require_relative 'spms_1_filter'
require_relative 'spms_1_amp'
require_relative 'spms_1_env_gen'

SAMPLE_RATE = 48000.0
DURATION_SEC = 10.0
NUM_SAMPLES = (SAMPLE_RATE * DURATION_SEC).to_i
FILENAME = "spms_1_output.wav"

oscillator = Spms1::Oscillator.new
oscillator.set_sample_rate(SAMPLE_RATE)
oscillator.set_waveform(64.0 * (1.0 / 128.0))

filter = Spms1::Filter.new
filter.set_sample_rate(SAMPLE_RATE)
filter.set_cutoff(60.0 * (1.0 / 120.0))
filter.set_resonance(80.0 * (1.0 / 128.0))
filter.set_modulation_amount(48.0 * (1.0 / 128.0))

amp = Spms1::Amp.new
amp.set_sample_rate(SAMPLE_RATE)
amp.set_gain((100.0 * 100.0) * (1.0 / (127.0 * 127.0)))

env_gen = Spms1::EnvGen.new
env_gen.set_sample_rate(SAMPLE_RATE)

env_gen.set_attack(0.0 * (1.0 / 128.0))
env_gen.set_decay(128.0 * (1.0 / 128.0))
env_gen.set_sustain(64.0 * (1.0 / 128.0))

puts "Generating stereo waveform data..."

pcm_bytes = []

NUM_SAMPLES.times do |i|
  env_gen_output = env_gen.process(1.0)
  oscillator_output = oscillator.process(60.0 * (1.0 / 120.0) - 0.5)
  filter_output = filter.process(oscillator_output, env_gen_output)
  amp_output = amp.process(filter_output, env_gen_output)

  [amp_output, amp_output].each do |ch_sample|
    clamped_sample = (ch_sample * 0.5 * 8388607.0).round
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
