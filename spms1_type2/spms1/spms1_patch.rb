# Generated from spms1_patch.yaml by patch_gen/spms1_patch_gen.rb. Do not edit; change the YAML
# and run the generator.

# Module ids, the values of NRPN category 0. MODULE_NONE ends the run order.
MODULE_NONE     = 0
MODULE_EG_1     = 1
MODULE_LFO_1    = 2
MODULE_MIXER_1  = 3
MODULE_PITCH_1  = 4
MODULE_OSC_1    = 5
MODULE_OSC_2    = 6
MODULE_NOISE_1  = 7
MODULE_MIXER_2  = 8
MODULE_FILTER_1 = 9
MODULE_AMP_1    = 10
MODULE_CHORUS_1 = 11
MODULE_DELAY_1  = 12

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
SIGNAL_NOTE_PITCH            = 9
SIGNAL_NOTE_GATE             = 10
SIGNAL_PITCH_BEND            = 11
SIGNAL_GENERAL_MOD_WHEEL     = 12
SIGNAL_GENERAL_UNIPOLAR_1    = 13
SIGNAL_GENERAL_UNIPOLAR_2    = 14
SIGNAL_GENERAL_UNIPOLAR_3    = 15
SIGNAL_GENERAL_UNIPOLAR_4    = 16
SIGNAL_GENERAL_BIPOLAR_1     = 17
SIGNAL_GENERAL_BIPOLAR_2     = 18
SIGNAL_GENERAL_BIPOLAR_3     = 19
SIGNAL_GENERAL_BIPOLAR_4     = 20
SIGNAL_EG_1_OUTPUT           = 21
SIGNAL_EG_1_OUTPUT_INV       = 22
SIGNAL_LFO_1_OUTPUT          = 23
SIGNAL_LFO_1_OUTPUT_INV      = 24
SIGNAL_LFO_1_OUTPUT_TRIANGLE = 25
SIGNAL_LFO_1_OUTPUT_SQUARE   = 26
SIGNAL_MIXER_1_OUTPUT        = 27
SIGNAL_PITCH_1_OUTPUT        = 28
SIGNAL_OSC_1_OUTPUT          = 29
SIGNAL_OSC_1_OUTPUT_SAW      = 30
SIGNAL_OSC_1_OUTPUT_PULSE    = 31
SIGNAL_OSC_2_OUTPUT          = 32
SIGNAL_OSC_2_OUTPUT_SAW      = 33
SIGNAL_OSC_2_OUTPUT_PULSE    = 34
SIGNAL_NOISE_1_OUTPUT        = 35
SIGNAL_NOISE_1_OUTPUT_WHITE  = 36
SIGNAL_NOISE_1_OUTPUT_RED    = 37
SIGNAL_MIXER_2_OUTPUT        = 38
SIGNAL_FILTER_1_OUTPUT       = 39
SIGNAL_FILTER_1_OUTPUT_LP    = 40
SIGNAL_FILTER_1_OUTPUT_HP    = 41
SIGNAL_AMP_1_OUTPUT          = 42
SIGNAL_CHORUS_1_OUTPUT_L     = 43
SIGNAL_CHORUS_1_OUTPUT_R     = 44
SIGNAL_CHORUS_1_OUTPUT_MONO  = 45
SIGNAL_DELAY_1_OUTPUT_L      = 46
SIGNAL_DELAY_1_OUTPUT_R      = 47
SIGNAL_DELAY_1_OUTPUT_MONO   = 48

# A parameter source of SIGNAL_OWN is the parameter's own control slot, at PARAM_SLOT_BASE + its
# entry, off the bus: the slots below.
SIGNAL_OWN      = 127
PARAM_SLOT_BASE = 128

