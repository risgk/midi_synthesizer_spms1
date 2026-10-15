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
    # as value += (target - value) * blend, and lands on the target exactly once it is within 1e-20
    # of it. Without that a stage heading for 0.0 would sink into the denormals and stay there, at
    # about 4e-44, where the step rounds to nothing -- and Mixer Level, Amp Gain, Delay and Chorus
    # Mix and the like multiply the audio by their stage every sample. Away from zero the test
    # never passes before the step has rounded to nothing, so every other value is what it was.
    def self.smooth(target, value, blend)
      distance = target - value
      (distance.abs < 1e-20) ? target : value + distance * blend
    end
  end
end
