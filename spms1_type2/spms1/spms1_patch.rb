# Generated from spms1_patch.yaml by patch_gen/spms1_patch_gen.rb. Do not edit; change the YAML
# and run the generator.

# Module ids, the values of NRPN category 0. MODULE_NONE ends the run order.
MODULE_NONE     = 0
MODULE_PITCH_1  = 1
MODULE_EG_1     = 2
MODULE_EG_2     = 3
MODULE_LFO_1    = 4
MODULE_MIXER_1  = 5
MODULE_OSC_1    = 6
MODULE_OSC_2    = 7
MODULE_NOISE_1  = 8
MODULE_MIXER_2  = 9
MODULE_FILTER_1 = 10
MODULE_AMP_1    = 11
MODULE_CHORUS_1 = 12
MODULE_DELAY_1  = 13

# Slots of the signal bus, the values of NRPN categories 1 and 2.
SIGNAL_NONE                      = 0
SIGNAL_ONE                       = 1
SIGNAL_HALF                      = 2
SIGNAL_MINUS_HALF                = 3
SIGNAL_MINUS_ONE                 = 4
SIGNAL_NOTE_PITCH                = 5
SIGNAL_NOTE_GATE                 = 6
SIGNAL_PITCH_BEND                = 7
SIGNAL_MOD_WHEEL                 = 8
SIGNAL_GENERAL_1                 = 9
SIGNAL_GENERAL_1_REV             = 10
SIGNAL_GENERAL_1_INV             = 11
SIGNAL_GENERAL_1_REV_INV         = 12
SIGNAL_GENERAL_1_BIPOLAR         = 13
SIGNAL_GENERAL_1_BIPOLAR_INV     = 14
SIGNAL_GENERAL_2                 = 15
SIGNAL_GENERAL_2_REV             = 16
SIGNAL_GENERAL_2_INV             = 17
SIGNAL_GENERAL_2_REV_INV         = 18
SIGNAL_GENERAL_2_BIPOLAR         = 19
SIGNAL_GENERAL_2_BIPOLAR_INV     = 20
SIGNAL_PITCH_1_OUTPUT_1          = 21
SIGNAL_PITCH_1_OUTPUT_2          = 22
SIGNAL_EG_1_OUTPUT               = 23
SIGNAL_EG_1_OUTPUT_INV           = 24
SIGNAL_EG_2_OUTPUT               = 25
SIGNAL_EG_2_OUTPUT_INV           = 26
SIGNAL_LFO_1_OUTPUT              = 27
SIGNAL_LFO_1_OUTPUT_INV          = 28
SIGNAL_LFO_1_OUTPUT_TRIANGLE     = 29
SIGNAL_LFO_1_OUTPUT_TRIANGLE_INV = 30
SIGNAL_LFO_1_OUTPUT_SQUARE       = 31
SIGNAL_LFO_1_OUTPUT_SQUARE_INV   = 32
SIGNAL_MIXER_1_OUTPUT            = 33
SIGNAL_MIXER_1_OUTPUT_INV        = 34
SIGNAL_OSC_1_OUTPUT              = 35
SIGNAL_OSC_1_OUTPUT_SAW          = 36
SIGNAL_OSC_1_OUTPUT_PULSE        = 37
SIGNAL_OSC_1_OUTPUT_SUB          = 38
SIGNAL_OSC_2_OUTPUT              = 39
SIGNAL_OSC_2_OUTPUT_SAW          = 40
SIGNAL_OSC_2_OUTPUT_PULSE        = 41
SIGNAL_NOISE_1_OUTPUT            = 42
SIGNAL_NOISE_1_OUTPUT_WHITE      = 43
SIGNAL_NOISE_1_OUTPUT_RED        = 44
SIGNAL_MIXER_2_OUTPUT            = 45
SIGNAL_MIXER_2_OUTPUT_INV        = 46
SIGNAL_FILTER_1_OUTPUT           = 47
SIGNAL_FILTER_1_OUTPUT_LP        = 48
SIGNAL_FILTER_1_OUTPUT_HP        = 49
SIGNAL_FILTER_1_OUTPUT_BP        = 50
SIGNAL_AMP_1_OUTPUT              = 51
SIGNAL_CHORUS_1_OUTPUT_L         = 52
SIGNAL_CHORUS_1_OUTPUT_R         = 53
SIGNAL_CHORUS_1_OUTPUT_MONO      = 54
SIGNAL_DELAY_1_OUTPUT_L          = 55
SIGNAL_DELAY_1_OUTPUT_R          = 56
SIGNAL_DELAY_1_OUTPUT_MONO       = 57

# A parameter source of SIGNAL_OWN is the parameter's own control slot, at PARAM_SLOT_BASE + its
# entry, off the bus: the slots below.
SIGNAL_OWN      = 127
PARAM_SLOT_BASE = 128