SLOT_EG_1_ATTACK           = 128
SLOT_EG_1_DECAY            = 129
SLOT_EG_1_SUSTAIN          = 130
SLOT_EG_1_RELEASE_SW       = 131
SLOT_EG_1_LEVEL            = 132
SLOT_LFO_1_RATE            = 133
SLOT_LFO_1_RATE_MOD_AMT    = 134
SLOT_LFO_1_RATE_MOD_POL    = 135
SLOT_LFO_1_LEVEL           = 136
SLOT_LFO_1_WAVE            = 137
SLOT_LFO_1_LEVEL_MOD_AMT   = 138
SLOT_LFO_1_LEVEL_MOD_POL   = 139
SLOT_MIXER_1_LEVEL_1       = 140
SLOT_MIXER_1_LEVEL_2       = 141
SLOT_MIXER_1_LEVEL_3       = 142
SLOT_MIXER_1_OUT_LEVEL     = 143
SLOT_PITCH_1_GLIDE         = 144
SLOT_PITCH_1_GLIDE_SW      = 145
SLOT_PITCH_1_COARSE        = 146
SLOT_PITCH_1_FINE          = 147
SLOT_PITCH_1_STRETCH       = 148
SLOT_PITCH_1_BEND_AMT      = 149
SLOT_PITCH_1_BEND_POL      = 150
SLOT_OSC_1_PITCH_COARSE    = 151
SLOT_OSC_1_PITCH_FINE      = 152
SLOT_OSC_1_MOD_MIX         = 153
SLOT_OSC_1_PITCH_MOD_AMT   = 154
SLOT_OSC_1_PITCH_MOD_RANGE = 155
SLOT_OSC_1_WAVE            = 156
SLOT_OSC_1_PULSE_WIDTH     = 157
SLOT_OSC_1_PW_MOD_AMT      = 158
SLOT_OSC_2_PITCH_COARSE    = 159
SLOT_OSC_2_PITCH_FINE      = 160
SLOT_OSC_2_MOD_MIX         = 161
SLOT_OSC_2_PITCH_MOD_AMT   = 162
SLOT_OSC_2_PITCH_MOD_RANGE = 163
SLOT_OSC_2_WAVE            = 164
SLOT_OSC_2_PULSE_WIDTH     = 165
SLOT_OSC_2_PW_MOD_AMT      = 166
SLOT_NOISE_1_LEVEL         = 167
SLOT_NOISE_1_COLOR         = 168
SLOT_MIXER_2_LEVEL_1       = 169
SLOT_MIXER_2_LEVEL_2       = 170
SLOT_MIXER_2_LEVEL_3       = 171
SLOT_MIXER_2_OUT_LEVEL     = 172
SLOT_FILTER_1_GAIN         = 173
SLOT_FILTER_1_CUTOFF       = 174
SLOT_FILTER_1_PITCH_AMT    = 175
SLOT_FILTER_1_MOD_MIX      = 176
SLOT_FILTER_1_MOD_AMT      = 177
SLOT_FILTER_1_RESONANCE    = 178
SLOT_FILTER_1_MODE         = 179
SLOT_AMP_1_GAIN            = 180
SLOT_CHORUS_1_MIX          = 181
SLOT_CHORUS_1_RATE         = 182
SLOT_CHORUS_1_DEPTH        = 183
SLOT_DELAY_1_MIX           = 184
SLOT_DELAY_1_TIME          = 185
SLOT_DELAY_1_FEEDBACK      = 186

# NRPN parameter numbers: (MSB << 7) | LSB, where the MSB picks a category and the LSB an entry.
#   0..127   active_modules[slot]
# 128..255   what feeds each module input
# 256..383   where each parameter's value comes from
# 384..511   which CC fills each control slot
# 512..639   the value of each parameter's control slot while it has no CC
NRPN_ACTIVE_MODULE_BASE = 0

