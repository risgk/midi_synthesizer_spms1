module Spms1
  # Arithmetic shared by the modules. Module functions rather than methods of each class, so that
  # there is one copy of each; Spinel emits them always_inline, so calling one costs nothing over
  # writing it out in place.
  module Dsp
    # A dead zone of 1e-20 about zero, so that a state decaying on a silent input lands on exactly
    # zero instead of sinking into denormals, which x86 computes slowly. It shifts every other
    # value toward zero by 1e-20, which rounds away at any audible level. Built from a + |a| as
    # Filter#clip_output is, rather than as (s + c) - c: -ffast-math may fold that one to s, while
    # this is a dead zone in exact arithmetic, so any rewrite it allows still is one. What comes
    # out is zero or at least 8e-28, the spacing of floats near 1e-20: never a denormal. Rewritten
    # under -ffast-math it rounds at that spacing and may leave a remnant of that size instead of
    # zero, still far above the denormals. A literal, as the vendored Spinel emits a Float constant
    # as a runtime global rather than a compile-time literal.
    def self.flush_tiny(state)
      above = state - 1e-20
      below = (0.0 - state) - 1e-20
      ((above + above.abs) - (below + below.abs)) * 0.5
    end

    # One stage of the control-rate parameter smoothing: value moves toward target by the blend,
    # as value += (target - value) * blend. A stage heading for 0.0 would sink into the denormals,
    # and Mixer Level, Amp Gain, Delay and Chorus Mix and the like multiply the audio by their stage
    # every sample; the floating point unit runs with flush-to-zero instead, on the device (FPSCR.FZ,
    # set in setup1 in spms1.ino, where the synth runs) and in the simulators (FTZ and DAZ), so the
    # stage reaches 0.0 itself once it falls below the smallest normal float. That leaves this
    # with no test and no branch: this is expanded 94 times and runs every fourth sample, and a
    # test that landed the stage on its target took more than the step it saved, 32 us a buffer,
    # and made the time depend on which way each one went. Away from zero the step rounds to
    # nothing long before the stage could come within such a test, so nothing else changes.
    def self.smooth(target, value, blend)
      value + (target - value) * blend
    end
  end
end
