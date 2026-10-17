# Generated from spms1_patch.yaml by patch_gen/spms1_patch_gen.rb. Do not edit; change the YAML
# and run the generator.

# Module ids, the values of NRPN category 0. MODULE_NONE ends the run order.
MODULE_NONE     = 0
MODULE_LFO_1    = 1
MODULE_EG_1     = 2
MODULE_OSC_1    = 3
MODULE_FILTER_1 = 4
MODULE_AMP_1    = 5
MODULE_MIXER_1  = 6
MODULE_CHORUS_1 = 7
MODULE_DELAY_1  = 8
MODULE_PITCH_1  = 9
MODULE_NOISE_1  = 10
MODULE_OSC_2    = 11
MODULE_MIXER_2  = 12

# Slots of the signal bus, the values of NRPN categories 1 and 2.
SIGNAL_NONE                = 0
SIGNAL_ONE                 = 1
SIGNAL_HALF                = 2
SIGNAL_POINT_TWO           = 3
SIGNAL_POINT_ONE           = 4
SIGNAL_MINUS_POINT_ONE     = 5
SIGNAL_MINUS_POINT_TWO     = 6
SIGNAL_MINUS_HALF          = 7
SIGNAL_MINUS_ONE           = 8
SIGNAL_LFO_1_OUTPUT        = 9
SIGNAL_EG_1_OUTPUT         = 10
SIGNAL_OSC_1_OUTPUT        = 11
SIGNAL_FILTER_1_OUTPUT_LP  = 12
SIGNAL_AMP_1_OUTPUT        = 13
SIGNAL_MIXER_1_OUTPUT      = 14
SIGNAL_CHORUS_1_OUTPUT_L   = 15
SIGNAL_CHORUS_1_OUTPUT_R   = 16
SIGNAL_DELAY_1_OUTPUT_L    = 17
SIGNAL_DELAY_1_OUTPUT_R    = 18
SIGNAL_LFO_1_RATE          = 19
SIGNAL_LFO_1_LEVEL         = 20
SIGNAL_EG_1_ATTACK         = 22
SIGNAL_EG_1_DECAY          = 23
SIGNAL_EG_1_SUSTAIN        = 24
SIGNAL_EG_1_LEVEL          = 25
SIGNAL_OSC_1_WAVE          = 27
SIGNAL_OSC_1_PITCH_COARSE  = 28
SIGNAL_OSC_1_PITCH_FINE    = 29
SIGNAL_OSC_1_MOD_2_AMT     = 30
SIGNAL_OSC_1_MOD_2_POL     = 31
SIGNAL_FILTER_1_CUTOFF     = 32
SIGNAL_FILTER_1_RESONANCE  = 33
SIGNAL_FILTER_1_GAIN       = 34
SIGNAL_FILTER_1_MOD_1_AMT  = 35
SIGNAL_FILTER_1_MOD_1_POL  = 36
SIGNAL_AMP_1_GAIN          = 37
SIGNAL_MIXER_1_LEVEL_1     = 38
SIGNAL_MIXER_1_POL_1       = 39
SIGNAL_MIXER_1_LEVEL_2     = 40
SIGNAL_MIXER_1_POL_2       = 41
SIGNAL_CHORUS_1_RATE       = 42
SIGNAL_CHORUS_1_DEPTH      = 43
SIGNAL_CHORUS_1_MIX        = 44
SIGNAL_DELAY_1_TIME        = 45
SIGNAL_DELAY_1_FEEDBACK    = 46
SIGNAL_DELAY_1_MIX         = 47
SIGNAL_NOTE_PITCH          = 48
SIGNAL_NOTE_GATE           = 49
SIGNAL_PITCH_BEND          = 50
SIGNAL_GENERAL_MOD_WHEEL   = 51
SIGNAL_GENERAL_UNIPOLAR_1  = 52
SIGNAL_GENERAL_UNIPOLAR_2  = 53
SIGNAL_GENERAL_UNIPOLAR_3  = 54
SIGNAL_GENERAL_UNIPOLAR_4  = 55
SIGNAL_GENERAL_BIPOLAR_1   = 56
SIGNAL_GENERAL_BIPOLAR_2   = 57
SIGNAL_GENERAL_BIPOLAR_3   = 58
SIGNAL_GENERAL_BIPOLAR_4   = 59
SIGNAL_PITCH_1_OUTPUT      = 60
SIGNAL_PITCH_1_GLIDE       = 61
SIGNAL_OSC_1_PULSE_WIDTH   = 62
SIGNAL_OSC_1_PW_MOD_AMT    = 63
SIGNAL_OSC_1_PW_MOD_POL    = 64
SIGNAL_FILTER_1_OUTPUT_BP  = 65
SIGNAL_FILTER_1_OUTPUT_HP  = 66
SIGNAL_LFO_1_RATE_MOD_AMT  = 69
SIGNAL_LFO_1_RATE_MOD_POL  = 70
SIGNAL_FILTER_1_MOD_2_AMT  = 73
SIGNAL_FILTER_1_MOD_2_POL  = 74
SIGNAL_FILTER_1_MOD_3_AMT  = 75
SIGNAL_FILTER_1_MOD_3_POL  = 76
SIGNAL_PITCH_1_BEND_AMT    = 77
SIGNAL_PITCH_1_BEND_POL    = 78
SIGNAL_LFO_1_LEVEL_MOD_AMT = 79
SIGNAL_LFO_1_LEVEL_MOD_POL = 80
SIGNAL_PITCH_1_COARSE      = 81
SIGNAL_PITCH_1_FINE        = 82
SIGNAL_MIXER_1_OUT_LEVEL   = 83
SIGNAL_OSC_1_MOD_1_AMT     = 84
SIGNAL_OSC_1_MOD_1_POL     = 85
SIGNAL_NOISE_1_OUTPUT      = 86
SIGNAL_NOISE_1_LEVEL       = 87
SIGNAL_OSC_2_OUTPUT        = 88
SIGNAL_OSC_2_WAVE          = 89
SIGNAL_OSC_2_PITCH_COARSE  = 90
SIGNAL_OSC_2_PITCH_FINE    = 91
SIGNAL_OSC_2_MOD_1_AMT     = 92
SIGNAL_OSC_2_MOD_1_POL     = 93
SIGNAL_OSC_2_MOD_2_AMT     = 94
SIGNAL_OSC_2_MOD_2_POL     = 95
SIGNAL_OSC_2_PULSE_WIDTH   = 96
SIGNAL_OSC_2_PW_MOD_AMT    = 97
SIGNAL_OSC_2_PW_MOD_POL    = 98
SIGNAL_MIXER_1_LEVEL_3     = 102
SIGNAL_MIXER_1_POL_3       = 103
SIGNAL_MIXER_1_LEVEL_4     = 104
SIGNAL_MIXER_1_POL_4       = 105
SIGNAL_MIXER_2_OUTPUT      = 106
SIGNAL_MIXER_2_LEVEL_1     = 107
SIGNAL_MIXER_2_POL_1       = 108
SIGNAL_MIXER_2_LEVEL_2     = 109
SIGNAL_MIXER_2_POL_2       = 110
SIGNAL_MIXER_2_LEVEL_3     = 111
SIGNAL_MIXER_2_POL_3       = 112
SIGNAL_MIXER_2_LEVEL_4     = 113
SIGNAL_MIXER_2_POL_4       = 114
SIGNAL_MIXER_2_OUT_LEVEL   = 115

