# Generated from spms1_patch.yaml by patch_gen/spms1_patch_gen.rb. Do not edit; change the YAML
# and run the generator.

# Module ids, the values of NRPN category 0. MODULE_NONE ends the run order.
MODULE_NONE      = 0
MODULE_LFO_1     = 1
MODULE_ENV_GEN_1 = 2
MODULE_OSC_1     = 3
MODULE_FILTER_1  = 4
MODULE_AMP_1     = 5
MODULE_MIXER_1   = 6
MODULE_CHORUS_1  = 7
MODULE_DELAY_1   = 8
MODULE_SLEW_1    = 9

# Slots of the signal bus, the values of NRPN categories 1 and 2.
SIGNAL_NONE                  = 0
SIGNAL_ONE                   = 1
SIGNAL_HALF                  = 2
SIGNAL_POINT_TWO             = 3
SIGNAL_POINT_ONE             = 4
SIGNAL_MINUS_POINT_ONE       = 5
SIGNAL_MINUS_POINT_TWO       = 6
SIGNAL_MINUS_HALF            = 7
SIGNAL_MINUS_ONE             = 8
SIGNAL_LFO_1_OUTPUT          = 9
SIGNAL_ENV_GEN_1_OUTPUT      = 10
SIGNAL_OSC_1_OUTPUT          = 11
SIGNAL_FILTER_1_OUTPUT       = 12
SIGNAL_AMP_1_OUTPUT          = 13
SIGNAL_MIXER_1_OUTPUT        = 14
SIGNAL_CHORUS_1_OUTPUT_L     = 15
SIGNAL_CHORUS_1_OUTPUT_R     = 16
SIGNAL_DELAY_1_OUTPUT_L      = 17
SIGNAL_DELAY_1_OUTPUT_R      = 18
SIGNAL_LFO_1_RATE            = 19
SIGNAL_LFO_1_LEVEL           = 20
SIGNAL_LFO_1_POLARITY        = 21
SIGNAL_ENV_GEN_1_ATTACK      = 22
SIGNAL_ENV_GEN_1_DECAY       = 23
SIGNAL_ENV_GEN_1_SUSTAIN     = 24
SIGNAL_ENV_GEN_1_LEVEL       = 25
SIGNAL_ENV_GEN_1_POLARITY    = 26
SIGNAL_OSC_1_WAVEFORM        = 27
SIGNAL_OSC_1_COARSE_TUNE     = 28
SIGNAL_OSC_1_FINE_TUNE       = 29
SIGNAL_OSC_1_MOD_AMOUNT      = 30
SIGNAL_OSC_1_MOD_POLARITY    = 31
SIGNAL_FILTER_1_CUTOFF       = 32
SIGNAL_FILTER_1_RESONANCE    = 33
SIGNAL_FILTER_1_GAIN         = 34
SIGNAL_FILTER_1_MOD_AMOUNT   = 35
SIGNAL_FILTER_1_MOD_POLARITY = 36
SIGNAL_AMP_1_GAIN            = 37
SIGNAL_MIXER_1_LEVEL_1       = 38
SIGNAL_MIXER_1_POLARITY_1    = 39
SIGNAL_MIXER_1_LEVEL_2       = 40
SIGNAL_MIXER_1_POLARITY_2    = 41
SIGNAL_CHORUS_1_RATE         = 42
SIGNAL_CHORUS_1_DEPTH        = 43
SIGNAL_CHORUS_1_MIX          = 44
SIGNAL_DELAY_1_TIME          = 45
SIGNAL_DELAY_1_FEEDBACK      = 46
SIGNAL_DELAY_1_MIX           = 47
SIGNAL_PITCH                 = 48
SIGNAL_GATE                  = 49
SIGNAL_BEND                  = 50
SIGNAL_GENERAL_MOD_WHEEL     = 51
SIGNAL_GENERAL_UNIPOLAR_1    = 52
SIGNAL_GENERAL_UNIPOLAR_2    = 53
SIGNAL_GENERAL_UNIPOLAR_3    = 54
SIGNAL_GENERAL_UNIPOLAR_4    = 55
SIGNAL_GENERAL_BIPOLAR_1     = 56
SIGNAL_GENERAL_BIPOLAR_2     = 57
SIGNAL_GENERAL_BIPOLAR_3     = 58
SIGNAL_GENERAL_BIPOLAR_4     = 59
SIGNAL_SLEW_1_OUTPUT         = 60
SIGNAL_SLEW_1_TIME           = 61
SIGNAL_OSC_1_PULSE_WIDTH     = 62
SIGNAL_OSC_1_MOD_DESTINATION = 63

