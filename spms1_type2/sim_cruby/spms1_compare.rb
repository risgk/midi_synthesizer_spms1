# Compares two WAV files from the renderers (sim_render/spms1_render.c and sim_cruby/spms1_render.rb),
# sample by sample: CRuby runs spms1_main.rb itself, so where the two part, Spinel's output does
# not do what the Ruby says (or float and double have drifted apart).
#
#   ruby sim_cruby/spms1_compare.rb A.wav B.wav [--limit DB]
#
# The test compares short-time spectra, magnitudes only: frames of 1024 samples (21 ms) under a
# Hann window, every 512, on each side. The float of Spinel's output and the double of CRuby let
# the oscillator's phase drift apart, a little more every second, which moves each edge of a
# sawtooth or a square by a growing fraction of a sample. Sample by sample, that difference grows
# without bound -- up to -8 dBFS after 3 s of a bare sawtooth -- though it is precision, not a
# different synth; the magnitudes hardly see it. The difference of the magnitudes is put on the
# same scale as a signal (the RMS a waveform with that spectrum would have), and taken relative to
# the louder of the two frames, or to -60 dBFS where both are quieter, so that a quiet passage
# counts as much as a loud one and a near silence does not count at all. At the frame where it is
# largest, precision stays below about -35 dB, a bare sawtooth at full scale for 3 s included; a
# routing or a module that does something else lands above -10 dB, and so does a CC value 4 steps
# away from the other (the cutoff, or the decay heard in the release).
#
# The chorus is the exception, as it turns a drift of its LFO's phase into one of the delay it
# swings, ±126 samples at the default depth, and then mixes the delayed sound with the dry: a
# phase 0.0003 of a cycle apart after 6 s, a delay 0.2 of a sample apart, moves the notches the mix
# makes among the high harmonics. A high note under the chorus, played some seconds into a render,
# can so pass -25 dB from precision alone: C7 at 6 s gives about -21 dB, and -36 dB with the
# chorus's Mix or Depth at 0. Keep a render that has to pass to about 4 s, as the default score is,
# or take the chorus out of it.
#
# Prints that, and the largest single difference and the RMS over the whole file sample by sample,
# for information. Exits with 1 if the spectral difference is above --limit (default -25 dB) or
# the lengths differ.
require 'optparse'

FRAME = 1024
HOP = 512

FLOOR = 10.0**(-60.0 / 20.0)

limit = -25.0
OptionParser.new do |o|
  o.on('--limit DB', Float, 'the largest spectral difference allowed, relative to the signal (default -25)') { |v| limit = v }
end.parse!
abort 'usage: ruby sim_cruby/spms1_compare.rb A.wav B.wav [--limit DB]' unless ARGV.size == 2

# The samples of a 24-bit stereo WAV, as the renderers write it, interleaved, in full scale units.
def read_wav(path)
  data = File.binread(path)
  abort "#{path}: not a 24-bit stereo WAV" unless data[0, 4] == 'RIFF' && data[8, 4] == 'WAVE' &&
                                                  data[22, 2].unpack1('v') == 2 && data[34, 2].unpack1('v') == 24
  pcm = data[44, data[40, 4].unpack1('V')]
  pcm.unpack('C*').each_slice(3).map do |b0, b1, b2|
    s = b0 | (b1 << 8) | (b2 << 16)
    s -= 0x1000000 if s >= 0x800000
    s / 8388607.0
  end
end

def dbfs(v) = v > 0.0 ? 20.0 * Math.log10(v) : -Float::INFINITY

# In-place radix-2 FFT of re and im (the size a power of 2).
def fft!(re, im)
  n = re.size
  j = 0
  (1...n).each do |i|
    bit = n >> 1
    while j & bit != 0
      j ^= bit
      bit >>= 1
    end
    j |= bit
    if i < j
      re[i], re[j] = re[j], re[i]
      im[i], im[j] = im[j], im[i]
    end
  end
  len = 2
  while len <= n
    angle = -2.0 * Math::PI / len
    wr = Math.cos(angle)
    wi = Math.sin(angle)
    (0...n).step(len) do |start|
      cr = 1.0
      ci = 0.0
      (0...(len / 2)).each do |k|
        a = start + k
        b = a + len / 2
        tr = re[b] * cr - im[b] * ci
        ti = re[b] * ci + im[b] * cr
        re[b] = re[a] - tr
        im[b] = im[a] - ti
        re[a] += tr
        im[a] += ti
        cr, ci = cr * wr - ci * wi, cr * wi + ci * wr
      end
    end
    len *= 2
  end
end

HANN = Array.new(FRAME) { |i| 0.5 - 0.5 * Math.cos(2.0 * Math::PI * i / FRAME) }
HANN_POWER = HANN.sum { |w| w * w }

def magnitudes(samples, channel, start)
  re = Array.new(FRAME) { |i| (samples[(start + i) * 2 + channel] || 0.0) * HANN[i] }
  im = Array.new(FRAME, 0.0)
  fft!(re, im)
  Array.new(FRAME) { |k| Math.sqrt(re[k] * re[k] + im[k] * im[k]) }
end

a = read_wav(ARGV[0])
b = read_wav(ARGV[1])
if a.size != b.size
  puts "The lengths differ: #{a.size / 2} and #{b.size / 2} frames"
  exit 1
end

max_diff = 0.0
sum_sq = 0.0
a.each_index do |i|
  d = (a[i] - b[i]).abs
  sum_sq += d * d
  max_diff = d if d > max_diff
end
rms = Math.sqrt(sum_sq / a.size)

# By Parseval, sum |X[k]|^2 = FRAME * sum (x[i] w[i])^2, so the RMS of a waveform with the spectrum
# of the difference is sqrt(sum |dX|^2 / (FRAME * HANN_POWER)).
frames = a.size / 2
spectral_max = 0.0
spectral_at = 0
(0..[frames - FRAME, 0].max).step(HOP) do |start|
  2.times do |channel|
    ma = magnitudes(a, channel, start)
    mb = magnitudes(b, channel, start)
    power = 0.0
    power_a = 0.0
    power_b = 0.0
    FRAME.times do |k|
      power += (ma[k] - mb[k])**2
      power_a += ma[k]**2
      power_b += mb[k]**2
    end
    level = Math.sqrt([power_a, power_b].max / (FRAME * HANN_POWER))
    diff = Math.sqrt(power / (FRAME * HANN_POWER)) / [level, FLOOR].max
    if diff > spectral_max
      spectral_max = diff
      spectral_at = start
    end
  end
end

ok = dbfs(spectral_max) <= limit
printf("Difference: spectral %.1f dB to the signal at its largest (%.2f s); sample by sample %.1f dBFS at most, " \
       "%.1f dBFS RMS; peaks %.1f and %.1f dBFS: %s\n",
       dbfs(spectral_max), spectral_at / 48000.0, dbfs(max_diff), dbfs(rms),
       dbfs(a.map(&:abs).max), dbfs(b.map(&:abs).max), ok ? 'OK' : "above #{limit} dB")
exit(ok ? 0 : 1)