SLOT_PITCH_1_GLIDE          = 128
SLOT_PITCH_1_OUT_1_GLIDE_SW = 129
SLOT_PITCH_1_OUT_2_GLIDE_SW = 130
SLOT_PITCH_1_BEND_AMT       = 131
SLOT_PITCH_1_OUT_1_BEND_SW  = 132
SLOT_PITCH_1_OUT_2_BEND_SW  = 133
SLOT_PITCH_1_STRETCH        = 134
SLOT_EG_1_ATTACK            = 135
SLOT_EG_1_DECAY             = 136
SLOT_EG_1_SUSTAIN           = 137
SLOT_EG_1_RELEASE_SW        = 138
SLOT_EG_1_LEVEL             = 139
SLOT_EG_2_ATTACK            = 140
SLOT_EG_2_DECAY             = 141
SLOT_EG_2_SUSTAIN           = 142
SLOT_EG_2_RELEASE_SW        = 143
SLOT_EG_2_LEVEL             = 144
SLOT_LFO_1_WAVE             = 145
SLOT_LFO_1_RATE             = 146
SLOT_LFO_1_LEVEL            = 147
SLOT_LFO_1_RATE_MOD_AMT     = 148
SLOT_LFO_1_LEVEL_MOD_AMT    = 149
SLOT_LFO_1_RESET_SW         = 150
SLOT_MIXER_1_LEVEL_1        = 151
SLOT_MIXER_1_LEVEL_2        = 152
SLOT_MIXER_1_LEVEL_3        = 153
SLOT_MIXER_1_LEVEL_4        = 154
SLOT_MIXER_1_OUT_LEVEL      = 155
SLOT_OSC_1_WAVE             = 156
SLOT_OSC_1_PW               = 157
SLOT_OSC_1_PITCH_COARSE     = 158
SLOT_OSC_1_PITCH_FINE       = 159
SLOT_OSC_1_PITCH_MOD_1_AMT  = 160
SLOT_OSC_1_PITCH_MOD_2_AMT  = 161
SLOT_OSC_1_PITCH_MOD_1_SW   = 162
SLOT_OSC_1_PITCH_MOD_2_SW   = 163
SLOT_OSC_1_PITCH_MOD_RANGE  = 164
SLOT_OSC_1_PW_MOD_1_AMT     = 165
SLOT_OSC_1_PW_MOD_2_AMT     = 166
SLOT_OSC_2_WAVE             = 167
SLOT_OSC_2_PW               = 168
SLOT_OSC_2_PITCH_COARSE     = 169
SLOT_OSC_2_PITCH_FINE       = 170
SLOT_OSC_2_PITCH_MOD_1_AMT  = 171
SLOT_OSC_2_PITCH_MOD_2_AMT  = 172
SLOT_OSC_2_PITCH_MOD_1_SW   = 173
SLOT_OSC_2_PITCH_MOD_2_SW   = 174
SLOT_OSC_2_PITCH_MOD_RANGE  = 175
SLOT_OSC_2_PW_MOD_1_AMT     = 176
SLOT_OSC_2_PW_MOD_2_AMT     = 177
SLOT_OSC_2_SYNC_SW          = 178
SLOT_NOISE_1_COLOR          = 179
SLOT_NOISE_1_LEVEL          = 180
SLOT_MIXER_2_LEVEL_1        = 181
SLOT_MIXER_2_LEVEL_2        = 182
SLOT_MIXER_2_LEVEL_3        = 183
SLOT_MIXER_2_LEVEL_4        = 184
SLOT_MIXER_2_OUT_LEVEL      = 185
SLOT_FILTER_1_CUTOFF        = 186
SLOT_FILTER_1_RESONANCE     = 187
SLOT_FILTER_1_MODE          = 188
SLOT_FILTER_1_PITCH_AMT     = 189
SLOT_FILTER_1_MOD_1_AMT     = 190
SLOT_FILTER_1_MOD_2_AMT     = 191
SLOT_FILTER_1_MOD_POLARITY  = 192
SLOT_AMP_1_GAIN             = 193
SLOT_AMP_1_MOD_1_2_MIX      = 194
SLOT_CHORUS_1_MIX           = 195
SLOT_CHORUS_1_RATE          = 196
SLOT_CHORUS_1_DEPTH         = 197
SLOT_DELAY_1_MIX            = 198
SLOT_DELAY_1_TIME           = 199
SLOT_DELAY_1_FEEDBACK       = 200

# NRPN parameter numbers: (MSB << 7) | LSB, where the MSB picks a category and the LSB an entry.
#   0..127   active_modules[slot]
# 128..255   what feeds each module input
# 256..383   where each parameter's value comes from
# 384..511   which CC fills each control slot
# 512..639   the value of each parameter's control slot while it has no CC
NRPN_ACTIVE_MODULE_BASE = 0