# NRPN parameter numbers: (MSB << 7) | LSB, where the MSB picks a category and the LSB an entry.
#   0..127   active_modules[slot]
# 128..255   what feeds each module input
# 256..383   where each parameter's value comes from
# 384..511   which CC fills each control slot
NRPN_ACTIVE_MODULE_BASE = 0

NRPN_SOURCE_ENV_GEN_1_GATE  = 128
NRPN_SOURCE_OSC_1_PITCH     = 129
NRPN_SOURCE_OSC_1_MOD       = 130
NRPN_SOURCE_FILTER_1_AUDIO  = 131
NRPN_SOURCE_FILTER_1_MOD    = 132
NRPN_SOURCE_AMP_1_AUDIO     = 133
NRPN_SOURCE_AMP_1_MOD       = 134
NRPN_SOURCE_MIXER_1_IN_1    = 135
NRPN_SOURCE_MIXER_1_IN_2    = 136
NRPN_SOURCE_CHORUS_1_AUDIO  = 137
NRPN_SOURCE_DELAY_1_AUDIO_L = 138
NRPN_SOURCE_DELAY_1_AUDIO_R = 139
NRPN_SOURCE_OUTPUT_L        = 140
NRPN_SOURCE_OUTPUT_R        = 141
NRPN_SOURCE_SLEW_1_IN       = 142

NRPN_SOURCE_LFO_1_RATE            = 256
NRPN_SOURCE_LFO_1_LEVEL           = 257
NRPN_SOURCE_LFO_1_POLARITY        = 258
NRPN_SOURCE_ENV_GEN_1_ATTACK      = 259
NRPN_SOURCE_ENV_GEN_1_DECAY       = 260
NRPN_SOURCE_ENV_GEN_1_SUSTAIN     = 261
NRPN_SOURCE_ENV_GEN_1_LEVEL       = 262
NRPN_SOURCE_ENV_GEN_1_POLARITY    = 263
NRPN_SOURCE_OSC_1_WAVEFORM        = 264
NRPN_SOURCE_OSC_1_COARSE_TUNE     = 265
NRPN_SOURCE_OSC_1_FINE_TUNE       = 266
NRPN_SOURCE_OSC_1_MOD_AMOUNT      = 267
NRPN_SOURCE_OSC_1_MOD_POLARITY    = 268
NRPN_SOURCE_FILTER_1_CUTOFF       = 269
NRPN_SOURCE_FILTER_1_RESONANCE    = 270
NRPN_SOURCE_FILTER_1_GAIN         = 271
NRPN_SOURCE_FILTER_1_MOD_AMOUNT   = 272
NRPN_SOURCE_FILTER_1_MOD_POLARITY = 273
NRPN_SOURCE_AMP_1_GAIN            = 274
NRPN_SOURCE_MIXER_1_LEVEL_1       = 275
NRPN_SOURCE_MIXER_1_POLARITY_1    = 276
NRPN_SOURCE_MIXER_1_LEVEL_2       = 277
NRPN_SOURCE_MIXER_1_POLARITY_2    = 278
NRPN_SOURCE_CHORUS_1_RATE         = 279
NRPN_SOURCE_CHORUS_1_DEPTH        = 280
NRPN_SOURCE_CHORUS_1_MIX          = 281
NRPN_SOURCE_DELAY_1_TIME          = 282
NRPN_SOURCE_DELAY_1_FEEDBACK      = 283
NRPN_SOURCE_DELAY_1_MIX           = 284
NRPN_SOURCE_SLEW_1_TIME           = 290
NRPN_SOURCE_OSC_1_PULSE_WIDTH     = 291
NRPN_SOURCE_OSC_1_MOD_DESTINATION = 292

