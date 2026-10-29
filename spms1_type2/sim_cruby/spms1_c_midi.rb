# The MIDI side of Spms1::C for the CRuby hosts (spms1_sim.rb and spms1_render.rb): the MIDI
# tables spms1_main.rb reads and the handlers that fill them, as spms1_midi_state.h has them for
# the sketch and the C hosts, and the signal bus, as spms1_bus.h has it. Each host adds the audio
# side.
require 'yaml'

module Spms1
  module C
    @note_on_pitch = Array.new(16, 60)
    @note_on_state = Array.new(16, 0)
    @note_prev_pitch = Array.new(16, nil)  # the note that comes back on a note off, or nil
    @pitch_bend    = Array.new(16, 0)
    @cc_values     = Array.new(16) { Array.new(128, 0) }
    @nrpn_values   = Array.new(16) { Array.new(640, 0) }
    @nrpn_msb      = Array.new(16, 0)
    @nrpn_lsb      = Array.new(16, 0)
    @nrpn_selected = Array.new(16, false)
    # When each slot of the run order was last written, as in spms1_midi_state.h.
    @run_order_writes  = Array.new(16, 0)
    @run_order_written = Array.new(16) { Array.new(32, 0) }
    # Mute (NRPN 117/0), as in spms1_midi_state.h.
    @mute = Array.new(16, 0)
    @mute_count = Array.new(16, 0)
    # Save (NRPN 117/2) and Load (117/3), as in spms1_midi_state.h, with the patch kept in RAM: the
    # patch made as Save arrives, and the one written when the synth stores it, as [NRPN table, CC
    # values, run order ranks], or nil.
    @save_count = Array.new(16, 0)
    # The controls whose CCs' values a Save keeps, by entry: all but the performance controls', as
    # g_spms1_saved_cc_entries in spms1_default_patch.h has them.
    @saved_cc_entries = YAML.load_file(File.expand_path('../spms1_patch.yaml', __dir__))
                            .fetch('controls').reject { |c| c['performance'] }.map { |c| c['entry'] }
    @patch_image = nil
    @stored_image = nil

    # The signal bus SignalBus reads and writes, as spms1_bus.h has it for the C builds.
    @bus_signals = Array.new(512, 0.0)
    @active_modules = Array.new(32, 0)

    @sample_rate = 48000
    @audio_buffers = 2
    @audio_buffer_words = 64

    @parse_status = 0
    @parse_data = []
    @parse_sysex = nil  # the SysEx being kept until its F7, or nil

    # SPMS1_PATCH_SPEC_HASH, which a SysEx carries, as spms1_default_patch.h has it.
    @patch_spec_hash = Integer(File.read(File.expand_path('../spms1/spms1_default_patch.h', __dir__))[/#define SPMS1_PATCH_SPEC_HASH \((0x\h+)u\)/, 1])

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
      def set_midi_nrpn_value(ch, i, v)
        return unless i >= 0 && i < 640
        @nrpn_values[ch][i] = v
        @run_order_written[ch][i] = (@run_order_writes[ch] += 1) if i < 32
      end
      def get_midi_run_order_written(ch, slot) = ((slot >= 0 && slot < 32) ? @run_order_written[ch][slot] : 0)
      def get_midi_nrpn_value(ch, i) = ((i >= 0 && i < 640) ? @nrpn_values[ch][i] : 0)
      def get_midi_mute(ch) = @mute[ch]
      def get_midi_mute_count(ch) = @mute_count[ch]
      def get_midi_save_count(ch) = @save_count[ch]
      def store_patch_image(_ch) = (@stored_image = @patch_image)

      # The patch as spms1_make_patch_image takes it: the CC values of the controls but the
      # performance ones, and each run order slot's time as a rank, 1 the first written, 0 never.
      def make_patch_image(ch)
        written = @run_order_written[ch]
        ranks = written.map { |w| w == 0 ? 0 : written.count { |o| o != 0 && o <= w } }
        cc = Array.new(128, 0)
        @saved_cc_entries.each do |entry|
          number = @nrpn_values[ch][384 + entry]
          cc[number] = @cc_values[ch][number] if number > 0 && number < 128
        end
        @patch_image = [@nrpn_values[ch].dup, cc, ranks]
      end

      # As spms1_apply_patch_image, over the default patch.
      def load_saved_patch(ch)
        return unless @stored_image
        nrpn, cc, ranks = @stored_image
        reset_patch(ch)
        @nrpn_values[ch] = nrpn.dup
        @cc_values[ch] = cc.dup
        @run_order_writes[ch] = 0
        @run_order_written[ch].fill(0)
        (1..32).each { |rank| 32.times { |slot| set_midi_nrpn_value(ch, slot, nrpn[slot]) if ranks[slot] == rank } }
      end

      # The reset NRPN, as spms1_reset_patch: every entry, the times the run order was written and
      # every CC to 0, then the default patch, written as at power-up by spms1_patch.rb.
      def reset_patch(ch)
        @nrpn_values[ch].fill(0)
        @run_order_writes[ch] = 0
        @run_order_written[ch].fill(0)
        @cc_values[ch].fill(0)
        spms1_write_default_patch(ch)
      end
      def get_bus_signal(slot) = @bus_signals[slot & 511]
      def set_bus_signal(slot, v) = (@bus_signals[slot & 511] = v)
      def get_active_module(slot) = @active_modules[slot & 31]
      def set_active_module(slot, v) = (@active_modules[slot & 31] = v)
      def set_sample_rate(v) = (@sample_rate = v)
      def get_sample_rate = @sample_rate
      def set_audio_buffers(v) = (@audio_buffers = v)
      def get_audio_buffers = @audio_buffers
      def set_audio_buffer_words(v) = (@audio_buffer_words = v)
      def get_audio_buffer_words = @audio_buffer_words

      # The handlers of spms1_midi_state.h, as the MIDI library calls them: a note-on of velocity 0
      # is a note-off.
      def handle_midi_message(status, d1, d2)
        ch = status & 0x0F
        case status & 0xF0
        when 0x80
          handle_note_off(ch, d1)
        when 0x90
          if d2 == 0
            handle_note_off(ch, d1)
          else
            if @note_on_state[ch] == 0
              @note_prev_pitch[ch] = nil
            elsif d1 != @note_on_pitch[ch]
              @note_prev_pitch[ch] = @note_on_pitch[ch]
            end
            @note_on_pitch[ch] = d1
            @note_on_state[ch] = 1
          end
        when 0xB0
          if d1 >= 120
            handle_channel_mode(ch, d1)
          else
            @cc_values[ch][d1] = d2
            handle_midi_nrpn_cc(ch, d1, d2)
          end
        when 0xE0
          @pitch_bend[ch] = ((d2 << 7) | d1) - 8192
        end
      end

      # The note sounding gives way to the one remembered, with the gate left open, or closes the
      # gate; the remembered note is only forgotten.
      def handle_note_off(ch, pitch)
        if pitch == @note_on_pitch[ch]
          if @note_prev_pitch[ch]
            @note_on_pitch[ch] = @note_prev_pitch[ch]
            @note_prev_pitch[ch] = nil
          else
            @note_on_state[ch] = 0
          end
        elsif pitch == @note_prev_pitch[ch]
          @note_prev_pitch[ch] = nil
        end
      end

      # The Channel Mode messages, as spms1_midi_state.h takes them: Reset All Controllers (121)
      # centers the bend, sets CC 1 to 0 and leaves no NRPN selected; Local Control (122) does
      # nothing; the rest end every note.
      def handle_channel_mode(ch, number)
        if number == 121
          @pitch_bend[ch] = 0
          @cc_values[ch][1] = 0
          @nrpn_selected[ch] = false
        elsif number != 122
          @note_prev_pitch[ch] = nil
          @note_on_state[ch] = 0
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
        elsif number == 6 && @nrpn_selected[ch] && @nrpn_msb[ch] == 117
          # The system entries: Mute (0), Reset (1), Save (2) and Load (3).
          if @nrpn_lsb[ch] == 0
            @mute[ch] = (value >= 64) ? 1 : 0
            @mute_count[ch] += 1 if value >= 64
          elsif @nrpn_lsb[ch] == 1 && value >= 64
            reset_patch(ch)
          elsif @nrpn_lsb[ch] == 2 && value >= 64 && @mute[ch] != 0
            make_patch_image(ch)
            @save_count[ch] += 1
          elsif @nrpn_lsb[ch] == 3 && value >= 64 && @mute[ch] != 0
            load_saved_patch(ch)
          end
        elsif number == 6 && @nrpn_selected[ch] && @nrpn_msb[ch] >= 112
          set_midi_nrpn_value(ch, ((@nrpn_msb[ch] - 112) << 7) | @nrpn_lsb[ch], value)
        end
      end

      # A SysEx of NRPN values, as spms1_handle_sysex: F0 7D 53 31, the channel, 01, the spec
      # hash in five bytes, the category, the first entry, the values and F7, whole or not at all.
      def handle_sysex(data)
        return unless data.size >= 14 && data[0] == 0xF0 && data[-1] == 0xF7 && data[1, 3] == [0x7D, 0x53, 0x31]
        ch, cmd = data[4], data[5]
        hash = (0...5).sum { |i| data[6 + i] << (7 * i) }
        category, entry = data[11], data[12]
        values = data[13...-1]
        return unless ch < 16 && cmd == 1 && hash == @patch_spec_hash && category < 5 &&
                      entry + values.size <= 128 && values.all? { |v| v < 0x80 }
        values.each_with_index { |v, i| set_midi_nrpn_value(ch, (category << 7) + entry + i, v) }
      end

      # A byte stream: running status is resolved here, several messages may come in a row, and
      # real-time bytes may arrive anywhere and are skipped. A SysEx is kept until its F7, and one
      # longer than 128 bytes is skipped, as in spms1_midi_parse_byte.
      def parse_midi_byte(byte)
        if byte >= 0xF8
          nil
        elsif byte == 0xF7 && @parse_sysex
          @parse_sysex << byte
          handle_sysex(@parse_sysex) if @parse_sysex.size <= 128
          @parse_sysex = nil
        elsif byte >= 0x80
          @parse_sysex = (byte == 0xF0) ? [byte] : nil
          @parse_status = (byte < 0xF0) ? byte : 0
          @parse_data.clear
        elsif @parse_sysex
          @parse_sysex << byte
        elsif @parse_status != 0
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
