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
SIGNAL_NONE                  = 0
SIGNAL_ONE                   = 1
SIGNAL_HALF                  = 2
SIGNAL_POINT_TWO             = 3
SIGNAL_POINT_ONE             = 4
SIGNAL_MINUS_POINT_ONE       = 5
SIGNAL_MINUS_POINT_TWO       = 6
SIGNAL_MINUS_HALF            = 7
SIGNAL_MINUS_ONE             = 8
SIGNAL_SQRT_HALF             = 125
SIGNAL_LFO_1_OUTPUT          = 9
SIGNAL_EG_1_OUTPUT           = 10
SIGNAL_OSC_1_OUTPUT          = 11
SIGNAL_FILTER_1_OUTPUT       = 12
SIGNAL_AMP_1_OUTPUT          = 13
SIGNAL_MIXER_1_OUTPUT        = 14
SIGNAL_CHORUS_1_OUTPUT_L     = 15
SIGNAL_CHORUS_1_OUTPUT_R     = 16
SIGNAL_DELAY_1_OUTPUT_L      = 17
SIGNAL_DELAY_1_OUTPUT_R      = 18
SIGNAL_NOTE_PITCH            = 48
SIGNAL_NOTE_GATE             = 49
SIGNAL_PITCH_BEND            = 50
SIGNAL_GENERAL_MOD_WHEEL     = 51
SIGNAL_GENERAL_UNIPOLAR_1    = 52
SIGNAL_GENERAL_UNIPOLAR_2    = 53
SIGNAL_GENERAL_UNIPOLAR_3    = 54
SIGNAL_GENERAL_UNIPOLAR_4    = 55
SIGNAL_GENERAL_BIPOLAR_1     = 56
SIGNAL_GENERAL_BIPOLAR_2     = 57
SIGNAL_GENERAL_BIPOLAR_3     = 58
SIGNAL_GENERAL_BIPOLAR_4     = 59
SIGNAL_PITCH_1_OUTPUT        = 60
SIGNAL_FILTER_1_OUTPUT_LP    = 117
SIGNAL_FILTER_1_OUTPUT_HP    = 66
SIGNAL_NOISE_1_OUTPUT        = 86
SIGNAL_OSC_2_OUTPUT          = 88
SIGNAL_MIXER_2_OUTPUT        = 106
SIGNAL_NOISE_1_OUTPUT_WHITE  = 122
SIGNAL_NOISE_1_OUTPUT_RED    = 116
SIGNAL_OSC_1_OUTPUT_SAW      = 118
SIGNAL_OSC_1_OUTPUT_PULSE    = 119
SIGNAL_OSC_2_OUTPUT_SAW      = 120
SIGNAL_OSC_2_OUTPUT_PULSE    = 121
SIGNAL_LFO_1_OUTPUT_TRIANGLE = 123
SIGNAL_LFO_1_OUTPUT_SQUARE   = 124
SIGNAL_CHORUS_1_OUTPUT_MONO  = 126
SIGNAL_DELAY_1_OUTPUT_MONO   = 19

# A parameter source of SIGNAL_OWN is the parameter's own control slot, at PARAM_SLOT_BASE + its
# entry, off the bus: the slots below.
SIGNAL_OWN      = 127
PARAM_SLOT_BASE = 128