NRPN_SOURCE_EG_1_GATE       = 128
NRPN_SOURCE_LFO_1_RATE_MOD  = 129
NRPN_SOURCE_LFO_1_LEVEL_MOD = 130
NRPN_SOURCE_MIXER_1_IN_1    = 131
NRPN_SOURCE_MIXER_1_IN_2    = 132
NRPN_SOURCE_MIXER_1_IN_3    = 133
NRPN_SOURCE_PITCH_1_PITCH   = 134
NRPN_SOURCE_PITCH_1_BEND    = 135
NRPN_SOURCE_OSC_1_PITCH     = 136
NRPN_SOURCE_OSC_1_MOD_1     = 137
NRPN_SOURCE_OSC_1_MOD_2     = 138
NRPN_SOURCE_OSC_2_PITCH     = 139
NRPN_SOURCE_OSC_2_MOD_1     = 140
NRPN_SOURCE_OSC_2_MOD_2     = 141
NRPN_SOURCE_MIXER_2_IN_1    = 142
NRPN_SOURCE_MIXER_2_IN_2    = 143
NRPN_SOURCE_MIXER_2_IN_3    = 144
NRPN_SOURCE_FILTER_1_AUDIO  = 145
NRPN_SOURCE_FILTER_1_PITCH  = 146
NRPN_SOURCE_FILTER_1_MOD_1  = 147
NRPN_SOURCE_FILTER_1_MOD_2  = 148
NRPN_SOURCE_AMP_1_AUDIO     = 149
NRPN_SOURCE_AMP_1_MOD       = 150
NRPN_SOURCE_CHORUS_1_AUDIO  = 151
NRPN_SOURCE_DELAY_1_AUDIO_L = 152
NRPN_SOURCE_DELAY_1_AUDIO_R = 153
NRPN_SOURCE_OUTPUT_L        = 154
NRPN_SOURCE_OUTPUT_R        = 155

NRPN_SOURCE_EG_1_ATTACK           = 256
NRPN_SOURCE_EG_1_DECAY            = 257
NRPN_SOURCE_EG_1_SUSTAIN          = 258
NRPN_SOURCE_EG_1_RELEASE_SW       = 259
NRPN_SOURCE_EG_1_LEVEL            = 260
NRPN_SOURCE_LFO_1_RATE            = 261
NRPN_SOURCE_LFO_1_RATE_MOD_AMT    = 262
NRPN_SOURCE_LFO_1_RATE_MOD_POL    = 263
NRPN_SOURCE_LFO_1_LEVEL           = 264
NRPN_SOURCE_LFO_1_WAVE            = 265
NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT   = 266
NRPN_SOURCE_LFO_1_LEVEL_MOD_POL   = 267
NRPN_SOURCE_MIXER_1_LEVEL_1       = 268
NRPN_SOURCE_MIXER_1_LEVEL_2       = 269
NRPN_SOURCE_MIXER_1_LEVEL_3       = 270
NRPN_SOURCE_MIXER_1_OUT_LEVEL     = 271
NRPN_SOURCE_PITCH_1_GLIDE         = 272
NRPN_SOURCE_PITCH_1_GLIDE_SW      = 273
NRPN_SOURCE_PITCH_1_COARSE        = 274
NRPN_SOURCE_PITCH_1_FINE          = 275
NRPN_SOURCE_PITCH_1_STRETCH       = 276
NRPN_SOURCE_PITCH_1_BEND_AMT      = 277
NRPN_SOURCE_PITCH_1_BEND_POL      = 278
NRPN_SOURCE_OSC_1_PITCH_COARSE    = 279
NRPN_SOURCE_OSC_1_PITCH_FINE      = 280
NRPN_SOURCE_OSC_1_MOD_MIX         = 281
NRPN_SOURCE_OSC_1_PITCH_MOD_AMT   = 282
NRPN_SOURCE_OSC_1_PITCH_MOD_RANGE = 283
NRPN_SOURCE_OSC_1_WAVE            = 284
NRPN_SOURCE_OSC_1_PULSE_WIDTH     = 285
NRPN_SOURCE_OSC_1_PW_MOD_AMT      = 286
NRPN_SOURCE_OSC_2_PITCH_COARSE    = 287
NRPN_SOURCE_OSC_2_PITCH_FINE      = 288
NRPN_SOURCE_OSC_2_MOD_MIX         = 289
NRPN_SOURCE_OSC_2_PITCH_MOD_AMT   = 290
NRPN_SOURCE_OSC_2_PITCH_MOD_RANGE = 291
NRPN_SOURCE_OSC_2_WAVE            = 292
NRPN_SOURCE_OSC_2_PULSE_WIDTH     = 293
NRPN_SOURCE_OSC_2_PW_MOD_AMT      = 294
NRPN_SOURCE_NOISE_1_LEVEL         = 295
NRPN_SOURCE_NOISE_1_COLOR         = 296
NRPN_SOURCE_MIXER_2_LEVEL_1       = 297
NRPN_SOURCE_MIXER_2_LEVEL_2       = 298
NRPN_SOURCE_MIXER_2_LEVEL_3       = 299
NRPN_SOURCE_MIXER_2_OUT_LEVEL     = 300
NRPN_SOURCE_FILTER_1_GAIN         = 301
NRPN_SOURCE_FILTER_1_CUTOFF       = 302
NRPN_SOURCE_FILTER_1_PITCH_AMT    = 303
NRPN_SOURCE_FILTER_1_MOD_MIX      = 304
NRPN_SOURCE_FILTER_1_MOD_AMT      = 305
NRPN_SOURCE_FILTER_1_RESONANCE    = 306
NRPN_SOURCE_FILTER_1_MODE         = 307
NRPN_SOURCE_AMP_1_GAIN            = 308
NRPN_SOURCE_CHORUS_1_MIX          = 309
NRPN_SOURCE_CHORUS_1_RATE         = 310
NRPN_SOURCE_CHORUS_1_DEPTH        = 311
NRPN_SOURCE_DELAY_1_MIX           = 312
NRPN_SOURCE_DELAY_1_TIME          = 313
NRPN_SOURCE_DELAY_1_FEEDBACK      = 314

