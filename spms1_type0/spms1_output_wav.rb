require_relative 'spms1_oscillator'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'
require_relative 'spms1_control_value_smoother'
require_relative 'spms1_signal_index'
require_relative 'spms1_module_index'

include Spms1
include SignalIndex
include ModuleIndex

SAMPLE_RATE = 48000.0
DURATION_SEC = 30.0
NUM_SAMPLES = (SAMPLE_RATE * DURATION_SEC).to_i
FILENAME = "spms1_output.wav"

# Pool of instantiated modules, indexed by ModuleIndex; not every slot need be run each sample
# (e.g. several Oscillators could live here with only one actually wired up below).
modules = Array.new(MODULES_SIZE, nil)
modules[ENV_GEN]    = EnvGen.new(SAMPLE_RATE)
modules[OSCILLATOR] = Oscillator.new(SAMPLE_RATE)
modules[FILTER]     = Filter.new(SAMPLE_RATE)
modules[AMP]        = Amp.new

# ModuleIndex values that actually run each sample, in order; a subset of what's in modules.
# Fixed-length, all-Integer array (NONE = no assignment) rather than a dynamically-sized one.
# Packed from the front with no gaps: the loop below stops at the first NONE it hits.
active_module_indices = Array.new(MODULES_SIZE, NONE)
active_module_indices[0] = ENV_GEN
active_module_indices[1] = OSCILLATOR
active_module_indices[2] = FILTER
active_module_indices[3] = AMP

# Which signal feeds each positional argument of a module's process(), and which signal its
# result is written to. Data, indexed by ModuleIndex, so this wiring may become MIDI-assignable
# later without changing the dispatch loop below (SignalIndex::NONE = unused argument slot).
# Flat (not nested) so it stays one static, all-Integer array rather than an array of arrays --
# module_index's row starts at module_index * MODULE_MAX_ARGS.
module_input_signal_indices = Array.new(MODULES_SIZE * MODULE_MAX_ARGS, SignalIndex::NONE)
module_output_signal_indices = Array.new(MODULES_SIZE, SignalIndex::NONE)

module_input_signal_indices[ENV_GEN * MODULE_MAX_ARGS + 0] = GATE
module_input_signal_indices[ENV_GEN * MODULE_MAX_ARGS + 1] = ENV_GEN_ATTACK
module_input_signal_indices[ENV_GEN * MODULE_MAX_ARGS + 2] = ENV_GEN_DECAY
module_input_signal_indices[ENV_GEN * MODULE_MAX_ARGS + 3] = ENV_GEN_SUSTAIN
module_output_signal_indices[ENV_GEN]                      = ENV_GEN_OUTPUT

module_input_signal_indices[OSCILLATOR * MODULE_MAX_ARGS + 0] = PITCH
module_input_signal_indices[OSCILLATOR * MODULE_MAX_ARGS + 1] = OSCILLATOR_WAVEFORM
module_output_signal_indices[OSCILLATOR]                      = OSCILLATOR_OUTPUT

module_input_signal_indices[FILTER * MODULE_MAX_ARGS + 0] = OSCILLATOR_OUTPUT
module_input_signal_indices[FILTER * MODULE_MAX_ARGS + 1] = ENV_GEN_OUTPUT
module_input_signal_indices[FILTER * MODULE_MAX_ARGS + 2] = FILTER_CUTOFF
module_input_signal_indices[FILTER * MODULE_MAX_ARGS + 3] = FILTER_RESONANCE
module_input_signal_indices[FILTER * MODULE_MAX_ARGS + 4] = FILTER_ENV_GEN_MOD_AMOUNT
module_output_signal_indices[FILTER]                      = FILTER_OUTPUT

module_input_signal_indices[AMP * MODULE_MAX_ARGS + 0] = FILTER_OUTPUT
module_input_signal_indices[AMP * MODULE_MAX_ARGS + 1] = ENV_GEN_OUTPUT
module_input_signal_indices[AMP * MODULE_MAX_ARGS + 2] = AMP_GAIN
module_output_signal_indices[AMP]                      = AMP_OUTPUT

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

  # Run the active modules front to back, stopping at the first NONE (see active_module_indices
  # above). Which signal feeds each argument, and where the result lands, comes from
  # module_input_signal_indices / module_output_signal_indices; only the argument count and
  # order (and the Filter audio input's fixed -6dB pad) stay hard-coded per module here.
  active_module_indices.each do |module_index|
    break if module_index == NONE

    current_module = modules[module_index]
    input_base = module_index * MODULE_MAX_ARGS
    in0 = signals[module_input_signal_indices[input_base]]
    in1 = signals[module_input_signal_indices[input_base + 1]]
    in2 = signals[module_input_signal_indices[input_base + 2]]
    in3 = signals[module_input_signal_indices[input_base + 3]]
    in4 = signals[module_input_signal_indices[input_base + 4]]
    output = module_output_signal_indices[module_index]

    case module_index
    when ENV_GEN
      signals[output] = current_module.process(in0, in1, in2, in3)
    when OSCILLATOR
      signals[output] = current_module.process(in0, in1)
    when FILTER
      signals[output] = current_module.process(in0 * 0.5, in1, in2, in3, in4)
    when AMP
      signals[output] = current_module.process(in0, in1, in2)
    end
  end

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
