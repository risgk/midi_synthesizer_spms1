require_relative 'spms_1_oscillator'
require_relative 'spms_1_filter'
require_relative 'spms_1_amp'
require_relative 'spms_1_env_gen'

module Spms1
  module C
    ffi_func :get_sample_rate,        [],                 :int32
    ffi_func :get_audio_buffer_words, [],                 :int32
    ffi_func :get_midi_note_on_pitch, [],                 :uint8
    ffi_func :get_midi_note_on_state, [],                 :uint8
    ffi_func :get_midi_cc_value,      [:uint8],           :uint8
    ffi_func :audio_out_write,        [:float, :float],   :void
    ffi_func :debug_measure_begin,    [],                 :void
    ffi_func :debug_measure_end,      [],                 :void
  end
end

SAMPLE_RATE = Spms1::C.get_sample_rate.to_f
BUFFER_WORDS = Spms1::C.get_audio_buffer_words

oscillator = Spms1::Oscillator.new
oscillator.set_sample_rate(SAMPLE_RATE)

filter = Spms1::Filter.new
filter.set_sample_rate(SAMPLE_RATE)

env_gen = Spms1::EnvGen.new
env_gen.set_sample_rate(SAMPLE_RATE)

amp = Spms1::Amp.new
amp.set_sample_rate(SAMPLE_RATE)

audio_buffer = Array.new(BUFFER_WORDS, 0.0)

loop do
  Spms1::C.debug_measure_begin

  pitch = Spms1::C.get_midi_note_on_pitch.to_f * (1.0 / 120.0) - 0.5
  gate = Spms1::C.get_midi_note_on_state.to_f
  
  oscillator.set_waveform(C::get_midi_cc_value(20).to_f * (1.0 / 127.0))
  filter.set_cutoff(C::get_midi_cc_value(74).to_f * (1.0 / 127.0))
  filter.set_resonance(C::get_midi_cc_value(71).to_f * (1.0 / 127.0))
  filter.set_modulation_amount(C::get_midi_cc_value(24).to_f * (1.0 / 127.0))
  env_gen.set_attack(C::get_midi_cc_value(73).to_f * (1.0 / 127.0))
  env_gen.set_decay(C::get_midi_cc_value(75).to_f * (1.0 / 127.0))
  env_gen.set_sustain((((value = C::get_midi_cc_value(30)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))

  BUFFER_WORDS.times do |i|
    env_gen_output = env_gen.process(gate)
    oscillator_output = oscillator.process(pitch)
    filter_output = filter.process(oscillator_output, env_gen_output)
    amp_output = amp.process(filter_output, env_gen_output)

    audio_buffer[i] = amp_output
  end

  Spms1::C.debug_measure_end

  BUFFER_WORDS.times do |i|
    Spms1::C.audio_out_write(audio_buffer[i], audio_buffer[i])
  end
end