# A CC number of 0 means the control has no CC: a parameter's control slot then holds its NRPN_VALUE_*
# below, whatever CC it had before, so a patch sets it alone, and a General slot holds 0.0.
NRPN_CC_EG_1_ATTACK           = 384
NRPN_CC_EG_1_DECAY            = 385
NRPN_CC_EG_1_SUSTAIN          = 386
NRPN_CC_EG_1_RELEASE_SW       = 387
NRPN_CC_EG_1_LEVEL            = 388
NRPN_CC_LFO_1_RATE            = 389
NRPN_CC_LFO_1_RATE_MOD_AMT    = 390
NRPN_CC_LFO_1_RATE_MOD_POL    = 391
NRPN_CC_LFO_1_LEVEL           = 392
NRPN_CC_LFO_1_WAVE            = 393
NRPN_CC_LFO_1_LEVEL_MOD_AMT   = 394
NRPN_CC_LFO_1_LEVEL_MOD_POL   = 395
NRPN_CC_MIXER_1_LEVEL_1       = 396
NRPN_CC_MIXER_1_LEVEL_2       = 397
NRPN_CC_MIXER_1_LEVEL_3       = 398
NRPN_CC_MIXER_1_OUT_LEVEL     = 399
NRPN_CC_PITCH_1_GLIDE         = 400
NRPN_CC_PITCH_1_GLIDE_SW      = 401
NRPN_CC_PITCH_1_COARSE        = 402
NRPN_CC_PITCH_1_FINE          = 403
NRPN_CC_PITCH_1_STRETCH       = 404
NRPN_CC_PITCH_1_BEND_AMT      = 405
NRPN_CC_PITCH_1_BEND_POL      = 406
NRPN_CC_OSC_1_PITCH_COARSE    = 407
NRPN_CC_OSC_1_PITCH_FINE      = 408
NRPN_CC_OSC_1_MOD_MIX         = 409
NRPN_CC_OSC_1_PITCH_MOD_AMT   = 410
NRPN_CC_OSC_1_PITCH_MOD_RANGE = 411
NRPN_CC_OSC_1_WAVE            = 412
NRPN_CC_OSC_1_PULSE_WIDTH     = 413
NRPN_CC_OSC_1_PW_MOD_AMT      = 414
NRPN_CC_OSC_2_PITCH_COARSE    = 415
NRPN_CC_OSC_2_PITCH_FINE      = 416
NRPN_CC_OSC_2_MOD_MIX         = 417
NRPN_CC_OSC_2_PITCH_MOD_AMT   = 418
NRPN_CC_OSC_2_PITCH_MOD_RANGE = 419
NRPN_CC_OSC_2_WAVE            = 420
NRPN_CC_OSC_2_PULSE_WIDTH     = 421
NRPN_CC_OSC_2_PW_MOD_AMT      = 422
NRPN_CC_NOISE_1_LEVEL         = 423
NRPN_CC_NOISE_1_COLOR         = 424
NRPN_CC_MIXER_2_LEVEL_1       = 425
NRPN_CC_MIXER_2_LEVEL_2       = 426
NRPN_CC_MIXER_2_LEVEL_3       = 427
NRPN_CC_MIXER_2_OUT_LEVEL     = 428
NRPN_CC_FILTER_1_GAIN         = 429
NRPN_CC_FILTER_1_CUTOFF       = 430
NRPN_CC_FILTER_1_PITCH_AMT    = 431
NRPN_CC_FILTER_1_MOD_MIX      = 432
NRPN_CC_FILTER_1_MOD_AMT      = 433
NRPN_CC_FILTER_1_RESONANCE    = 434
NRPN_CC_FILTER_1_MODE         = 435
NRPN_CC_AMP_1_GAIN            = 436
NRPN_CC_CHORUS_1_MIX          = 437
NRPN_CC_CHORUS_1_RATE         = 438
NRPN_CC_CHORUS_1_DEPTH        = 439
NRPN_CC_DELAY_1_MIX           = 440
NRPN_CC_DELAY_1_TIME          = 441
NRPN_CC_DELAY_1_FEEDBACK      = 442
NRPN_CC_GENERAL_MOD_WHEEL     = 443
NRPN_CC_GENERAL_1             = 444
NRPN_CC_GENERAL_2             = 445
NRPN_CC_GENERAL_3             = 446
NRPN_CC_GENERAL_4             = 447