NRPN_SOURCE_PITCH_1_PITCH   = 128
NRPN_SOURCE_PITCH_1_BEND    = 129
NRPN_SOURCE_PITCH_1_GATE    = 130
NRPN_SOURCE_EG_1_GATE       = 131
NRPN_SOURCE_EG_2_GATE       = 132
NRPN_SOURCE_LFO_1_RATE_MOD  = 133
NRPN_SOURCE_LFO_1_LEVEL_MOD = 134
NRPN_SOURCE_LFO_1_RESET     = 135
NRPN_SOURCE_MIXER_1_IN_1    = 136
NRPN_SOURCE_MIXER_1_IN_2    = 137
NRPN_SOURCE_MIXER_1_IN_3    = 138
NRPN_SOURCE_MIXER_1_IN_4    = 139
NRPN_SOURCE_OSC_1_PITCH     = 140
NRPN_SOURCE_OSC_1_MOD_1     = 141
NRPN_SOURCE_OSC_1_MOD_2     = 142
NRPN_SOURCE_OSC_2_PITCH     = 143
NRPN_SOURCE_OSC_2_MOD_1     = 144
NRPN_SOURCE_OSC_2_MOD_2     = 145
NRPN_SOURCE_OSC_2_SYNC      = 146
NRPN_SOURCE_MIXER_2_IN_1    = 147
NRPN_SOURCE_MIXER_2_IN_2    = 148
NRPN_SOURCE_MIXER_2_IN_3    = 149
NRPN_SOURCE_MIXER_2_IN_4    = 150
NRPN_SOURCE_FILTER_1_AUDIO  = 151
NRPN_SOURCE_FILTER_1_PITCH  = 152
NRPN_SOURCE_FILTER_1_MOD_1  = 153
NRPN_SOURCE_FILTER_1_MOD_2  = 154
NRPN_SOURCE_AMP_1_AUDIO     = 155
NRPN_SOURCE_AMP_1_MOD_1     = 156
NRPN_SOURCE_AMP_1_MOD_2     = 157
NRPN_SOURCE_CHORUS_1_AUDIO  = 158
NRPN_SOURCE_DELAY_1_AUDIO_L = 159
NRPN_SOURCE_DELAY_1_AUDIO_R = 160
NRPN_SOURCE_OUTPUT_L        = 161
NRPN_SOURCE_OUTPUT_R        = 162

NRPN_SOURCE_PITCH_1_GLIDE          = 256
NRPN_SOURCE_PITCH_1_OUT_1_GLIDE_SW = 257
NRPN_SOURCE_PITCH_1_OUT_2_GLIDE_SW = 258
NRPN_SOURCE_PITCH_1_BEND_AMT       = 259
NRPN_SOURCE_PITCH_1_OUT_1_BEND_SW  = 260
NRPN_SOURCE_PITCH_1_OUT_2_BEND_SW  = 261
NRPN_SOURCE_PITCH_1_STRETCH        = 262
NRPN_SOURCE_EG_1_ATTACK            = 263
NRPN_SOURCE_EG_1_DECAY             = 264
NRPN_SOURCE_EG_1_SUSTAIN           = 265
NRPN_SOURCE_EG_1_RELEASE_SW        = 266
NRPN_SOURCE_EG_1_LEVEL             = 267
NRPN_SOURCE_EG_2_ATTACK            = 268
NRPN_SOURCE_EG_2_DECAY             = 269
NRPN_SOURCE_EG_2_SUSTAIN           = 270
NRPN_SOURCE_EG_2_RELEASE_SW        = 271
NRPN_SOURCE_EG_2_LEVEL             = 272
NRPN_SOURCE_LFO_1_WAVE             = 273
NRPN_SOURCE_LFO_1_RATE             = 274
NRPN_SOURCE_LFO_1_LEVEL            = 275
NRPN_SOURCE_LFO_1_RATE_MOD_AMT     = 276
NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT    = 277
NRPN_SOURCE_LFO_1_RESET_SW         = 278
NRPN_SOURCE_MIXER_1_LEVEL_1        = 279
NRPN_SOURCE_MIXER_1_LEVEL_2        = 280
NRPN_SOURCE_MIXER_1_LEVEL_3        = 281
NRPN_SOURCE_MIXER_1_LEVEL_4        = 282
NRPN_SOURCE_MIXER_1_OUT_LEVEL      = 283
NRPN_SOURCE_OSC_1_WAVE             = 284
NRPN_SOURCE_OSC_1_PW               = 285
NRPN_SOURCE_OSC_1_PITCH_COARSE     = 286
NRPN_SOURCE_OSC_1_PITCH_FINE       = 287
NRPN_SOURCE_OSC_1_PITCH_MOD_1_AMT  = 288
NRPN_SOURCE_OSC_1_PITCH_MOD_2_AMT  = 289
NRPN_SOURCE_OSC_1_PITCH_MOD_1_SW   = 290
NRPN_SOURCE_OSC_1_PITCH_MOD_2_SW   = 291
NRPN_SOURCE_OSC_1_PITCH_MOD_RANGE  = 292
NRPN_SOURCE_OSC_1_PW_MOD_1_AMT     = 293
NRPN_SOURCE_OSC_1_PW_MOD_2_AMT     = 294
NRPN_SOURCE_OSC_2_WAVE             = 295
NRPN_SOURCE_OSC_2_PW               = 296
NRPN_SOURCE_OSC_2_PITCH_COARSE     = 297
NRPN_SOURCE_OSC_2_PITCH_FINE       = 298
NRPN_SOURCE_OSC_2_PITCH_MOD_1_AMT  = 299
NRPN_SOURCE_OSC_2_PITCH_MOD_2_AMT  = 300
NRPN_SOURCE_OSC_2_PITCH_MOD_1_SW   = 301
NRPN_SOURCE_OSC_2_PITCH_MOD_2_SW   = 302
NRPN_SOURCE_OSC_2_PITCH_MOD_RANGE  = 303
NRPN_SOURCE_OSC_2_PW_MOD_1_AMT     = 304
NRPN_SOURCE_OSC_2_PW_MOD_2_AMT     = 305
NRPN_SOURCE_OSC_2_SYNC_SW          = 306
NRPN_SOURCE_NOISE_1_COLOR          = 307
NRPN_SOURCE_NOISE_1_LEVEL          = 308
NRPN_SOURCE_MIXER_2_LEVEL_1        = 309
NRPN_SOURCE_MIXER_2_LEVEL_2        = 310
NRPN_SOURCE_MIXER_2_LEVEL_3        = 311
NRPN_SOURCE_MIXER_2_LEVEL_4        = 312
NRPN_SOURCE_MIXER_2_OUT_LEVEL      = 313
NRPN_SOURCE_FILTER_1_CUTOFF        = 314
NRPN_SOURCE_FILTER_1_RESONANCE     = 315
NRPN_SOURCE_FILTER_1_MODE          = 316
NRPN_SOURCE_FILTER_1_PITCH_AMT     = 317
NRPN_SOURCE_FILTER_1_MOD_1_AMT     = 318
NRPN_SOURCE_FILTER_1_MOD_2_AMT     = 319
NRPN_SOURCE_FILTER_1_MOD_POLARITY  = 320
NRPN_SOURCE_AMP_1_GAIN             = 321
NRPN_SOURCE_AMP_1_MOD_1_2_MIX      = 322
NRPN_SOURCE_CHORUS_1_MIX           = 323
NRPN_SOURCE_CHORUS_1_RATE          = 324
NRPN_SOURCE_CHORUS_1_DEPTH         = 325
NRPN_SOURCE_DELAY_1_MIX            = 326
NRPN_SOURCE_DELAY_1_TIME           = 327
NRPN_SOURCE_DELAY_1_FEEDBACK       = 328