# A CC number of 0 means the parameter has no CC: its control slot holds 0.0 -- the bottom of a
# unipolar dial, the middle of a bipolar one -- whatever CC it had before, so a patch sets it alone.
NRPN_CC_LFO_1_RATE            = 384
NRPN_CC_LFO_1_LEVEL           = 385
NRPN_CC_LFO_1_POLARITY        = 386
NRPN_CC_ENV_GEN_1_ATTACK      = 387
NRPN_CC_ENV_GEN_1_DECAY       = 388
NRPN_CC_ENV_GEN_1_SUSTAIN     = 389
NRPN_CC_ENV_GEN_1_LEVEL       = 390
NRPN_CC_ENV_GEN_1_POLARITY    = 391
NRPN_CC_OSC_1_WAVEFORM        = 392
NRPN_CC_OSC_1_COARSE_TUNE     = 393
NRPN_CC_OSC_1_FINE_TUNE       = 394
NRPN_CC_OSC_1_MOD_AMOUNT      = 395
NRPN_CC_OSC_1_MOD_POLARITY    = 396
NRPN_CC_FILTER_1_CUTOFF       = 397
NRPN_CC_FILTER_1_RESONANCE    = 398
NRPN_CC_FILTER_1_GAIN         = 399
NRPN_CC_FILTER_1_MOD_AMOUNT   = 400
NRPN_CC_FILTER_1_MOD_POLARITY = 401
NRPN_CC_AMP_1_GAIN            = 402
NRPN_CC_MIXER_1_LEVEL_1       = 403
NRPN_CC_MIXER_1_POLARITY_1    = 404
NRPN_CC_MIXER_1_LEVEL_2       = 405
NRPN_CC_MIXER_1_POLARITY_2    = 406
NRPN_CC_CHORUS_1_RATE         = 407
NRPN_CC_CHORUS_1_DEPTH        = 408
NRPN_CC_CHORUS_1_MIX          = 409
NRPN_CC_DELAY_1_TIME          = 410
NRPN_CC_DELAY_1_FEEDBACK      = 411
NRPN_CC_DELAY_1_MIX           = 412
NRPN_CC_GENERAL_MOD_WHEEL     = 413
NRPN_CC_GENERAL_1             = 414
NRPN_CC_GENERAL_2             = 415
NRPN_CC_GENERAL_3             = 416
NRPN_CC_GENERAL_4             = 417
NRPN_CC_SLEW_1_TIME           = 418
NRPN_CC_OSC_1_PULSE_WIDTH     = 419
NRPN_CC_OSC_1_MOD_DESTINATION = 420

# The constants of the bus, which nothing else ever writes. A slot not written here holds 0.0.
def spms1_fill_constant_signals(signals)
  signals[SIGNAL_ONE]             =  1.0
  signals[SIGNAL_HALF]            =  0.5
  signals[SIGNAL_POINT_TWO]       =  0.2
  signals[SIGNAL_POINT_ONE]       =  0.1
  signals[SIGNAL_MINUS_POINT_ONE] = -0.1
  signals[SIGNAL_MINUS_POINT_TWO] = -0.2
  signals[SIGNAL_MINUS_HALF]      = -0.5
  signals[SIGNAL_MINUS_ONE]       = -1.0
end