# The value of each parameter's control slot while it has no CC, as a CC value.
NRPN_VALUE_EG_1_ATTACK           = 512
NRPN_VALUE_EG_1_DECAY            = 513
NRPN_VALUE_EG_1_SUSTAIN          = 514
NRPN_VALUE_EG_1_RELEASE_SW       = 515
NRPN_VALUE_EG_1_LEVEL            = 516
NRPN_VALUE_LFO_1_RATE            = 517
NRPN_VALUE_LFO_1_RATE_MOD_AMT    = 518
NRPN_VALUE_LFO_1_RATE_MOD_POL    = 519
NRPN_VALUE_LFO_1_LEVEL           = 520
NRPN_VALUE_LFO_1_WAVE            = 521
NRPN_VALUE_LFO_1_LEVEL_MOD_AMT   = 522
NRPN_VALUE_LFO_1_LEVEL_MOD_POL   = 523
NRPN_VALUE_MIXER_1_LEVEL_1       = 524
NRPN_VALUE_MIXER_1_LEVEL_2       = 525
NRPN_VALUE_MIXER_1_LEVEL_3       = 526
NRPN_VALUE_MIXER_1_OUT_LEVEL     = 527
NRPN_VALUE_PITCH_1_GLIDE         = 528
NRPN_VALUE_PITCH_1_GLIDE_SW      = 529
NRPN_VALUE_PITCH_1_COARSE        = 530
NRPN_VALUE_PITCH_1_FINE          = 531
NRPN_VALUE_PITCH_1_STRETCH       = 532
NRPN_VALUE_PITCH_1_BEND_AMT      = 533
NRPN_VALUE_PITCH_1_BEND_POL      = 534
NRPN_VALUE_OSC_1_PITCH_COARSE    = 535
NRPN_VALUE_OSC_1_PITCH_FINE      = 536
NRPN_VALUE_OSC_1_MOD_MIX         = 537
NRPN_VALUE_OSC_1_PITCH_MOD_AMT   = 538
NRPN_VALUE_OSC_1_PITCH_MOD_RANGE = 539
NRPN_VALUE_OSC_1_WAVE            = 540
NRPN_VALUE_OSC_1_PULSE_WIDTH     = 541
NRPN_VALUE_OSC_1_PW_MOD_AMT      = 542
NRPN_VALUE_OSC_2_PITCH_COARSE    = 543
NRPN_VALUE_OSC_2_PITCH_FINE      = 544
NRPN_VALUE_OSC_2_MOD_MIX         = 545
NRPN_VALUE_OSC_2_PITCH_MOD_AMT   = 546
NRPN_VALUE_OSC_2_PITCH_MOD_RANGE = 547
NRPN_VALUE_OSC_2_WAVE            = 548
NRPN_VALUE_OSC_2_PULSE_WIDTH     = 549
NRPN_VALUE_OSC_2_PW_MOD_AMT      = 550
NRPN_VALUE_NOISE_1_LEVEL         = 551
NRPN_VALUE_NOISE_1_COLOR         = 552
NRPN_VALUE_MIXER_2_LEVEL_1       = 553
NRPN_VALUE_MIXER_2_LEVEL_2       = 554
NRPN_VALUE_MIXER_2_LEVEL_3       = 555
NRPN_VALUE_MIXER_2_OUT_LEVEL     = 556
NRPN_VALUE_FILTER_1_GAIN         = 557
NRPN_VALUE_FILTER_1_CUTOFF       = 558
NRPN_VALUE_FILTER_1_PITCH_AMT    = 559
NRPN_VALUE_FILTER_1_MOD_MIX      = 560
NRPN_VALUE_FILTER_1_MOD_AMT      = 561
NRPN_VALUE_FILTER_1_RESONANCE    = 562
NRPN_VALUE_FILTER_1_MODE         = 563
NRPN_VALUE_AMP_1_GAIN            = 564
NRPN_VALUE_CHORUS_1_MIX          = 565
NRPN_VALUE_CHORUS_1_RATE         = 566
NRPN_VALUE_CHORUS_1_DEPTH        = 567
NRPN_VALUE_DELAY_1_MIX           = 568
NRPN_VALUE_DELAY_1_TIME          = 569
NRPN_VALUE_DELAY_1_FEEDBACK      = 570

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