# A CC number of 0 means the control has no CC: a parameter's control slot then holds its NRPN_VALUE_*
# below, whatever CC it had before, so a patch sets it alone, and a controller slot holds 0.0.
NRPN_CC_PITCH_1_GLIDE          = 384
NRPN_CC_PITCH_1_OUT_1_GLIDE_SW = 385
NRPN_CC_PITCH_1_OUT_2_GLIDE_SW = 386
NRPN_CC_PITCH_1_BEND_AMT       = 387
NRPN_CC_PITCH_1_OUT_1_BEND_SW  = 388
NRPN_CC_PITCH_1_OUT_2_BEND_SW  = 389
NRPN_CC_PITCH_1_STRETCH        = 390
NRPN_CC_EG_1_ATTACK            = 391
NRPN_CC_EG_1_DECAY             = 392
NRPN_CC_EG_1_SUSTAIN           = 393
NRPN_CC_EG_1_RELEASE_SW        = 394
NRPN_CC_EG_1_LEVEL             = 395
NRPN_CC_EG_2_ATTACK            = 396
NRPN_CC_EG_2_DECAY             = 397
NRPN_CC_EG_2_SUSTAIN           = 398
NRPN_CC_EG_2_RELEASE_SW        = 399
NRPN_CC_EG_2_LEVEL             = 400
NRPN_CC_LFO_1_WAVE             = 401
NRPN_CC_LFO_1_RATE             = 402
NRPN_CC_LFO_1_LEVEL            = 403
NRPN_CC_LFO_1_RATE_MOD_AMT     = 404
NRPN_CC_LFO_1_LEVEL_MOD_AMT    = 405
NRPN_CC_LFO_1_RESET_SW         = 406
NRPN_CC_MIXER_1_LEVEL_1        = 407
NRPN_CC_MIXER_1_LEVEL_2        = 408
NRPN_CC_MIXER_1_LEVEL_3        = 409
NRPN_CC_MIXER_1_LEVEL_4        = 410
NRPN_CC_MIXER_1_OUT_LEVEL      = 411
NRPN_CC_OSC_1_WAVE             = 412
NRPN_CC_OSC_1_PW               = 413
NRPN_CC_OSC_1_PITCH_COARSE     = 414
NRPN_CC_OSC_1_PITCH_FINE       = 415
NRPN_CC_OSC_1_PITCH_MOD_1_AMT  = 416
NRPN_CC_OSC_1_PITCH_MOD_2_AMT  = 417
NRPN_CC_OSC_1_PITCH_MOD_1_SW   = 418
NRPN_CC_OSC_1_PITCH_MOD_2_SW   = 419
NRPN_CC_OSC_1_PITCH_MOD_RANGE  = 420
NRPN_CC_OSC_1_PW_MOD_1_AMT     = 421
NRPN_CC_OSC_1_PW_MOD_2_AMT     = 422
NRPN_CC_OSC_2_WAVE             = 423
NRPN_CC_OSC_2_PW               = 424
NRPN_CC_OSC_2_PITCH_COARSE     = 425
NRPN_CC_OSC_2_PITCH_FINE       = 426
NRPN_CC_OSC_2_PITCH_MOD_1_AMT  = 427
NRPN_CC_OSC_2_PITCH_MOD_2_AMT  = 428
NRPN_CC_OSC_2_PITCH_MOD_1_SW   = 429
NRPN_CC_OSC_2_PITCH_MOD_2_SW   = 430
NRPN_CC_OSC_2_PITCH_MOD_RANGE  = 431
NRPN_CC_OSC_2_PW_MOD_1_AMT     = 432
NRPN_CC_OSC_2_PW_MOD_2_AMT     = 433
NRPN_CC_OSC_2_SYNC_SW          = 434
NRPN_CC_NOISE_1_COLOR          = 435
NRPN_CC_NOISE_1_LEVEL          = 436
NRPN_CC_MIXER_2_LEVEL_1        = 437
NRPN_CC_MIXER_2_LEVEL_2        = 438
NRPN_CC_MIXER_2_LEVEL_3        = 439
NRPN_CC_MIXER_2_LEVEL_4        = 440
NRPN_CC_MIXER_2_OUT_LEVEL      = 441
NRPN_CC_FILTER_1_CUTOFF        = 442
NRPN_CC_FILTER_1_RESONANCE     = 443
NRPN_CC_FILTER_1_MODE          = 444
NRPN_CC_FILTER_1_PITCH_AMT     = 445
NRPN_CC_FILTER_1_MOD_1_AMT     = 446
NRPN_CC_FILTER_1_MOD_2_AMT     = 447
NRPN_CC_FILTER_1_MOD_POLARITY  = 448
NRPN_CC_AMP_1_GAIN             = 449
NRPN_CC_AMP_1_MOD_1_2_MIX      = 450
NRPN_CC_CHORUS_1_MIX           = 451
NRPN_CC_CHORUS_1_RATE          = 452
NRPN_CC_CHORUS_1_DEPTH         = 453
NRPN_CC_DELAY_1_MIX            = 454
NRPN_CC_DELAY_1_TIME           = 455
NRPN_CC_DELAY_1_FEEDBACK       = 456
NRPN_CC_MOD_WHEEL              = 457
NRPN_CC_GENERAL_1              = 458
NRPN_CC_GENERAL_2              = 459