SLOT_LFO_1_RATE          = 128
SLOT_LFO_1_LEVEL         = 129
SLOT_EG_1_ATTACK         = 131
SLOT_EG_1_DECAY          = 132
SLOT_EG_1_SUSTAIN        = 133
SLOT_EG_1_LEVEL          = 134
SLOT_OSC_1_WAVE          = 136
SLOT_OSC_1_PITCH_COARSE  = 137
SLOT_OSC_1_PITCH_FINE    = 138
SLOT_OSC_1_MOD_2_AMT     = 139
SLOT_OSC_1_MOD_2_POL     = 140
SLOT_FILTER_1_CUTOFF     = 141
SLOT_FILTER_1_RESONANCE  = 142
SLOT_FILTER_1_GAIN       = 143
SLOT_FILTER_1_MOD_1_AMT  = 144
SLOT_FILTER_1_MOD_1_POL  = 145
SLOT_AMP_1_GAIN          = 146
SLOT_MIXER_1_LEVEL_1     = 147
SLOT_MIXER_1_POL_1       = 148
SLOT_MIXER_1_LEVEL_2     = 149
SLOT_MIXER_1_POL_2       = 150
SLOT_CHORUS_1_RATE       = 151
SLOT_CHORUS_1_DEPTH      = 152
SLOT_CHORUS_1_MIX        = 153
SLOT_DELAY_1_TIME        = 154
SLOT_DELAY_1_FEEDBACK    = 155
SLOT_DELAY_1_MIX         = 156
SLOT_PITCH_1_GLIDE       = 162
SLOT_OSC_1_PULSE_WIDTH   = 163
SLOT_OSC_1_PW_MOD_2_AMT  = 164
SLOT_OSC_1_PW_MOD_2_POL  = 165
SLOT_LFO_1_RATE_MOD_AMT  = 168
SLOT_LFO_1_RATE_MOD_POL  = 169
SLOT_FILTER_1_MOD_2_AMT  = 172
SLOT_FILTER_1_MOD_2_POL  = 173
SLOT_FILTER_1_MOD_3_AMT  = 174
SLOT_FILTER_1_MOD_3_POL  = 175
SLOT_PITCH_1_BEND_AMT    = 176
SLOT_PITCH_1_BEND_POL    = 177
SLOT_LFO_1_LEVEL_MOD_AMT = 178
SLOT_LFO_1_LEVEL_MOD_POL = 179
SLOT_PITCH_1_COARSE      = 180
SLOT_PITCH_1_FINE        = 181
SLOT_MIXER_1_OUT_LEVEL   = 182
SLOT_OSC_1_MOD_1_AMT     = 183
SLOT_OSC_1_MOD_1_POL     = 184
SLOT_NOISE_1_LEVEL       = 185
SLOT_OSC_2_WAVE          = 186
SLOT_OSC_2_PITCH_COARSE  = 187
SLOT_OSC_2_PITCH_FINE    = 188
SLOT_OSC_2_MOD_1_AMT     = 189
SLOT_OSC_2_MOD_1_POL     = 190
SLOT_OSC_2_MOD_2_AMT     = 191
SLOT_OSC_2_MOD_2_POL     = 192
SLOT_OSC_2_PULSE_WIDTH   = 193
SLOT_OSC_2_PW_MOD_2_AMT  = 194
SLOT_OSC_2_PW_MOD_2_POL  = 195
SLOT_MIXER_1_LEVEL_3     = 199
SLOT_MIXER_1_POL_3       = 200
SLOT_MIXER_1_LEVEL_4     = 201
SLOT_MIXER_1_POL_4       = 202
SLOT_MIXER_2_LEVEL_1     = 203
SLOT_MIXER_2_POL_1       = 204
SLOT_MIXER_2_LEVEL_2     = 205
SLOT_MIXER_2_POL_2       = 206
SLOT_MIXER_2_LEVEL_3     = 207
SLOT_MIXER_2_POL_3       = 208
SLOT_MIXER_2_LEVEL_4     = 209
SLOT_MIXER_2_POL_4       = 210
SLOT_MIXER_2_OUT_LEVEL   = 211
SLOT_MIXER_1_BALANCE_1_2 = 213
SLOT_MIXER_1_BALANCE_3_4 = 214
SLOT_MIXER_2_BALANCE_1_2 = 215
SLOT_MIXER_2_BALANCE_3_4 = 216
SLOT_PITCH_1_STRETCH     = 217
SLOT_FILTER_1_MODE       = 218
SLOT_OSC_1_PW_MOD_1_AMT  = 219
SLOT_OSC_1_PW_MOD_1_POL  = 220
SLOT_OSC_2_PW_MOD_1_AMT  = 221
SLOT_OSC_2_PW_MOD_1_POL  = 222
SLOT_NOISE_1_COLOR       = 223
SLOT_LFO_1_WAVE          = 224
SLOT_MIXER_1_BALANCE_LAW = 225
SLOT_MIXER_2_BALANCE_LAW = 226

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
NRPN_SOURCE_OSC_1_PW_MOD_2  = 143
NRPN_SOURCE_LFO_1_RATE_MOD  = 144
NRPN_SOURCE_FILTER_1_MOD_2  = 145
NRPN_SOURCE_FILTER_1_MOD_3  = 146
NRPN_SOURCE_PITCH_1_BEND    = 147
NRPN_SOURCE_LFO_1_LEVEL_MOD = 148
NRPN_SOURCE_OSC_1_MOD_1     = 149
NRPN_SOURCE_OSC_2_PITCH     = 152
NRPN_SOURCE_OSC_2_MOD_1     = 153
NRPN_SOURCE_OSC_2_MOD_2     = 154
NRPN_SOURCE_OSC_2_PW_MOD_2  = 155
NRPN_SOURCE_MIXER_1_IN_3    = 156
NRPN_SOURCE_MIXER_1_IN_4    = 157
NRPN_SOURCE_MIXER_2_IN_1    = 158
NRPN_SOURCE_MIXER_2_IN_2    = 159
NRPN_SOURCE_MIXER_2_IN_3    = 160
NRPN_SOURCE_MIXER_2_IN_4    = 161
NRPN_SOURCE_OSC_1_PW_MOD_1  = 162
NRPN_SOURCE_OSC_2_PW_MOD_1  = 163

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
NRPN_SOURCE_OSC_1_PW_MOD_2_AMT  = 292
NRPN_SOURCE_OSC_1_PW_MOD_2_POL  = 293
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
NRPN_SOURCE_OSC_2_PW_MOD_2_AMT  = 322
NRPN_SOURCE_OSC_2_PW_MOD_2_POL  = 323
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
NRPN_SOURCE_MIXER_1_BALANCE_1_2 = 341
NRPN_SOURCE_MIXER_1_BALANCE_3_4 = 342
NRPN_SOURCE_MIXER_2_BALANCE_1_2 = 343
NRPN_SOURCE_MIXER_2_BALANCE_3_4 = 344
NRPN_SOURCE_PITCH_1_STRETCH     = 345
NRPN_SOURCE_FILTER_1_MODE       = 346
NRPN_SOURCE_OSC_1_PW_MOD_1_AMT  = 347
NRPN_SOURCE_OSC_1_PW_MOD_1_POL  = 348
NRPN_SOURCE_OSC_2_PW_MOD_1_AMT  = 349
NRPN_SOURCE_OSC_2_PW_MOD_1_POL  = 350
NRPN_SOURCE_NOISE_1_COLOR       = 351
NRPN_SOURCE_LFO_1_WAVE          = 352
NRPN_SOURCE_MIXER_1_BALANCE_LAW = 353
NRPN_SOURCE_MIXER_2_BALANCE_LAW = 354

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
NRPN_CC_OSC_1_PW_MOD_2_AMT  = 420
NRPN_CC_OSC_1_PW_MOD_2_POL  = 421
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
NRPN_CC_OSC_2_PW_MOD_2_AMT  = 450
NRPN_CC_OSC_2_PW_MOD_2_POL  = 451
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
NRPN_CC_MIXER_1_BALANCE_1_2 = 469
NRPN_CC_MIXER_1_BALANCE_3_4 = 470
NRPN_CC_MIXER_2_BALANCE_1_2 = 471
NRPN_CC_MIXER_2_BALANCE_3_4 = 472
NRPN_CC_PITCH_1_STRETCH     = 473
NRPN_CC_FILTER_1_MODE       = 474
NRPN_CC_OSC_1_PW_MOD_1_AMT  = 475
NRPN_CC_OSC_1_PW_MOD_1_POL  = 476
NRPN_CC_OSC_2_PW_MOD_1_AMT  = 477
NRPN_CC_OSC_2_PW_MOD_1_POL  = 478
NRPN_CC_NOISE_1_COLOR       = 479
NRPN_CC_LFO_1_WAVE          = 480
NRPN_CC_MIXER_1_BALANCE_LAW = 481
NRPN_CC_MIXER_2_BALANCE_LAW = 482

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
  signals[SIGNAL_SQRT_HALF]       = 0.7071068