# NRPN parameter numbers: (MSB << 7) | LSB, where the MSB picks a category and the LSB an entry.
#   0..127   active_modules[slot]
# 128..255   what feeds each module input
# 256..383   where each parameter's value comes from
# 384..511   which CC fills each control slot
NRPN_ACTIVE_MODULE_BASE = 0

NRPN_SOURCE_EG_1_GATE       = 128
NRPN_SOURCE_OSC_1_PITCH     = 129
NRPN_SOURCE_OSC_1_MOD_2     = 130
NRPN_SOURCE_FILTER_1_AUDIO  = 131
NRPN_SOURCE_FILTER_1_MOD_1  = 132
NRPN_SOURCE_AMP_1_AUDIO     = 133
NRPN_SOURCE_AMP_1_MOD       = 134
NRPN_SOURCE_MIXER_1_IN_1    = 135
NRPN_SOURCE_MIXER_1_IN_2    = 136
NRPN_SOURCE_CHORUS_1_AUDIO  = 137
NRPN_SOURCE_DELAY_1_AUDIO_L = 138
NRPN_SOURCE_DELAY_1_AUDIO_R = 139
NRPN_SOURCE_OUTPUT_L        = 140
NRPN_SOURCE_OUTPUT_R        = 141
NRPN_SOURCE_PITCH_1_PITCH   = 142
NRPN_SOURCE_OSC_1_PW_MOD    = 143
NRPN_SOURCE_LFO_1_RATE_MOD  = 144
NRPN_SOURCE_FILTER_1_MOD_2  = 145
NRPN_SOURCE_FILTER_1_MOD_3  = 146
NRPN_SOURCE_PITCH_1_BEND    = 147
NRPN_SOURCE_LFO_1_LEVEL_MOD = 148
NRPN_SOURCE_OSC_1_MOD_1     = 149
NRPN_SOURCE_OSC_2_PITCH     = 152
NRPN_SOURCE_OSC_2_MOD_1     = 153
NRPN_SOURCE_OSC_2_MOD_2     = 154
NRPN_SOURCE_OSC_2_PW_MOD    = 155
NRPN_SOURCE_MIXER_1_IN_3    = 156
NRPN_SOURCE_MIXER_1_IN_4    = 157
NRPN_SOURCE_MIXER_2_IN_1    = 158
NRPN_SOURCE_MIXER_2_IN_2    = 159
NRPN_SOURCE_MIXER_2_IN_3    = 160
NRPN_SOURCE_MIXER_2_IN_4    = 161

