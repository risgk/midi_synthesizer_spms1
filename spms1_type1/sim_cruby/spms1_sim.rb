# Runs spms1_main.rb unmodified on CRuby, standing in for the sketch: Spms1::C is implemented here
# in Ruby, audio goes out through PortAudio and MIDI comes in through unimidi.
#
#   ruby sim_cruby/spms1_sim.rb [--midi-in N|NAME] [--frames 256] [--host wasapi|mme|ds]
#
# Needs the ffi and unimidi gems and a PortAudio DLL; SPMS1_PORTAUDIO_DLL overrides where it is
# looked for.
require 'ffi'
require 'unimidi'
require 'optparse'

options = { midi_in: nil, frames: 256, host: 'wasapi' }
OptionParser.new do |o|
  o.on('--midi-in N', 'MIDI input: index or part of its name') { |v| options[:midi_in] = v }
  o.on('--frames N', Integer, 'frames per PortAudio write') { |v| options[:frames] = v }
  o.on('--host NAME', 'wasapi, mme or ds') { |v| options[:host] = v.downcase }
end.parse!

module PortAudio
  extend FFI::Library
  ffi_lib [ENV['SPMS1_PORTAUDIO_DLL'], 'portaudio', 'libportaudio', 'libportaudio-2',
           'C:/Program Files/Audacity/portaudio_x64.dll'].compact

  PA_FLOAT32 = 0x00000001
  PA_CLIP_OFF = 0x00000001
  PA_OUTPUT_UNDERFLOWED = -9980
  HOST_API_TYPES = { 'mme' => 2, 'ds' => 1, 'wasapi' => 13 }

  class HostApiInfo < FFI::Struct
    layout :struct_version, :int, :type, :int, :name, :string, :device_count, :int,
           :default_input_device, :int, :default_output_device, :int
  end

  class DeviceInfo < FFI::Struct
    layout :struct_version, :int, :name, :string, :host_api, :int,
           :max_input_channels, :int, :max_output_channels, :int,
           :default_low_input_latency, :double, :default_low_output_latency, :double,
           :default_high_input_latency, :double, :default_high_output_latency, :double,
           :default_sample_rate, :double
  end

  class StreamParameters < FFI::Struct
    layout :device, :int, :channel_count, :int, :sample_format, :ulong,
           :suggested_latency, :double, :host_api_specific_stream_info, :pointer
  end

  attach_function :Pa_Initialize, [], :int
  attach_function :Pa_Terminate, [], :int
  attach_function :Pa_GetErrorText, [:int], :string
  attach_function :Pa_GetVersionText, [], :string
  attach_function :Pa_GetDefaultOutputDevice, [], :int
  attach_function :Pa_HostApiTypeIdToHostApiIndex, [:int], :int
  attach_function :Pa_GetHostApiInfo, [:int], HostApiInfo.by_ref
  attach_function :Pa_GetDeviceInfo, [:int], DeviceInfo.by_ref
  attach_function :Pa_OpenStream, [:pointer, :pointer, StreamParameters.by_ref, :double, :ulong,
                                   :ulong, :pointer, :pointer], :int
  attach_function :Pa_StartStream, [:pointer], :int
  attach_function :Pa_StopStream, [:pointer], :int
  attach_function :Pa_CloseStream, [:pointer], :int
  # Blocking, so the GVL has to be released while it waits or the MIDI thread stalls with it.
  attach_function :Pa_WriteStream, [:pointer, :buffer_in, :ulong], :int, blocking: true

  def self.check(err, what)
    raise "#{what}: #{Pa_GetErrorText(err)}" if err < 0
    err
  end
