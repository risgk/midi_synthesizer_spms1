require_relative 'spms1_oscillator'
require_relative 'spms1_filter'
require_relative 'spms1_amp'
require_relative 'spms1_env_gen'

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
    ffi_func :debug_measure_begin,    [],                       :void
    ffi_func :debug_measure_end,      [],                       :void
  end
end

MIDI_CH            = 0
SAMPLE_RATE        = 96000
AUDIO_BUFFERS      = 2
AUDIO_BUFFER_WORDS = 64

oscillator = Spms1::Oscillator.new(SAMPLE_RATE)
filter = Spms1::Filter.new(SAMPLE_RATE)
amp = Spms1::Amp.new(SAMPLE_RATE)
env_gen = Spms1::EnvGen.new(SAMPLE_RATE)

audio_buffer = Array.new(AUDIO_BUFFER_WORDS, 0.0)

Spms1::C.set_midi_cc_value(MIDI_CH, 20 , 0  ) # Oscillator Waveform
Spms1::C.set_midi_cc_value(MIDI_CH, 74 , 127) # Filter Cutoff
Spms1::C.set_midi_cc_value(MIDI_CH, 71 , 64 ) # Filter Resonance
Spms1::C.set_midi_cc_value(MIDI_CH, 24 , 64 ) # Filter EG Amt
Spms1::C.set_midi_cc_value(MIDI_CH, 15 , 100) # Amp Gain
Spms1::C.set_midi_cc_value(MIDI_CH, 73 , 0  ) # EG Attack
Spms1::C.set_midi_cc_value(MIDI_CH, 75 , 96 ) # EG Decay/Release
Spms1::C.set_midi_cc_value(MIDI_CH, 30 , 0  ) # EG Sustain

Spms1::C.set_sample_rate(SAMPLE_RATE)
Spms1::C.set_audio_buffers(AUDIO_BUFFERS)
Spms1::C.set_audio_buffer_words(AUDIO_BUFFER_WORDS)
Spms1::C.start_audio

loop do
  Spms1::C.debug_measure_begin

  pitch = Spms1::C.get_midi_note_on_pitch(MIDI_CH).to_f * (1.0 / 120.0) - 0.5
  gate = Spms1::C.get_midi_note_on_state(MIDI_CH).to_f

  oscillator.set_waveform((((value = Spms1::C::get_midi_cc_value(MIDI_CH, 20)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))
  filter.set_cutoff((Spms1::C::get_midi_cc_value(MIDI_CH, 74).to_f - 4.0) * (1.0 / 120.0))
  filter.set_resonance((((value = Spms1::C::get_midi_cc_value(MIDI_CH, 71)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))
  filter.set_modulation_amount((((value = Spms1::C::get_midi_cc_value(MIDI_CH, 24)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))
  amp.set_gain(((value = Spms1::C.get_midi_cc_value(MIDI_CH, 15)).to_f * value.to_f) * (1.0 / (127.0 * 127.0)))
  env_gen.set_attack((((value = Spms1::C::get_midi_cc_value(MIDI_CH, 73)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))
  env_gen.set_decay((((value = Spms1::C::get_midi_cc_value(MIDI_CH, 75)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))
  env_gen.set_sustain((((value = Spms1::C::get_midi_cc_value(MIDI_CH, 30)) == 127) ? 128.0 : value.to_f) * (1.0 / 128.0))

  AUDIO_BUFFER_WORDS.times do |i|
    env_gen_output = env_gen.process(gate)
    oscillator_output = oscillator.process(pitch)
    filter_output = filter.process(oscillator_output, env_gen_output)
    amp_output = amp.process(filter_output, env_gen_output)

    audio_buffer[i] = amp_output
  end

  Spms1::C.debug_measure_end

  AUDIO_BUFFER_WORDS.times do |i|
    Spms1::C.write_to_audio_buffer(audio_buffer[i], audio_buffer[i])
  end
end