NRPN_SOURCE_LFO_1_RATE          = 256
NRPN_SOURCE_LFO_1_LEVEL         = 257
NRPN_SOURCE_EG_1_ATTACK         = 259
NRPN_SOURCE_EG_1_DECAY          = 260
NRPN_SOURCE_EG_1_SUSTAIN        = 261
NRPN_SOURCE_EG_1_LEVEL          = 262
NRPN_SOURCE_OSC_1_WAVE          = 264
NRPN_SOURCE_OSC_1_PITCH_COARSE  = 265
NRPN_SOURCE_OSC_1_PITCH_FINE    = 266
NRPN_SOURCE_OSC_1_MOD_2_AMT     = 267
NRPN_SOURCE_OSC_1_MOD_2_POL     = 268
NRPN_SOURCE_FILTER_1_CUTOFF     = 269
NRPN_SOURCE_FILTER_1_RESONANCE  = 270
NRPN_SOURCE_FILTER_1_GAIN       = 271
NRPN_SOURCE_FILTER_1_MOD_1_AMT  = 272
NRPN_SOURCE_FILTER_1_MOD_1_POL  = 273
NRPN_SOURCE_AMP_1_GAIN          = 274
NRPN_SOURCE_MIXER_1_LEVEL_1     = 275
NRPN_SOURCE_MIXER_1_POL_1       = 276
NRPN_SOURCE_MIXER_1_LEVEL_2     = 277
NRPN_SOURCE_MIXER_1_POL_2       = 278
NRPN_SOURCE_CHORUS_1_RATE       = 279
NRPN_SOURCE_CHORUS_1_DEPTH      = 280
NRPN_SOURCE_CHORUS_1_MIX        = 281
NRPN_SOURCE_DELAY_1_TIME        = 282
NRPN_SOURCE_DELAY_1_FEEDBACK    = 283
NRPN_SOURCE_DELAY_1_MIX         = 284
NRPN_SOURCE_PITCH_1_GLIDE       = 290
NRPN_SOURCE_OSC_1_PULSE_WIDTH   = 291
NRPN_SOURCE_OSC_1_PW_MOD_AMT    = 292
NRPN_SOURCE_OSC_1_PW_MOD_POL    = 293
NRPN_SOURCE_LFO_1_RATE_MOD_AMT  = 296
NRPN_SOURCE_LFO_1_RATE_MOD_POL  = 297
NRPN_SOURCE_FILTER_1_MOD_2_AMT  = 300
NRPN_SOURCE_FILTER_1_MOD_2_POL  = 301
NRPN_SOURCE_FILTER_1_MOD_3_AMT  = 302
NRPN_SOURCE_FILTER_1_MOD_3_POL  = 303
NRPN_SOURCE_PITCH_1_BEND_AMT    = 304
NRPN_SOURCE_PITCH_1_BEND_POL    = 305
NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT = 306
NRPN_SOURCE_LFO_1_LEVEL_MOD_POL = 307
NRPN_SOURCE_PITCH_1_COARSE      = 308
NRPN_SOURCE_PITCH_1_FINE        = 309
NRPN_SOURCE_MIXER_1_OUT_LEVEL   = 310
NRPN_SOURCE_OSC_1_MOD_1_AMT     = 311
NRPN_SOURCE_OSC_1_MOD_1_POL     = 312
NRPN_SOURCE_NOISE_1_LEVEL       = 313
NRPN_SOURCE_OSC_2_WAVE          = 314
NRPN_SOURCE_OSC_2_PITCH_COARSE  = 315
NRPN_SOURCE_OSC_2_PITCH_FINE    = 316
NRPN_SOURCE_OSC_2_MOD_1_AMT     = 317
NRPN_SOURCE_OSC_2_MOD_1_POL     = 318
NRPN_SOURCE_OSC_2_MOD_2_AMT     = 319
NRPN_SOURCE_OSC_2_MOD_2_POL     = 320
NRPN_SOURCE_OSC_2_PULSE_WIDTH   = 321
NRPN_SOURCE_OSC_2_PW_MOD_AMT    = 322
NRPN_SOURCE_OSC_2_PW_MOD_POL    = 323
NRPN_SOURCE_MIXER_1_LEVEL_3     = 327
NRPN_SOURCE_MIXER_1_POL_3       = 328
NRPN_SOURCE_MIXER_1_LEVEL_4     = 329
NRPN_SOURCE_MIXER_1_POL_4       = 330
NRPN_SOURCE_MIXER_2_LEVEL_1     = 331
NRPN_SOURCE_MIXER_2_POL_1       = 332
NRPN_SOURCE_MIXER_2_LEVEL_2     = 333
NRPN_SOURCE_MIXER_2_POL_2       = 334
NRPN_SOURCE_MIXER_2_LEVEL_3     = 335
NRPN_SOURCE_MIXER_2_POL_3       = 336
NRPN_SOURCE_MIXER_2_LEVEL_4     = 337
NRPN_SOURCE_MIXER_2_POL_4       = 338
NRPN_SOURCE_MIXER_2_OUT_LEVEL   = 339