end

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

    class << self
      attr_accessor :frames, :host
      attr_reader :stream

      # spms1_main.rb declares the functions the sketch provides. They are all defined here
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

      # The handlers of spms1_type1.ino, as the MIDI library calls them: a note-on of velocity 0
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

      def start_audio
        PortAudio.check(PortAudio.Pa_Initialize, 'Pa_Initialize')
        api = PortAudio.Pa_HostApiTypeIdToHostApiIndex(PortAudio::HOST_API_TYPES.fetch(@host))
        device = (api >= 0) ? PortAudio.Pa_GetHostApiInfo(api)[:default_output_device] : -1
        device = PortAudio.Pa_GetDefaultOutputDevice if device < 0
        info = PortAudio.Pa_GetDeviceInfo(device)
        api_name = PortAudio.Pa_GetHostApiInfo(info[:host_api])[:name]

        params = PortAudio::StreamParameters.new
        params[:device] = device
        params[:channel_count] = 2
        params[:sample_format] = PortAudio::PA_FLOAT32
        params[:suggested_latency] = info[:default_low_output_latency]
        params[:host_api_specific_stream_info] = nil

        stream_ptr = FFI::MemoryPointer.new(:pointer)
        PortAudio.check(PortAudio.Pa_OpenStream(stream_ptr, nil, params, @sample_rate.to_f, @frames,
                                                PortAudio::PA_CLIP_OFF, nil, nil),
                        "Pa_OpenStream (#{api_name}, #{info[:name]})")
        @stream = stream_ptr.read_pointer
        PortAudio.check(PortAudio.Pa_StartStream(@stream), 'Pa_StartStream')
        $stderr.puts "#{PortAudio.Pa_GetVersionText}: #{api_name}, #{info[:name]}, " \
                     "#{@sample_rate} Hz, #{@frames} frames per write"

        @out = Array.new(@frames * 2, 0.0)
        @out_index = 0
        @underflows = 0
        @measure_buffers = 0
        @measure_total = 0.0
        @measure_max = 0.0
        @report_at = now + 1.0
      end

      def stop_audio
        return unless @stream
        PortAudio.Pa_StopStream(@stream)
        PortAudio.Pa_CloseStream(@stream)
        PortAudio.Pa_Terminate
        @stream = nil
      end

      def write_to_audio_buffer(l, r)
        @out[@out_index] = l
        @out[@out_index + 1] = r
        @out_index += 2
        return if @out_index < @out.size

        @out_index = 0
        err = PortAudio.Pa_WriteStream(@stream, @out.pack('e*'), @frames)
        if err == PortAudio::PA_OUTPUT_UNDERFLOWED
          @underflows += 1
        else
          PortAudio.check(err, 'Pa_WriteStream')
        end
      end

      # What main brackets is one buffer's DSP, so the load reported is that time against what one
      # buffer lasts.
      def start_debug_measure
        @measure_start = now
      end

      def stop_debug_measure
        t = now - @measure_start
        @measure_total += t
        @measure_max = t if t > @measure_max
        @measure_buffers += 1
        return if now < @report_at

        budget = @audio_buffer_words.to_f / @sample_rate
        avg = @measure_total / @measure_buffers
        $stderr.printf("\rDSP %4.0f us avg (%3.0f%%), %4.0f us max / %4.0f us, underflows %d   ",
                       avg * 1e6, avg / budget * 100.0, @measure_max * 1e6, budget * 1e6, @underflows)
        @measure_buffers = 0
        @measure_total = 0.0
        @measure_max = 0.0
        @report_at += 1.0
      end

      private

      def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end

def select_midi_input(spec)
  inputs = UniMIDI::Input.all
  if inputs.empty?
    $stderr.puts 'No MIDI input found; running without MIDI.'
    return nil
  end
  if spec.nil?
    inputs.each_with_index { |d, i| $stderr.puts "#{i}: #{d.name}" }
    $stderr.print 'MIDI input: '
    spec = $stdin.gets.to_s.strip
  end
  input = (spec =~ /\A\d+\z/) ? inputs[spec.to_i] : inputs.find { |d| d.name.include?(spec) }
  raise "No MIDI input matches #{spec.inspect}" unless input
  input
end

# unimidi hands over raw bytes, so running status is resolved here. Real-time bytes may arrive
# anywhere and are skipped, and so is SysEx.
def start_midi_thread(input)
  input.open
  $stderr.puts "MIDI in: #{input.name}"
  Thread.new do
    status = 0
    data = []
    in_sysex = false
    loop do
      input.gets.each do |message|
        message[:data].each do |byte|
          if byte >= 0xF8
            next
          elsif byte == 0xF0
            in_sysex = true
          elsif byte >= 0x80
            in_sysex = false
            status = (byte < 0xF0) ? byte : 0
            data.clear
          elsif !in_sysex && status != 0
            data << byte
            length = (status & 0xE0) == 0xC0 ? 1 : 2
            next if data.size < length
            Spms1::C.handle_midi_message(status, data[0], data[1] || 0)
            data.clear
          end
        end
      end
    end
  end
end

Spms1::C.frames = options[:frames]
Spms1::C.host = options[:host]
input = select_midi_input(options[:midi_in])
start_midi_thread(input) if input

at_exit { Spms1::C.stop_audio }
begin
  load File.join(__dir__, '..', 'spms1_main.rb')
rescue Interrupt
  $stderr.puts
end