# The default patch, written into the NRPN table, and the values its CCs power up at.
def spms1_write_default_patch(midi_ch)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 0, MODULE_SLEW_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 1, MODULE_LFO_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 2, MODULE_ENV_GEN_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 3, MODULE_MIXER_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 4, MODULE_OSC_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 5, MODULE_FILTER_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 6, MODULE_AMP_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 7, MODULE_CHORUS_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 8, MODULE_DELAY_1)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_ENV_GEN_1_GATE , SIGNAL_GATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH    , SIGNAL_SLEW_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD      , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_AUDIO , SIGNAL_OSC_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD   , SIGNAL_ENV_GEN_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_AUDIO    , SIGNAL_FILTER_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_MOD      , SIGNAL_ENV_GEN_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_1   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_2   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_AUDIO , SIGNAL_AMP_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_L, SIGNAL_CHORUS_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_R, SIGNAL_CHORUS_1_OUTPUT_R)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_L       , SIGNAL_DELAY_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_R       , SIGNAL_DELAY_1_OUTPUT_R)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_SLEW_1_IN      , SIGNAL_PITCH)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE           , SIGNAL_LFO_1_RATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL          , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_POLARITY       , SIGNAL_POINT_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_ENV_GEN_1_ATTACK     , SIGNAL_ENV_GEN_1_ATTACK)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_ENV_GEN_1_DECAY      , SIGNAL_ENV_GEN_1_DECAY)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_ENV_GEN_1_SUSTAIN    , SIGNAL_ENV_GEN_1_SUSTAIN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_ENV_GEN_1_LEVEL      , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_ENV_GEN_1_POLARITY   , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_WAVEFORM       , SIGNAL_OSC_1_WAVEFORM)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_COARSE_TUNE    , SIGNAL_OSC_1_COARSE_TUNE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_FINE_TUNE      , SIGNAL_OSC_1_FINE_TUNE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_AMOUNT     , SIGNAL_OSC_1_MOD_AMOUNT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_POLARITY   , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_CUTOFF      , SIGNAL_FILTER_1_CUTOFF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_RESONANCE   , SIGNAL_FILTER_1_RESONANCE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_GAIN        , SIGNAL_FILTER_1_GAIN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_AMOUNT  , SIGNAL_FILTER_1_MOD_AMOUNT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_POLARITY, SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_GAIN           , SIGNAL_AMP_1_GAIN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_1      , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POLARITY_1   , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_2      , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POLARITY_2   , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_RATE        , SIGNAL_CHORUS_1_RATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_DEPTH       , SIGNAL_CHORUS_1_DEPTH)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_MIX         , SIGNAL_CHORUS_1_MIX)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_TIME         , SIGNAL_DELAY_1_TIME)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_FEEDBACK     , SIGNAL_DELAY_1_FEEDBACK)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_MIX          , SIGNAL_DELAY_1_MIX)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_SLEW_1_TIME          , SIGNAL_SLEW_1_TIME)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PULSE_WIDTH    , SIGNAL_OSC_1_PULSE_WIDTH)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_DESTINATION, SIGNAL_OSC_1_MOD_DESTINATION)

  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_RATE           , 3)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_ENV_GEN_1_ATTACK     , 73)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_ENV_GEN_1_DECAY      , 75)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_ENV_GEN_1_SUSTAIN    , 30)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_WAVEFORM       , 20)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_COARSE_TUNE    , 86)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_FINE_TUNE      , 70)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_MOD_AMOUNT     , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_CUTOFF      , 74)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_RESONANCE   , 71)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_GAIN        , 112)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_AMOUNT  , 24)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_AMP_1_GAIN           , 15)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_RATE        , 58)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_DEPTH       , 59)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_MIX         , 93)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_TIME         , 90)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_FEEDBACK     , 92)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_MIX          , 94)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_MOD_WHEEL    , 1)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_1            , 16)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_2            , 17)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_3            , 18)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_4            , 113)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_SLEW_1_TIME          , 5)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PULSE_WIDTH    , 19)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_MOD_DESTINATION, 103)

  C.set_midi_cc_value(midi_ch, 3  , 64 ) # LFO 1 Rate
  C.set_midi_cc_value(midi_ch, 73 , 4  ) # EG 1 Attack
  C.set_midi_cc_value(midi_ch, 75 , 96 ) # EG 1 Decay
  C.set_midi_cc_value(midi_ch, 30 , 124) # EG 1 Sustain
  C.set_midi_cc_value(midi_ch, 20 , 4  ) # Osc 1 Wave
  C.set_midi_cc_value(midi_ch, 86 , 64 ) # Osc 1 Coarse Tune
  C.set_midi_cc_value(midi_ch, 70 , 64 ) # Osc 1 Fine Tune
  C.set_midi_cc_value(midi_ch, 13 , 4  ) # Osc 1 Mod Amt
  C.set_midi_cc_value(midi_ch, 74 , 100) # Filter 1 Cutoff
  C.set_midi_cc_value(midi_ch, 71 , 94 ) # Filter 1 Resonance
  C.set_midi_cc_value(midi_ch, 112, 64 ) # Filter 1 Gain
  C.set_midi_cc_value(midi_ch, 24 , 28 ) # Filter 1 Mod Amt
  C.set_midi_cc_value(midi_ch, 15 , 124) # Amp 1 Gain
  C.set_midi_cc_value(midi_ch, 58 , 64 ) # Chorus 1 Rate
  C.set_midi_cc_value(midi_ch, 59 , 64 ) # Chorus 1 Depth
  C.set_midi_cc_value(midi_ch, 93 , 64 ) # Chorus 1 Mix
  C.set_midi_cc_value(midi_ch, 90 , 64 ) # Delay 1 Time
  C.set_midi_cc_value(midi_ch, 92 , 64 ) # Delay 1 Feedback
  C.set_midi_cc_value(midi_ch, 94 , 34 ) # Delay 1 Mix
  C.set_midi_cc_value(midi_ch, 1  , 4  ) # General Mod Wheel
  C.set_midi_cc_value(midi_ch, 16 , 64 ) # General 1
  C.set_midi_cc_value(midi_ch, 17 , 64 ) # General 2
  C.set_midi_cc_value(midi_ch, 18 , 64 ) # General 3
  C.set_midi_cc_value(midi_ch, 113, 64 ) # General 4
  C.set_midi_cc_value(midi_ch, 5  , 4  ) # Slew 1 Time
  C.set_midi_cc_value(midi_ch, 19 , 4  ) # Osc 1 Pulse Width
  C.set_midi_cc_value(midi_ch, 103, 4  ) # Osc 1 Mod Dst (Pitch|PW)
end