# A CC number of 0 means the parameter has no CC: its control slot holds 0.0 -- the bottom of a
# unipolar dial, the middle of a bipolar one -- whatever CC it had before, so a patch sets it alone.
NRPN_CC_LFO_1_RATE          = 384
NRPN_CC_LFO_1_LEVEL         = 385
NRPN_CC_EG_1_ATTACK         = 387
NRPN_CC_EG_1_DECAY          = 388
NRPN_CC_EG_1_SUSTAIN        = 389
NRPN_CC_EG_1_LEVEL          = 390
NRPN_CC_OSC_1_WAVE          = 392
NRPN_CC_OSC_1_PITCH_COARSE  = 393
NRPN_CC_OSC_1_PITCH_FINE    = 394
NRPN_CC_OSC_1_MOD_2_AMT     = 395
NRPN_CC_OSC_1_MOD_2_POL     = 396
NRPN_CC_FILTER_1_CUTOFF     = 397
NRPN_CC_FILTER_1_RESONANCE  = 398
NRPN_CC_FILTER_1_GAIN       = 399
NRPN_CC_FILTER_1_MOD_1_AMT  = 400
NRPN_CC_FILTER_1_MOD_1_POL  = 401
NRPN_CC_AMP_1_GAIN          = 402
NRPN_CC_MIXER_1_LEVEL_1     = 403
NRPN_CC_MIXER_1_POL_1       = 404
NRPN_CC_MIXER_1_LEVEL_2     = 405
NRPN_CC_MIXER_1_POL_2       = 406
NRPN_CC_CHORUS_1_RATE       = 407
NRPN_CC_CHORUS_1_DEPTH      = 408
NRPN_CC_CHORUS_1_MIX        = 409
NRPN_CC_DELAY_1_TIME        = 410
NRPN_CC_DELAY_1_FEEDBACK    = 411
NRPN_CC_DELAY_1_MIX         = 412
NRPN_CC_GENERAL_MOD_WHEEL   = 413
NRPN_CC_GENERAL_1           = 414
NRPN_CC_GENERAL_2           = 415
NRPN_CC_GENERAL_3           = 416
NRPN_CC_GENERAL_4           = 417
NRPN_CC_PITCH_1_GLIDE       = 418
NRPN_CC_OSC_1_PULSE_WIDTH   = 419
NRPN_CC_OSC_1_PW_MOD_AMT    = 420
NRPN_CC_OSC_1_PW_MOD_POL    = 421
NRPN_CC_LFO_1_RATE_MOD_AMT  = 424
NRPN_CC_LFO_1_RATE_MOD_POL  = 425
NRPN_CC_FILTER_1_MOD_2_AMT  = 428
NRPN_CC_FILTER_1_MOD_2_POL  = 429
NRPN_CC_FILTER_1_MOD_3_AMT  = 430
NRPN_CC_FILTER_1_MOD_3_POL  = 431
NRPN_CC_PITCH_1_BEND_AMT    = 432
NRPN_CC_PITCH_1_BEND_POL    = 433
NRPN_CC_LFO_1_LEVEL_MOD_AMT = 434
NRPN_CC_LFO_1_LEVEL_MOD_POL = 435
NRPN_CC_PITCH_1_COARSE      = 436
NRPN_CC_PITCH_1_FINE        = 437
NRPN_CC_MIXER_1_OUT_LEVEL   = 438
NRPN_CC_OSC_1_MOD_1_AMT     = 439
NRPN_CC_OSC_1_MOD_1_POL     = 440
NRPN_CC_NOISE_1_LEVEL       = 441
NRPN_CC_OSC_2_WAVE          = 442
NRPN_CC_OSC_2_PITCH_COARSE  = 443
NRPN_CC_OSC_2_PITCH_FINE    = 444
NRPN_CC_OSC_2_MOD_1_AMT     = 445
NRPN_CC_OSC_2_MOD_1_POL     = 446
NRPN_CC_OSC_2_MOD_2_AMT     = 447
NRPN_CC_OSC_2_MOD_2_POL     = 448
NRPN_CC_OSC_2_PULSE_WIDTH   = 449
NRPN_CC_OSC_2_PW_MOD_AMT    = 450
NRPN_CC_OSC_2_PW_MOD_POL    = 451
NRPN_CC_MIXER_1_LEVEL_3     = 455
NRPN_CC_MIXER_1_POL_3       = 456
NRPN_CC_MIXER_1_LEVEL_4     = 457
NRPN_CC_MIXER_1_POL_4       = 458
NRPN_CC_MIXER_2_LEVEL_1     = 459
NRPN_CC_MIXER_2_POL_1       = 460
NRPN_CC_MIXER_2_LEVEL_2     = 461
NRPN_CC_MIXER_2_POL_2       = 462
NRPN_CC_MIXER_2_LEVEL_3     = 463
NRPN_CC_MIXER_2_POL_3       = 464
NRPN_CC_MIXER_2_LEVEL_4     = 465
NRPN_CC_MIXER_2_POL_4       = 466
NRPN_CC_MIXER_2_OUT_LEVEL   = 467

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
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 0, MODULE_LFO_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 1, MODULE_EG_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 2, MODULE_NOISE_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 3, MODULE_MIXER_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 4, MODULE_PITCH_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 5, MODULE_OSC_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 6, MODULE_OSC_2)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 7, MODULE_MIXER_2)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 8, MODULE_FILTER_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 9, MODULE_AMP_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 10, MODULE_CHORUS_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 11, MODULE_DELAY_1)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_GATE      , SIGNAL_NOTE_GATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH    , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_2    , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_AUDIO , SIGNAL_MIXER_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1 , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_AUDIO    , SIGNAL_FILTER_1_OUTPUT_LP)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_MOD      , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_1   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_2   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_AUDIO , SIGNAL_AMP_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_L, SIGNAL_CHORUS_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_R, SIGNAL_CHORUS_1_OUTPUT_R)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_L       , SIGNAL_DELAY_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_R       , SIGNAL_DELAY_1_OUTPUT_R)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_PITCH  , SIGNAL_NOTE_PITCH)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD   , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2 , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_3 , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND   , SIGNAL_PITCH_BEND)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD, SIGNAL_GENERAL_MOD_WHEEL)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_1    , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH    , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_1    , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_2    , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD   , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_3   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_4   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_1   , SIGNAL_OSC_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_2   , SIGNAL_OSC_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_3   , SIGNAL_NOISE_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_4   , SIGNAL_NONE)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE         , SIGNAL_LFO_1_RATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL        , SIGNAL_LFO_1_LEVEL)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_ATTACK        , SIGNAL_EG_1_ATTACK)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_DECAY         , SIGNAL_EG_1_DECAY)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_SUSTAIN       , SIGNAL_EG_1_SUSTAIN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_LEVEL         , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_WAVE         , SIGNAL_OSC_1_WAVE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_COARSE , SIGNAL_OSC_1_PITCH_COARSE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_FINE   , SIGNAL_OSC_1_PITCH_FINE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_2_AMT    , SIGNAL_OSC_1_MOD_2_AMT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_2_POL    , SIGNAL_POINT_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_CUTOFF    , SIGNAL_FILTER_1_CUTOFF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_RESONANCE , SIGNAL_FILTER_1_RESONANCE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_GAIN      , SIGNAL_FILTER_1_GAIN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1_AMT , SIGNAL_FILTER_1_MOD_1_AMT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_GAIN         , SIGNAL_AMP_1_GAIN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_1    , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_1      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_2    , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_2      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_RATE      , SIGNAL_CHORUS_1_RATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_DEPTH     , SIGNAL_CHORUS_1_DEPTH)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_MIX       , SIGNAL_CHORUS_1_MIX)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_TIME       , SIGNAL_DELAY_1_TIME)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_FEEDBACK   , SIGNAL_DELAY_1_FEEDBACK)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_MIX        , SIGNAL_DELAY_1_MIX)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_GLIDE      , SIGNAL_PITCH_1_GLIDE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PULSE_WIDTH  , SIGNAL_OSC_1_PULSE_WIDTH)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_AMT   , SIGNAL_OSC_1_PW_MOD_AMT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_POL   , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_AMT , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2_AMT , SIGNAL_FILTER_1_MOD_2_AMT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2_POL , SIGNAL_POINT_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_3_AMT , SIGNAL_FILTER_1_MOD_3_AMT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_3_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_AMT   , SIGNAL_PITCH_1_BEND_AMT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_POL   , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT, SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_POL, SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_COARSE     , SIGNAL_PITCH_1_COARSE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_FINE       , SIGNAL_PITCH_1_FINE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_OUT_LEVEL  , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_1_AMT    , SIGNAL_OSC_1_MOD_1_AMT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_1_POL    , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_NOISE_1_LEVEL      , SIGNAL_NOISE_1_LEVEL)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_WAVE         , SIGNAL_OSC_2_WAVE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_COARSE , SIGNAL_OSC_2_PITCH_COARSE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_FINE   , SIGNAL_OSC_2_PITCH_FINE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_1_AMT    , SIGNAL_OSC_1_MOD_1_AMT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_1_POL    , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_2_AMT    , SIGNAL_OSC_1_MOD_2_AMT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_2_POL    , SIGNAL_POINT_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PULSE_WIDTH  , SIGNAL_OSC_1_PULSE_WIDTH)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_AMT   , SIGNAL_OSC_1_PW_MOD_AMT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_POL   , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_3    , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_3      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_4    , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_4      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_1    , SIGNAL_MIXER_2_LEVEL_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_1      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_2    , SIGNAL_MIXER_2_LEVEL_2)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_2      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_3    , SIGNAL_MIXER_2_LEVEL_3)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_3      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_4    , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_4      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_OUT_LEVEL  , SIGNAL_ONE)

  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_RATE        , 3)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_LEVEL       , 113)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_ATTACK       , 73)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_DECAY        , 75)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_SUSTAIN      , 30)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_WAVE        , 102)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_MOD_2_AMT   , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_CUTOFF   , 74)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_RESONANCE, 71)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_GAIN     , 112)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_1_AMT, 24)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_AMP_1_GAIN        , 15)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_RATE     , 58)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_DEPTH    , 59)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_MIX      , 93)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_TIME      , 90)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_FEEDBACK  , 92)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_MIX       , 94)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_MOD_WHEEL , 1)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_1         , 16)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_2         , 17)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_3         , 18)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_4         , 19)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_GLIDE     , 5)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PULSE_WIDTH , 114)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_AMT  , 115)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_2_AMT, 25)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_3_AMT, 9)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_BEND_AMT  , 57)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_COARSE    , 86)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_FINE      , 70)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_MOD_1_AMT   , 89)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_NOISE_1_LEVEL     , 23)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_WAVE        , 104)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_COARSE, 85)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_FINE  , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_1   , 116)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_2   , 21)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_3   , 117)

  C.set_midi_cc_value(midi_ch, 3  , 64 ) # LFO 1 Rate
  C.set_midi_cc_value(midi_ch, 113, 124) # LFO 1 Level
  C.set_midi_cc_value(midi_ch, 73 , 4  ) # EG 1 Attack
  C.set_midi_cc_value(midi_ch, 75 , 96 ) # EG 1 Decay
  C.set_midi_cc_value(midi_ch, 30 , 124) # EG 1 Sustain
  C.set_midi_cc_value(midi_ch, 102, 4  ) # Osc 1 Wave
  C.set_midi_cc_value(midi_ch, 13 , 4  ) # Osc 1 Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 74 , 100) # Filter 1 Cutoff
  C.set_midi_cc_value(midi_ch, 71 , 94 ) # Filter 1 Resonance
  C.set_midi_cc_value(midi_ch, 112, 64 ) # Filter 1 Gain
  C.set_midi_cc_value(midi_ch, 24 , 28 ) # Filter 1 Mod 1 Amt
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
  C.set_midi_cc_value(midi_ch, 19 , 64 ) # General 4
  C.set_midi_cc_value(midi_ch, 5  , 4  ) # Pitch 1 Glide
  C.set_midi_cc_value(midi_ch, 114, 4  ) # Osc 1 Pulse Width
  C.set_midi_cc_value(midi_ch, 115, 4  ) # Osc 1 PW Mod Amt
  C.set_midi_cc_value(midi_ch, 25 , 4  ) # Filter 1 Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 9  , 4  ) # Filter 1 Mod 3 Amt
  C.set_midi_cc_value(midi_ch, 57 , 8  ) # Pitch 1 Bend Amt
  C.set_midi_cc_value(midi_ch, 86 , 64 ) # Pitch 1 Coarse
  C.set_midi_cc_value(midi_ch, 70 , 64 ) # Pitch 1 Fine
  C.set_midi_cc_value(midi_ch, 89 , 4  ) # Osc 1 Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 23 , 4  ) # Noise 1 Level
  C.set_midi_cc_value(midi_ch, 104, 4  ) # Osc 2 Wave
  C.set_midi_cc_value(midi_ch, 85 , 64 ) # Osc 2 Pitch Coarse
  C.set_midi_cc_value(midi_ch, 76 , 76 ) # Osc 2 Pitch Fine
  C.set_midi_cc_value(midi_ch, 116, 124) # Mixer 2 Level 1
  C.set_midi_cc_value(midi_ch, 21 , 4  ) # Mixer 2 Level 2
  C.set_midi_cc_value(midi_ch, 117, 124) # Mixer 2 Level 3
end