# The value of each parameter's control slot while it has no CC, as a CC value.
NRPN_VALUE_PITCH_1_GLIDE          = 512
NRPN_VALUE_PITCH_1_OUT_1_GLIDE_SW = 513
NRPN_VALUE_PITCH_1_OUT_2_GLIDE_SW = 514
NRPN_VALUE_PITCH_1_BEND_AMT       = 515
NRPN_VALUE_PITCH_1_OUT_1_BEND_SW  = 516
NRPN_VALUE_PITCH_1_OUT_2_BEND_SW  = 517
NRPN_VALUE_PITCH_1_STRETCH        = 518
NRPN_VALUE_EG_1_ATTACK            = 519
NRPN_VALUE_EG_1_DECAY             = 520
NRPN_VALUE_EG_1_SUSTAIN           = 521
NRPN_VALUE_EG_1_RELEASE_SW        = 522
NRPN_VALUE_EG_1_LEVEL             = 523
NRPN_VALUE_EG_2_ATTACK            = 524
NRPN_VALUE_EG_2_DECAY             = 525
NRPN_VALUE_EG_2_SUSTAIN           = 526
NRPN_VALUE_EG_2_RELEASE_SW        = 527
NRPN_VALUE_EG_2_LEVEL             = 528
NRPN_VALUE_LFO_1_WAVE             = 529
NRPN_VALUE_LFO_1_RATE             = 530
NRPN_VALUE_LFO_1_LEVEL            = 531
NRPN_VALUE_LFO_1_RATE_MOD_AMT     = 532
NRPN_VALUE_LFO_1_LEVEL_MOD_AMT    = 533
NRPN_VALUE_LFO_1_RESET_SW         = 534
NRPN_VALUE_MIXER_1_LEVEL_1        = 535
NRPN_VALUE_MIXER_1_LEVEL_2        = 536
NRPN_VALUE_MIXER_1_LEVEL_3        = 537
NRPN_VALUE_MIXER_1_LEVEL_4        = 538
NRPN_VALUE_MIXER_1_OUT_LEVEL      = 539
NRPN_VALUE_OSC_1_WAVE             = 540
NRPN_VALUE_OSC_1_PW               = 541
NRPN_VALUE_OSC_1_PITCH_COARSE     = 542
NRPN_VALUE_OSC_1_PITCH_FINE       = 543
NRPN_VALUE_OSC_1_PITCH_MOD_1_AMT  = 544
NRPN_VALUE_OSC_1_PITCH_MOD_2_AMT  = 545
NRPN_VALUE_OSC_1_PITCH_MOD_1_SW   = 546
NRPN_VALUE_OSC_1_PITCH_MOD_2_SW   = 547
NRPN_VALUE_OSC_1_PITCH_MOD_RANGE  = 548
NRPN_VALUE_OSC_1_PW_MOD_1_AMT     = 549
NRPN_VALUE_OSC_1_PW_MOD_2_AMT     = 550
NRPN_VALUE_OSC_2_WAVE             = 551
NRPN_VALUE_OSC_2_PW               = 552
NRPN_VALUE_OSC_2_PITCH_COARSE     = 553
NRPN_VALUE_OSC_2_PITCH_FINE       = 554
NRPN_VALUE_OSC_2_PITCH_MOD_1_AMT  = 555
NRPN_VALUE_OSC_2_PITCH_MOD_2_AMT  = 556
NRPN_VALUE_OSC_2_PITCH_MOD_1_SW   = 557
NRPN_VALUE_OSC_2_PITCH_MOD_2_SW   = 558
NRPN_VALUE_OSC_2_PITCH_MOD_RANGE  = 559
NRPN_VALUE_OSC_2_PW_MOD_1_AMT     = 560
NRPN_VALUE_OSC_2_PW_MOD_2_AMT     = 561
NRPN_VALUE_OSC_2_SYNC_SW          = 562
NRPN_VALUE_NOISE_1_COLOR          = 563
NRPN_VALUE_NOISE_1_LEVEL          = 564
NRPN_VALUE_MIXER_2_LEVEL_1        = 565
NRPN_VALUE_MIXER_2_LEVEL_2        = 566
NRPN_VALUE_MIXER_2_LEVEL_3        = 567
NRPN_VALUE_MIXER_2_LEVEL_4        = 568
NRPN_VALUE_MIXER_2_OUT_LEVEL      = 569
NRPN_VALUE_FILTER_1_CUTOFF        = 570
NRPN_VALUE_FILTER_1_RESONANCE     = 571
NRPN_VALUE_FILTER_1_MODE          = 572
NRPN_VALUE_FILTER_1_PITCH_AMT     = 573
NRPN_VALUE_FILTER_1_MOD_1_AMT     = 574
NRPN_VALUE_FILTER_1_MOD_2_AMT     = 575
NRPN_VALUE_FILTER_1_MOD_POLARITY  = 576
NRPN_VALUE_AMP_1_GAIN             = 577
NRPN_VALUE_AMP_1_MOD_1_2_MIX      = 578
NRPN_VALUE_CHORUS_1_MIX           = 579
NRPN_VALUE_CHORUS_1_RATE          = 580
NRPN_VALUE_CHORUS_1_DEPTH         = 581
NRPN_VALUE_DELAY_1_MIX            = 582
NRPN_VALUE_DELAY_1_TIME           = 583
NRPN_VALUE_DELAY_1_FEEDBACK       = 584