end

# The default patch, written into the NRPN table, and the values its CCs power up at.
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
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH    , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_2    , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_AUDIO , SIGNAL_MIXER_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1 , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_AUDIO    , SIGNAL_FILTER_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_MOD      , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_1   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_2   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_AUDIO , SIGNAL_AMP_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_L, SIGNAL_CHORUS_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_R, SIGNAL_CHORUS_1_OUTPUT_R)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_L       , SIGNAL_DELAY_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_R       , SIGNAL_DELAY_1_OUTPUT_R)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_PITCH  , SIGNAL_NOTE_PITCH)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_2 , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2 , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_3 , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND   , SIGNAL_PITCH_BEND)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD, SIGNAL_GENERAL_MOD_WHEEL)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_1    , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH    , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_1    , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_2    , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_2 , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_3   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_4   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_1   , SIGNAL_OSC_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_2   , SIGNAL_OSC_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_3   , SIGNAL_NOISE_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_4   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_1 , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_1 , SIGNAL_EG_1_OUTPUT)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_ATTACK        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_DECAY         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_SUSTAIN       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_LEVEL         , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_WAVE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_COARSE , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_FINE   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_2_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_2_POL    , SIGNAL_POINT_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_CUTOFF    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_RESONANCE , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_GAIN      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_GAIN         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_1    , SIGNAL_SQRT_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_1      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_2    , SIGNAL_SQRT_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_2      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_RATE      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_DEPTH     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_MIX       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_TIME       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_FEEDBACK   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_MIX        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_GLIDE      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PULSE_WIDTH  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_2_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_2_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_AMT , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2_POL , SIGNAL_POINT_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_3_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_3_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_AMT   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_POL   , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT, SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_POL, SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_COARSE     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_FINE       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_OUT_LEVEL  , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_1_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_1_POL    , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_NOISE_1_LEVEL      , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_WAVE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_COARSE , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_FINE   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_1_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_1_POL    , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_2_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_2_POL    , SIGNAL_POINT_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PULSE_WIDTH  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_2_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_2_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_3    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_3      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_4    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_4      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_1    , SIGNAL_SQRT_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_1      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_2    , SIGNAL_SQRT_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_2      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_3    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_3      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_4    , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_4      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_OUT_LEVEL  , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_BALANCE_1_2, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_BALANCE_3_4, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_BALANCE_1_2, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_BALANCE_3_4, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_STRETCH    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MODE      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_1_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_1_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_1_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_1_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_NOISE_1_COLOR      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_WAVE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_BALANCE_LAW, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_BALANCE_LAW, SIGNAL_OWN)

  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_RATE         , 3)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_LEVEL        , 113)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_ATTACK        , 73)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_DECAY         , 75)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_SUSTAIN       , 30)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_WAVE         , 102)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_MOD_2_AMT    , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_CUTOFF    , 74)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_RESONANCE , 71)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_GAIN      , 112)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_1_AMT , 24)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_AMP_1_GAIN         , 15)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_RATE      , 58)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_DEPTH     , 59)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_MIX       , 93)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_TIME       , 90)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_FEEDBACK   , 92)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_MIX        , 94)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_MOD_WHEEL  , 1)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_1          , 16)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_2          , 17)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_3          , 18)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_4          , 19)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_GLIDE      , 5)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PULSE_WIDTH  , 114)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_2_AMT , 103)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_2_AMT , 25)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_3_AMT , 9)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_BEND_AMT   , 57)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_COARSE     , 86)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_FINE       , 70)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_MOD_1_AMT    , 89)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_WAVE         , 104)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_COARSE , 85)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_FINE   , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_MOD_1_AMT    , 89)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_MOD_2_AMT    , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PULSE_WIDTH  , 114)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PW_MOD_2_AMT , 103)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_3    , 23)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_1_BALANCE_1_2, 119)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_BALANCE_1_2, 21)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_STRETCH    , 22)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MODE      , 39)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_1_AMT , 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PW_MOD_1_AMT , 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_NOISE_1_COLOR      , 115)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_WAVE         , 33)

  C.set_midi_cc_value(midi_ch, 3  , 64 ) # LFO 1 Rate
  C.set_midi_cc_value(midi_ch, 113, 124) # LFO 1 Level
  C.set_midi_cc_value(midi_ch, 73 , 4  ) # EG 1 Attack
  C.set_midi_cc_value(midi_ch, 75 , 94 ) # EG 1 Decay
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
  C.set_midi_cc_value(midi_ch, 103, 4  ) # Osc 1 PW Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 25 , 4  ) # Filter 1 Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 9  , 4  ) # Filter 1 Mod 3 Amt
  C.set_midi_cc_value(midi_ch, 57 , 8  ) # Pitch 1 Bend Amt
  C.set_midi_cc_value(midi_ch, 86 , 64 ) # Pitch 1 Coarse
  C.set_midi_cc_value(midi_ch, 70 , 64 ) # Pitch 1 Fine
  C.set_midi_cc_value(midi_ch, 89 , 4  ) # Osc 1 Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 104, 4  ) # Osc 2 Wave
  C.set_midi_cc_value(midi_ch, 85 , 64 ) # Osc 2 Pitch Coarse
  C.set_midi_cc_value(midi_ch, 76 , 76 ) # Osc 2 Pitch Fine
  C.set_midi_cc_value(midi_ch, 89 , 4  ) # Osc 2 Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 13 , 4  ) # Osc 2 Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 114, 4  ) # Osc 2 Pulse Width
  C.set_midi_cc_value(midi_ch, 103, 4  ) # Osc 2 PW Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 23 , 4  ) # Mixer 2 Level 3
  C.set_midi_cc_value(midi_ch, 119, 64 ) # Mixer 1 Balance 1/2
  C.set_midi_cc_value(midi_ch, 21 , 4  ) # Mixer 2 Balance 1/2
  C.set_midi_cc_value(midi_ch, 22 , 4  ) # Pitch 1 Stretch
  C.set_midi_cc_value(midi_ch, 39 , 4  ) # Filter 1 Mode
  C.set_midi_cc_value(midi_ch, 8  , 4  ) # Osc 1 PW Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 8  , 4  ) # Osc 2 PW Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 115, 4  ) # Noise 1 Color
  C.set_midi_cc_value(midi_ch, 33 , 4  ) # LFO 1 Wave
end
