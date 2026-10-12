# The MIDI side of Spms1::C for the CRuby hosts (spms1_sim.rb and spms1_render.rb): the MIDI
# tables spms1_main.rb reads and the handlers that fill them, as spms1_midi_state.h has them for
# the sketch and the C hosts. Each host adds the audio side.
module Spms1
  module C
    @note_on_pitch = Array.new(16, 60)
    @note_on_state = Array.new(16, 0)
    @pitch_bend    = Array.new(16, 0)
    @cc_values     = Array.new(16) { Array.new(128, 0) }
    @nrpn_values   = Array.new(16) { Array.new(512, 0) }
    @nrpn_msb      = Array.new(16, 0)
    @nrpn_lsb      = Array.new(16, 0)
    @nrpn_selected = Array.new(16, false)

    @sample_rate = 48000
    @audio_buffers = 2
    @audio_buffer_words = 64

    @parse_status = 0
    @parse_data = []
    @parse_in_sysex = false

    class << self
      # spms1_main.rb declares the functions the sketch provides. They are all defined by the host
      # already, so a declaration only checks that nothing it needs is missing.
      def ffi_func(name, _args, _ret)
        raise NotImplementedError, "Spms1::C.#{name} is not simulated" unless respond_to?(name)
      end

      def set_midi_note_on_pitch(ch, v) = (@note_on_pitch[ch] = v)
      def get_midi_note_on_pitch(ch) = @note_on_pitch[ch]
      def set_midi_note_on_state(ch, v) = (@note_on_state[ch] = v)
      def get_midi_note_on_state(ch) = @note_on_state[ch]
      def set_midi_pitch_bend(ch, v) = (@pitch_bend[ch] = v)
      def get_midi_pitch_bend(ch) = @pitch_bend[ch]
      def set_midi_cc_value(ch, n, v) = (@cc_values[ch][n] = v)
      def get_midi_cc_value(ch, n) = @cc_values[ch][n]
      def set_midi_nrpn_value(ch, i, v) = (@nrpn_values[ch][i] = v if i >= 0 && i < 512)
      def get_midi_nrpn_value(ch, i) = ((i >= 0 && i < 512) ? @nrpn_values[ch][i] : 0)
      def set_sample_rate(v) = (@sample_rate = v)
      def get_sample_rate = @sample_rate
      def set_audio_buffers(v) = (@audio_buffers = v)
      def get_audio_buffers = @audio_buffers
      def set_audio_buffer_words(v) = (@audio_buffer_words = v)
      def get_audio_buffer_words = @audio_buffer_words

      # The handlers of spms1_type2.ino, as the MIDI library calls them: a note-on of velocity 0
      # is a note-off.
      def handle_midi_message(status, d1, d2)
        ch = status & 0x0F
        case status & 0xF0
        when 0x80
          @note_on_state[ch] = 0 if d1 == @note_on_pitch[ch]
        when 0x90
          if d2 == 0
            @note_on_state[ch] = 0 if d1 == @note_on_pitch[ch]
          else
            @note_on_pitch[ch] = d1
            @note_on_state[ch] = 1
          end
        when 0xB0
          @cc_values[ch][d1] = d2
          handle_midi_nrpn_cc(ch, d1, d2)
        when 0xE0
          @pitch_bend[ch] = ((d2 << 7) | d1) - 8192
        end
      end

      def handle_midi_nrpn_cc(ch, number, value)
        if number == 99
          @nrpn_msb[ch] = value
          @nrpn_selected[ch] = true
        elsif number == 98
          @nrpn_lsb[ch] = value
          @nrpn_selected[ch] = true
        elsif number == 101 || number == 100
          @nrpn_selected[ch] = false
        elsif number == 6 && @nrpn_selected[ch]
          set_midi_nrpn_value(ch, (@nrpn_msb[ch] << 7) | @nrpn_lsb[ch], value)
        end
      end

      # A byte stream: running status is resolved here, several messages may come in a row, and
      # real-time bytes may arrive anywhere and are skipped, and so is SysEx.
      def parse_midi_byte(byte)
        if byte >= 0xF8
          nil
        elsif byte == 0xF0
          @parse_in_sysex = true
        elsif byte >= 0x80
          @parse_in_sysex = false
          @parse_status = (byte < 0xF0) ? byte : 0
          @parse_data.clear
        elsif !@parse_in_sysex && @parse_status != 0
          @parse_data << byte
          length = (@parse_status & 0xE0) == 0xC0 ? 1 : 2
          return if @parse_data.size < length
          handle_midi_message(@parse_status, @parse_data[0], @parse_data[1] || 0)
          @parse_data.clear
        end
      end
    end
  end
end