# The constants of the bus, which nothing else ever writes. A slot not written here holds 0.0.
def spms1_fill_constant_signals(signals)
  signals[SIGNAL_ONE]        =  1.0
  signals[SIGNAL_HALF]       =  0.5
  signals[SIGNAL_MINUS_HALF] = -0.5
  signals[SIGNAL_MINUS_ONE]  = -1.0
end

# The default patch, written into the NRPN table, and the values its CCs power up at. Each
# parameter's NRPN value is its power-up value too, which its slot holds while it has no CC.
def spms1_write_default_patch(midi_ch)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 0, MODULE_PITCH_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 1, MODULE_EG_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 2, MODULE_EG_2)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 3, MODULE_LFO_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 4, MODULE_MIXER_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 5, MODULE_OSC_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 6, MODULE_OSC_2)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 7, MODULE_NOISE_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 8, MODULE_MIXER_2)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 9, MODULE_FILTER_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 10, MODULE_AMP_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 11, MODULE_CHORUS_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 12, MODULE_DELAY_1)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_PITCH  , SIGNAL_NOTE_PITCH)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND   , SIGNAL_PITCH_BEND)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_GATE   , SIGNAL_NOTE_GATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_GATE      , SIGNAL_NOTE_GATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_2_GATE      , SIGNAL_NOTE_GATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD, SIGNAL_MOD_WHEEL)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RESET    , SIGNAL_NOTE_GATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_1   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_2   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_3   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_4   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH    , SIGNAL_PITCH_1_OUTPUT_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_1    , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_2    , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH    , SIGNAL_PITCH_1_OUTPUT_2)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_1    , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_2    , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_SYNC     , SIGNAL_OSC_1_OUTPUT_SAW)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_1   , SIGNAL_OSC_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_2   , SIGNAL_OSC_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_3   , SIGNAL_OSC_1_OUTPUT_SUB)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_4   , SIGNAL_NOISE_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_AUDIO , SIGNAL_MIXER_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_PITCH , SIGNAL_PITCH_1_OUTPUT_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1 , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2 , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_AUDIO    , SIGNAL_FILTER_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_MOD_1    , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_MOD_2    , SIGNAL_EG_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_AUDIO , SIGNAL_AMP_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_L, SIGNAL_CHORUS_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_R, SIGNAL_CHORUS_1_OUTPUT_R)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_L       , SIGNAL_DELAY_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_R       , SIGNAL_DELAY_1_OUTPUT_R)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_GLIDE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_OUT_1_GLIDE_SW, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_OUT_2_GLIDE_SW, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_AMT      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_OUT_1_BEND_SW , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_OUT_2_BEND_SW , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_STRETCH       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_ATTACK           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_DECAY            , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_SUSTAIN          , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_RELEASE_SW       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_LEVEL            , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_2_ATTACK           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_2_DECAY            , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_2_SUSTAIN          , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_2_RELEASE_SW       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_2_LEVEL            , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_WAVE            , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE            , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RESET_SW        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_1       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_2       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_3       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_4       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_OUT_LEVEL     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_WAVE            , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW              , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_COARSE    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_FINE      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_1_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_2_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_1_SW  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_2_SW  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_RANGE , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_1_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_2_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_WAVE            , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW              , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_COARSE    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_FINE      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_1_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_2_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_1_SW  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_2_SW  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_RANGE , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_1_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_2_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_SYNC_SW         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_NOISE_1_COLOR         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_NOISE_1_LEVEL         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_1       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_2       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_3       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_4       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_OUT_LEVEL     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_CUTOFF       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_RESONANCE    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MODE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_PITCH_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_POLARITY , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_GAIN            , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_MOD_1_2_MIX     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_MIX          , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_RATE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_DEPTH        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_MIX           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_TIME          , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_FEEDBACK      , SIGNAL_OWN)

  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_GLIDE         , 5)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_OUT_1_GLIDE_SW, 34)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_OUT_2_GLIDE_SW, 34)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_BEND_AMT      , 57)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_STRETCH       , 22)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_ATTACK           , 73)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_DECAY            , 75)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_SUSTAIN          , 30)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_RELEASE_SW       , 105)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_2_ATTACK           , 52)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_2_DECAY            , 53)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_2_SUSTAIN          , 54)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_2_RELEASE_SW       , 105)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_WAVE            , 33)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_RATE            , 3)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_LEVEL           , 116)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_RESET_SW        , 113)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_WAVE            , 102)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW              , 114)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PITCH_MOD_1_AMT , 89)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PITCH_MOD_2_AMT , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_1_AMT    , 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_2_AMT    , 103)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_WAVE            , 104)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PW              , 114)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_COARSE    , 85)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_FINE      , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_MOD_1_AMT , 89)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_MOD_2_AMT , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PW_MOD_1_AMT    , 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PW_MOD_2_AMT    , 103)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_SYNC_SW         , 112)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_NOISE_1_COLOR         , 115)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_1       , 19)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_2       , 20)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_3       , 21)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_4       , 23)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_CUTOFF       , 74)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_RESONANCE    , 71)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MODE         , 39)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_PITCH_AMT    , 9)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_1_AMT    , 24)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_2_AMT    , 25)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_POLARITY , 51)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_AMP_1_GAIN            , 15)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_AMP_1_MOD_1_2_MIX     , 36)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_MIX          , 93)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_RATE         , 58)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_DEPTH        , 59)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_MIX           , 94)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_TIME          , 90)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_FEEDBACK      , 92)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MOD_WHEEL             , 1)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_1             , 16)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_2             , 17)

  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_GLIDE         , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_OUT_1_GLIDE_SW, 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_OUT_2_GLIDE_SW, 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_BEND_AMT      , 28)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_OUT_1_BEND_SW , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_OUT_2_BEND_SW , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_STRETCH       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_ATTACK           , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_DECAY            , 100)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_SUSTAIN          , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_RELEASE_SW       , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_LEVEL            , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_2_ATTACK           , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_2_DECAY            , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_2_SUSTAIN          , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_2_RELEASE_SW       , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_2_LEVEL            , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_WAVE            , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_RATE            , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_LEVEL           , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_RATE_MOD_AMT    , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_LEVEL_MOD_AMT   , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_RESET_SW        , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_1_LEVEL_1       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_1_LEVEL_2       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_1_LEVEL_3       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_1_LEVEL_4       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_1_OUT_LEVEL     , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_WAVE            , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PW              , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_COARSE    , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_FINE      , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_1_AMT , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_2_AMT , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_1_SW  , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_2_SW  , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_RANGE , 28)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PW_MOD_1_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PW_MOD_2_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_WAVE            , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PW              , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_COARSE    , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_FINE      , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_1_AMT , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_2_AMT , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_1_SW  , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_2_SW  , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_RANGE , 28)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PW_MOD_1_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PW_MOD_2_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_SYNC_SW         , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_NOISE_1_COLOR         , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_NOISE_1_LEVEL         , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_LEVEL_1       , 88)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_LEVEL_2       , 88)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_LEVEL_3       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_LEVEL_4       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_OUT_LEVEL     , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_CUTOFF       , 112)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_RESONANCE    , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MODE         , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_PITCH_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MOD_1_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MOD_2_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MOD_POLARITY , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_AMP_1_GAIN            , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_AMP_1_MOD_1_2_MIX     , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_CHORUS_1_MIX          , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_CHORUS_1_RATE         , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_CHORUS_1_DEPTH        , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_DELAY_1_MIX           , 34)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_DELAY_1_TIME          , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_DELAY_1_FEEDBACK      , 64)

  C.set_midi_cc_value(midi_ch, 5  , 4  ) # Pitch 1 Glide
  C.set_midi_cc_value(midi_ch, 34 , 124) # Pitch 1 Out 1 Glide Switch
  C.set_midi_cc_value(midi_ch, 34 , 124) # Pitch 1 Out 2 Glide Switch
  C.set_midi_cc_value(midi_ch, 57 , 28 ) # Pitch 1 Bend Amt
  C.set_midi_cc_value(midi_ch, 22 , 4  ) # Pitch 1 Stretch
  C.set_midi_cc_value(midi_ch, 73 , 4  ) # EG 1 Attack
  C.set_midi_cc_value(midi_ch, 75 , 100) # EG 1 Decay
  C.set_midi_cc_value(midi_ch, 30 , 124) # EG 1 Sustain
  C.set_midi_cc_value(midi_ch, 105, 124) # EG 1 Release Switch
  C.set_midi_cc_value(midi_ch, 52 , 4  ) # EG 2 Attack
  C.set_midi_cc_value(midi_ch, 53 , 4  ) # EG 2 Decay
  C.set_midi_cc_value(midi_ch, 54 , 124) # EG 2 Sustain
  C.set_midi_cc_value(midi_ch, 105, 124) # EG 2 Release Switch
  C.set_midi_cc_value(midi_ch, 33 , 4  ) # LFO 1 Wave
  C.set_midi_cc_value(midi_ch, 3  , 64 ) # LFO 1 Rate
  C.set_midi_cc_value(midi_ch, 116, 4  ) # LFO 1 Level
  C.set_midi_cc_value(midi_ch, 113, 4  ) # LFO 1 Reset Switch
  C.set_midi_cc_value(midi_ch, 102, 4  ) # Osc 1 Wave
  C.set_midi_cc_value(midi_ch, 114, 64 ) # Osc 1 PW
  C.set_midi_cc_value(midi_ch, 89 , 4  ) # Osc 1 Pitch Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 13 , 124) # Osc 1 Pitch Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 8  , 4  ) # Osc 1 PW Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 103, 4  ) # Osc 1 PW Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 104, 4  ) # Osc 2 Wave
  C.set_midi_cc_value(midi_ch, 114, 64 ) # Osc 2 PW
  C.set_midi_cc_value(midi_ch, 85 , 64 ) # Osc 2 Pitch Coarse
  C.set_midi_cc_value(midi_ch, 76 , 76 ) # Osc 2 Pitch Fine
  C.set_midi_cc_value(midi_ch, 89 , 4  ) # Osc 2 Pitch Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 13 , 124) # Osc 2 Pitch Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 8  , 4  ) # Osc 2 PW Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 103, 4  ) # Osc 2 PW Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 112, 4  ) # Osc 2 Sync Switch
  C.set_midi_cc_value(midi_ch, 115, 4  ) # Noise 1 Color
  C.set_midi_cc_value(midi_ch, 19 , 88 ) # Mixer 2 Level 1
  C.set_midi_cc_value(midi_ch, 20 , 88 ) # Mixer 2 Level 2
  C.set_midi_cc_value(midi_ch, 21 , 4  ) # Mixer 2 Level 3
  C.set_midi_cc_value(midi_ch, 23 , 4  ) # Mixer 2 Level 4
  C.set_midi_cc_value(midi_ch, 74 , 112) # Filter 1 Cutoff
  C.set_midi_cc_value(midi_ch, 71 , 64 ) # Filter 1 Resonance
  C.set_midi_cc_value(midi_ch, 39 , 4  ) # Filter 1 Mode
  C.set_midi_cc_value(midi_ch, 9  , 4  ) # Filter 1 Pitch Amt
  C.set_midi_cc_value(midi_ch, 24 , 4  ) # Filter 1 Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 25 , 4  ) # Filter 1 Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 51 , 124) # Filter 1 Mod Polarity
  C.set_midi_cc_value(midi_ch, 15 , 64 ) # Amp 1 Gain
  C.set_midi_cc_value(midi_ch, 36 , 4  ) # Amp 1 Mod 1/2 Mix
  C.set_midi_cc_value(midi_ch, 93 , 64 ) # Chorus 1 Mix
  C.set_midi_cc_value(midi_ch, 58 , 64 ) # Chorus 1 Rate
  C.set_midi_cc_value(midi_ch, 59 , 64 ) # Chorus 1 Depth
  C.set_midi_cc_value(midi_ch, 94 , 34 ) # Delay 1 Mix
  C.set_midi_cc_value(midi_ch, 90 , 64 ) # Delay 1 Time
  C.set_midi_cc_value(midi_ch, 92 , 64 ) # Delay 1 Feedback
  C.set_midi_cc_value(midi_ch, 1  , 4  ) # Mod Wheel
  C.set_midi_cc_value(midi_ch, 16 , 4  ) # General 1
  C.set_midi_cc_value(midi_ch, 17 , 4  ) # General 2
end
