require_relative 'spms1_oscillator'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'
require_relative 'spms1_control_value_smoother'
require_relative 'spms1_signal_index'

module Spms1
  module C
    ffi_func :set_midi_note_on_pitch, [:uint8, :uint8],         :void
    ffi_func :get_midi_note_on_pitch, [:uint8],                 :uint8
    ffi_func :set_midi_note_on_state, [:uint8, :uint8],         :void
    ffi_func :get_midi_note_on_state, [:uint8],                 :uint8
    ffi_func :set_midi_cc_value,      [:uint8, :uint8, :uint8], :void
    ffi_func :get_midi_cc_value,      [:uint8, :uint8],         :uint8
    ffi_func :set_sample_rate,        [:int32],                 :void
    ffi_func :get_sample_rate,        [],                       :int32
    ffi_func :set_audio_buffers,      [:int32],                 :void
    ffi_func :get_audio_buffers,      [],                       :int32
    ffi_func :set_audio_buffer_words, [:int32],                 :void
    ffi_func :get_audio_buffer_words, [],                       :int32
    ffi_func :start_audio,            [],                       :void
    ffi_func :stop_audio,             [],                       :void
    ffi_func :write_to_audio_buffer,  [:float, :float],         :void
    ffi_func :start_debug_measure,    [],                       :void
    ffi_func :stop_debug_measure,     [],                       :void
  end
end

include Spms1
include SignalIndex

MIDI_CH            = 0
SAMPLE_RATE        = 96000
AUDIO_BUFFERS      = 2
AUDIO_BUFFER_WORDS = 64

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

audio_buffer = Array.new(AUDIO_BUFFER_WORDS, 0.0)

C.set_midi_cc_value(MIDI_CH, 20 , 0  ) # Oscillator Waveform
C.set_midi_cc_value(MIDI_CH, 74 , 127) # Filter Cutoff
C.set_midi_cc_value(MIDI_CH, 71 , 64 ) # Filter Resonance
C.set_midi_cc_value(MIDI_CH, 24 , 64 ) # Filter EG Amt
C.set_midi_cc_value(MIDI_CH, 15 , 100) # Amp Gain
C.set_midi_cc_value(MIDI_CH, 73 , 0  ) # EG Attack
C.set_midi_cc_value(MIDI_CH, 75 , 96 ) # EG Decay/Release
C.set_midi_cc_value(MIDI_CH, 30 , 0  ) # EG Sustain

C.set_sample_rate(SAMPLE_RATE)
C.set_audio_buffers(AUDIO_BUFFERS)
C.set_audio_buffer_words(AUDIO_BUFFER_WORDS)
C.start_audio

loop do
  C.start_debug_measure

  signals[PITCH] = C.get_midi_note_on_pitch(MIDI_CH).to_f * (1.0 / 120.0) - 0.5
  signals[GATE] = C.get_midi_note_on_state(MIDI_CH).to_f

  signals[OSCILLATOR_WAVEFORM_TARGET] = (((value = C::get_midi_cc_value(MIDI_CH, 20)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)
  signals[FILTER_CUTOFF_TARGET] = (C::get_midi_cc_value(MIDI_CH, 74).to_f - 4.0) * (1.0 / 120.0)
  signals[FILTER_RESONANCE_TARGET] = (((value = C::get_midi_cc_value(MIDI_CH, 71)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)
  signals[FILTER_ENV_GEN_MOD_AMOUNT_TARGET] = (((value = C::get_midi_cc_value(MIDI_CH, 24)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)
  signals[AMP_GAIN_TARGET] = ((value = C.get_midi_cc_value(MIDI_CH, 15)).to_f * value.to_f) * (1.0 / (127.0 * 127.0))
  signals[ENV_GEN_ATTACK_TARGET] = (((value = C::get_midi_cc_value(MIDI_CH, 73)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)
  signals[ENV_GEN_DECAY_TARGET] = (((value = C::get_midi_cc_value(MIDI_CH, 75)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)
  signals[ENV_GEN_SUSTAIN_TARGET] = (((value = C::get_midi_cc_value(MIDI_CH, 30)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0)

  AUDIO_BUFFER_WORDS.times do |i|
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

    audio_buffer[i] = signals[AMP_OUTPUT]
  end

  C.stop_debug_measure

  AUDIO_BUFFER_WORDS.times do |i|
    C.write_to_audio_buffer(audio_buffer[i], audio_buffer[i])
  end
end
