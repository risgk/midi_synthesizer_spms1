# Runs spms1_main.rb unmodified on CRuby, offline, and writes what it puts out to a WAV file: the
# CRuby counterpart of sim_render/spms1_render.c, taking the same options and the same patch and
# score files, and timing them the same way. CRuby computes in double where Spinel's output computes
# in float, so the two renders are close rather than equal; spms1_compare.rb says how close.
#
#   ruby sim_cruby/spms1_render.rb [--patch FILE] [--score FILE] [--seconds N] [--out FILE]
#
# Needs no gems.
require 'optparse'
require_relative 'spms1_c_midi'

options = { patch: nil, score: nil, seconds: 4.0, out: 'spms1_render_cruby.wav' }
OptionParser.new do |o|
  o.on('--patch FILE', 'a patch copied from the editor as MIDI bytes (hex)') { |v| options[:patch] = v }
  o.on('--score FILE', 'the MIDI to play: the time in seconds and the bytes in hex, a line each') { |v| options[:score] = v }
  o.on('--seconds N', Float, 'the length of the render (default 4)') { |v| options[:seconds] = v }
  o.on('--out FILE', 'the WAV file (default spms1_render_cruby.wav)') { |v| options[:out] = v }
end.parse!

# Hex bytes up to the end of the line or a ';'.
def parse_hex_bytes(text)
  text.split(';', 2).first.to_s.split(/[\s,]+/).reject(&:empty?).map do |b|
    raise "Not a hex byte: #{b}" unless b =~ /\A\h{1,2}\z/
    b.to_i(16)
  end
end

patch = options[:patch] ? File.readlines(options[:patch]).flat_map { |line| parse_hex_bytes(line) } : []

# [frame, bytes], in time order and, at the same time, in the order of the file.
events =
  if options[:score]
    File.readlines(options[:score]).each_with_index.filter_map do |line, i|
      line = line.split(';', 2).first.to_s.strip
      next if line.empty?
      time, rest = line.split(/\s+/, 2)
      seconds = Float(time, exception: false)
      raise "A line of the score must start with the time in seconds: #{line}" unless seconds && seconds >= 0.0
      [(seconds * 48000.0).round, i, parse_hex_bytes(rest.to_s)]
    end.sort_by { |frame, i, _| [frame, i] }.map { |frame, _, bytes| [frame, bytes] }
  else
    [[0, [0x90, 60, 100]], [48000, [0x80, 60, 64]]]
  end

module Spms1
  module C
    class << self
      attr_accessor :patch, :events, :total_frames, :out_path

      def stop_audio; end
      def start_debug_measure; end
      def stop_debug_measure; end

      # Called once the synth has written its default patch and its default CC values, so the
      # patch given here replaces them, as one sent from the editor after power-up does.
      def start_audio
        @patch.each { |b| parse_midi_byte(b) }
        @next_event = 0
        @frames = 0
        @pcm = String.new(capacity: @total_frames * 6, encoding: Encoding::BINARY)
        @peak = [0.0, 0.0]
      end

      # The score's messages arrive as the frame they are timed at goes out, so the synth takes
      # them at its next buffer, as it takes MIDI on the device.
      def write_to_audio_buffer(l, r)
        while @next_event < @events.size && @events[@next_event][0] <= @frames
          @events[@next_event][1].each { |b| parse_midi_byte(b) }
          @next_event += 1
        end

        write_sample(l, 0)
        write_sample(r, 1)
        @frames += 1
        finish if @frames >= @total_frames
      end

      private

      def write_sample(v, channel)
        @peak[channel] = v.abs if v.abs > @peak[channel]
        s = (v * 8388607.0).round.clamp(-8388608, 8388607)
        @pcm << [s & 0xFF, (s >> 8) & 0xFF, (s >> 16) & 0xFF].pack('C3')
      end

      def finish
        rate = @sample_rate
        header = ['RIFF', 36 + @pcm.bytesize, 'WAVE', 'fmt ', 16, 1, 2, rate, rate * 6, 6, 24,
                  'data', @pcm.bytesize].pack('a4Va4a4VvvVVvva4V')
        File.binwrite(@out_path, header + @pcm)
        db = ->(v) { v > 0.0 ? format('%.1f', 20.0 * Math.log10(v)) : '-inf' }
        puts "#{@out_path}: #{format('%.3f', @frames.to_f / rate)} s, peak L #{db.(@peak[0])} dBFS, R #{db.(@peak[1])} dBFS"
        exit 0
      end
    end
  end
end

Spms1::C.patch = patch
Spms1::C.events = events
Spms1::C.total_frames = [(options[:seconds] * 48000.0).round, 1].max
Spms1::C.out_path = options[:out]
load File.join(__dir__, '..', 'spms1_main.rb')
