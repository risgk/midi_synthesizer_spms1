# Renders the default patch offline, module for module: the same modules in the same order, wired
# the way spms1_main.rb wires them, on the CC values it ships with.
# What it does not reproduce is the layer above, the signals bus and the run order and the NRPN
# table, so it will not catch a routing mistake, only a change in what the modules do themselves.
require_relative '../spms1_osc'
require_relative '../spms1_filter'
require_relative '../spms1_amp'
require_relative '../spms1_env_gen'
require_relative '../spms1_lfo'
require_relative '../spms1_mixer'
require_relative '../spms1_chorus'
require_relative '../spms1_delay'

SAMPLE_RATE = 48000.0
# Long enough for the release and the delay's repeats after it to fall to about -100 dBFS.
DURATION_SEC = 4.0
NUM_SAMPLES = (SAMPLE_RATE * DURATION_SEC).to_i
FILENAME = "spms1_output.wav"
NOTE = 60
# The gate is let go here, so that the default Sustain, at the top of its dial, does not hold the
# note through the whole render, and the release at the Decay rate is heard.
GATE_SAMPLES = (SAMPLE_RATE * 1.0).to_i

# The same converters spms1_main.rb uses, so a number here means the CC value it looks like.
def cc_to_unipolar(value)
  scaled = (value.to_f - 4.0) * (1.0 / 120.0)
  (scaled < 0.0) ? 0.0 : ((scaled > 1.0) ? 1.0 : scaled)
end

def cc_to_bipolar(value)
  scaled = (value.to_f - 64.0) * (1.0 / 120.0)
  (scaled < -0.5) ? -0.5 : ((scaled > 0.5) ? 0.5 : scaled)
end

# The CC values the synth powers up with.
oscillator = Spms1::Osc.new(SAMPLE_RATE)
oscillator.set_waveform(cc_to_unipolar(4))
oscillator.set_modulation_amount(cc_to_unipolar(4))
oscillator.set_coarse_tune(cc_to_bipolar(64))
oscillator.set_fine_tune(cc_to_bipolar(64))

filter = Spms1::Filter.new(SAMPLE_RATE)
filter.set_cutoff(cc_to_unipolar(100))
filter.set_resonance(cc_to_unipolar(94))
filter.set_modulation_amount(cc_to_unipolar(28))
filter.set_gain(cc_to_unipolar(64))

amp = Spms1::Amp.new(SAMPLE_RATE)
amp.set_gain(cc_to_unipolar(124))

env_gen = Spms1::EnvGen.new(SAMPLE_RATE)
env_gen.set_attack(cc_to_unipolar(4))
env_gen.set_decay(cc_to_unipolar(96))
env_gen.set_sustain(cc_to_unipolar(124))

lfo = Spms1::LFO.new(SAMPLE_RATE)
lfo.set_rate(cc_to_unipolar(64))
# The CC value LFO 1 Level powers up with.
lfo.set_level(cc_to_unipolar(124))
# The constant 0.1 the default patch routes to it.
lfo.set_polarity(0.1)

chorus = Spms1::Chorus.new(SAMPLE_RATE)
chorus.set_rate(cc_to_unipolar(64))
chorus.set_depth(cc_to_unipolar(64))
chorus.set_mix(cc_to_unipolar(64))

delay = Spms1::Delay.new(SAMPLE_RATE)
delay.set_time(cc_to_unipolar(64))
delay.set_feedback(cc_to_unipolar(64))
delay.set_mix(cc_to_unipolar(34))

puts "Generating stereo waveform data..."

pcm_bytes = []

# The default run order, less the mixer it does not use: LFO, EG, Osc, Filter, Amp, Chorus, Delay.
# Each module reads what the ones ahead of it made in this same sample, which is what the run order
# buys. The chorus turns the mono amp into a left and a right, and the delay keeps the two apart.
NUM_SAMPLES.times do |i|
  lfo_output = lfo.process
  env_gen_output = env_gen.process((i < GATE_SAMPLES) ? 1.0 : 0.0)
  oscillator_output = oscillator.process(NOTE * (1.0 / 120.0) - 0.5, lfo_output)
  filter_output = filter.process(oscillator_output, env_gen_output)
  amp_output = amp.process(filter_output, env_gen_output)
  chorus.process(amp_output)
  delay.process(chorus.output_l, chorus.output_r)

  [delay.output_l, delay.output_r].each do |ch_sample|
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