# The default patch, written into the NRPN table, and the values its CCs power up at. Each
# parameter's NRPN value is its power-up value too, which its slot holds while it has no CC.
def spms1_write_default_patch(midi_ch)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 0, MODULE_EG_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 1, MODULE_LFO_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 2, MODULE_MIXER_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 3, MODULE_PITCH_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 4, MODULE_OSC_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 5, MODULE_OSC_2)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 6, MODULE_NOISE_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 7, MODULE_MIXER_2)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 8, MODULE_FILTER_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 9, MODULE_AMP_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 10, MODULE_CHORUS_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 11, MODULE_DELAY_1)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_GATE      , SIGNAL_NOTE_GATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD, SIGNAL_GENERAL_MOD_WHEEL)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_1   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_2   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_3   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_PITCH  , SIGNAL_NOTE_PITCH)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND   , SIGNAL_PITCH_BEND)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH    , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_1    , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_2    , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH    , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_1    , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_2    , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_1   , SIGNAL_OSC_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_2   , SIGNAL_OSC_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_3   , SIGNAL_NOISE_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_AUDIO , SIGNAL_MIXER_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_PITCH , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1 , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2 , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_AUDIO    , SIGNAL_FILTER_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_MOD      , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_AUDIO , SIGNAL_AMP_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_L, SIGNAL_CHORUS_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_R, SIGNAL_CHORUS_1_OUTPUT_R)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_L       , SIGNAL_DELAY_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_R       , SIGNAL_DELAY_1_OUTPUT_R)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_ATTACK          , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_DECAY           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_SUSTAIN         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_RELEASE_SW      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_LEVEL           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_AMT   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_POL   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL          , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_WAVE           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_POL  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_1      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_2      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_3      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_OUT_LEVEL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_GLIDE        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_GLIDE_SW     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_COARSE       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_FINE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_STRETCH      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_AMT     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_POL     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_COARSE   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_FINE     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_MIX        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_AMT  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_RANGE, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_WAVE           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PULSE_WIDTH    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_AMT     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_COARSE   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_FINE     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_MIX        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_AMT  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_RANGE, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_WAVE           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PULSE_WIDTH    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_AMT     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_NOISE_1_LEVEL        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_NOISE_1_COLOR        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_1      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_2      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_3      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_OUT_LEVEL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_GAIN        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_CUTOFF      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_PITCH_AMT   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_MIX     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_AMT     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_RESONANCE   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MODE        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_GAIN           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_MIX         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_RATE        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_DEPTH       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_MIX          , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_TIME         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_FEEDBACK     , SIGNAL_OWN)

  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_ATTACK        , 73)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_DECAY         , 75)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_SUSTAIN       , 30)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_RELEASE_SW    , 105)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_RATE         , 3)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_LEVEL        , 113)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_WAVE         , 33)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_1_LEVEL_1    , 118)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_1_LEVEL_2    , 119)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_GLIDE      , 5)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_GLIDE_SW   , 34)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_COARSE     , 86)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_FINE       , 70)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_STRETCH    , 22)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_BEND_AMT   , 57)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_MOD_MIX      , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PITCH_MOD_AMT, 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_WAVE         , 102)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PULSE_WIDTH  , 114)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_AMT   , 103)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_COARSE , 85)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_FINE   , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_MOD_MIX      , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_MOD_AMT, 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_WAVE         , 104)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PULSE_WIDTH  , 114)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PW_MOD_AMT   , 103)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_NOISE_1_COLOR      , 115)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_1    , 116)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_2    , 21)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_3    , 23)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_GAIN      , 112)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_CUTOFF    , 74)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_PITCH_AMT , 9)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_MIX   , 25)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_AMT   , 117)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_RESONANCE , 71)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MODE      , 39)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_AMP_1_GAIN         , 15)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_MIX       , 93)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_RATE      , 58)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_DEPTH     , 59)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_MIX        , 94)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_TIME       , 90)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_FEEDBACK   , 92)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_MOD_WHEEL  , 1)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_1          , 16)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_2          , 17)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_3          , 18)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_4          , 19)

  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_ATTACK          , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_DECAY           , 94)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_SUSTAIN         , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_RELEASE_SW      , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_LEVEL           , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_RATE           , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_RATE_MOD_AMT   , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_RATE_MOD_POL   , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_LEVEL          , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_WAVE           , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_LEVEL_MOD_AMT  , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_LEVEL_MOD_POL  , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_1_LEVEL_1      , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_1_LEVEL_2      , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_1_LEVEL_3      , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_1_OUT_LEVEL    , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_GLIDE        , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_GLIDE_SW     , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_COARSE       , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_FINE         , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_STRETCH      , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_BEND_AMT     , 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_BEND_POL     , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_COARSE   , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_FINE     , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_MOD_MIX        , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_AMT  , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_RANGE, 28)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_WAVE           , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PULSE_WIDTH    , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PW_MOD_AMT     , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_COARSE   , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_FINE     , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_MOD_MIX        , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_AMT  , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_RANGE, 28)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_WAVE           , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PULSE_WIDTH    , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PW_MOD_AMT     , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_NOISE_1_LEVEL        , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_NOISE_1_COLOR        , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_LEVEL_1      , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_LEVEL_2      , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_LEVEL_3      , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_OUT_LEVEL    , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_GAIN        , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_CUTOFF      , 100)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_PITCH_AMT   , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MOD_MIX     , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MOD_AMT     , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_RESONANCE   , 94)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MODE        , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_AMP_1_GAIN           , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_CHORUS_1_MIX         , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_CHORUS_1_RATE        , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_CHORUS_1_DEPTH       , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_DELAY_1_MIX          , 34)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_DELAY_1_TIME         , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_DELAY_1_FEEDBACK     , 64)

  C.set_midi_cc_value(midi_ch, 73 , 4  ) # EG 1 Attack
  C.set_midi_cc_value(midi_ch, 75 , 94 ) # EG 1 Decay
  C.set_midi_cc_value(midi_ch, 30 , 124) # EG 1 Sustain
  C.set_midi_cc_value(midi_ch, 105, 124) # EG 1 Release Switch
  C.set_midi_cc_value(midi_ch, 3  , 64 ) # LFO 1 Rate
  C.set_midi_cc_value(midi_ch, 113, 124) # LFO 1 Level
  C.set_midi_cc_value(midi_ch, 33 , 4  ) # LFO 1 Wave
  C.set_midi_cc_value(midi_ch, 118, 4  ) # Mixer 1 Level 1
  C.set_midi_cc_value(midi_ch, 119, 4  ) # Mixer 1 Level 2
  C.set_midi_cc_value(midi_ch, 5  , 4  ) # Pitch 1 Glide
  C.set_midi_cc_value(midi_ch, 34 , 124) # Pitch 1 Glide Switch
  C.set_midi_cc_value(midi_ch, 86 , 64 ) # Pitch 1 Coarse
  C.set_midi_cc_value(midi_ch, 70 , 64 ) # Pitch 1 Fine
  C.set_midi_cc_value(midi_ch, 22 , 4  ) # Pitch 1 Stretch
  C.set_midi_cc_value(midi_ch, 57 , 8  ) # Pitch 1 Bend Amt
  C.set_midi_cc_value(midi_ch, 13 , 124) # Osc 1 Mod 1/2 Mix
  C.set_midi_cc_value(midi_ch, 8  , 4  ) # Osc 1 Pitch Mod Amt
  C.set_midi_cc_value(midi_ch, 102, 4  ) # Osc 1 Wave
  C.set_midi_cc_value(midi_ch, 114, 64 ) # Osc 1 Pulse Width
  C.set_midi_cc_value(midi_ch, 103, 4  ) # Osc 1 PW Mod Amt
  C.set_midi_cc_value(midi_ch, 85 , 64 ) # Osc 2 Pitch Coarse
  C.set_midi_cc_value(midi_ch, 76 , 76 ) # Osc 2 Pitch Fine
  C.set_midi_cc_value(midi_ch, 13 , 124) # Osc 2 Mod 1/2 Mix
  C.set_midi_cc_value(midi_ch, 8  , 4  ) # Osc 2 Pitch Mod Amt
  C.set_midi_cc_value(midi_ch, 104, 4  ) # Osc 2 Wave
  C.set_midi_cc_value(midi_ch, 114, 64 ) # Osc 2 Pulse Width
  C.set_midi_cc_value(midi_ch, 103, 4  ) # Osc 2 PW Mod Amt
  C.set_midi_cc_value(midi_ch, 115, 4  ) # Noise 1 Color
  C.set_midi_cc_value(midi_ch, 116, 124) # Mixer 2 Level 1
  C.set_midi_cc_value(midi_ch, 21 , 4  ) # Mixer 2 Level 2
  C.set_midi_cc_value(midi_ch, 23 , 4  ) # Mixer 2 Level 3
  C.set_midi_cc_value(midi_ch, 112, 64 ) # Filter 1 Gain
  C.set_midi_cc_value(midi_ch, 74 , 100) # Filter 1 Cutoff
  C.set_midi_cc_value(midi_ch, 9  , 4  ) # Filter 1 Pitch Amt
  C.set_midi_cc_value(midi_ch, 25 , 4  ) # Filter 1 Mod 1/2 Mix
  C.set_midi_cc_value(midi_ch, 117, 76 ) # Filter 1 Mod Amt
  C.set_midi_cc_value(midi_ch, 71 , 94 ) # Filter 1 Resonance
  C.set_midi_cc_value(midi_ch, 39 , 4  ) # Filter 1 Mode
  C.set_midi_cc_value(midi_ch, 15 , 124) # Amp 1 Gain
  C.set_midi_cc_value(midi_ch, 93 , 64 ) # Chorus 1 Mix
  C.set_midi_cc_value(midi_ch, 58 , 64 ) # Chorus 1 Rate
  C.set_midi_cc_value(midi_ch, 59 , 64 ) # Chorus 1 Depth
  C.set_midi_cc_value(midi_ch, 94 , 34 ) # Delay 1 Mix
  C.set_midi_cc_value(midi_ch, 90 , 64 ) # Delay 1 Time
  C.set_midi_cc_value(midi_ch, 92 , 64 ) # Delay 1 Feedback
  C.set_midi_cc_value(midi_ch, 1  , 4  ) # General Mod Wheel
  C.set_midi_cc_value(midi_ch, 16 , 64 ) # General 1
  C.set_midi_cc_value(midi_ch, 17 , 64 ) # General 2
  C.set_midi_cc_value(midi_ch, 18 , 64 ) # General 3
  C.set_midi_cc_value(midi_ch, 19 , 64 ) # General 4
end
