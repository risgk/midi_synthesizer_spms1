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
SIGNAL_SQRT_HALF             = 2
SIGNAL_HALF                  = 3
SIGNAL_POINT_TWO             = 4
SIGNAL_POINT_ONE             = 5
SIGNAL_MINUS_POINT_ONE       = 6
SIGNAL_MINUS_POINT_TWO       = 7
SIGNAL_MINUS_HALF            = 8
SIGNAL_MINUS_ONE             = 9
SIGNAL_NOTE_PITCH            = 10
SIGNAL_NOTE_GATE             = 11
SIGNAL_PITCH_BEND            = 12
SIGNAL_GENERAL_MOD_WHEEL     = 13
SIGNAL_GENERAL_UNIPOLAR_1    = 14
SIGNAL_GENERAL_UNIPOLAR_2    = 15
SIGNAL_GENERAL_UNIPOLAR_3    = 16
SIGNAL_GENERAL_UNIPOLAR_4    = 17
SIGNAL_GENERAL_BIPOLAR_1     = 18
SIGNAL_GENERAL_BIPOLAR_2     = 19
SIGNAL_GENERAL_BIPOLAR_3     = 20
SIGNAL_GENERAL_BIPOLAR_4     = 21
SIGNAL_EG_1_OUTPUT           = 22
SIGNAL_LFO_1_OUTPUT          = 23
SIGNAL_LFO_1_OUTPUT_TRIANGLE = 24
SIGNAL_LFO_1_OUTPUT_SQUARE   = 25
SIGNAL_MIXER_1_OUTPUT        = 26
SIGNAL_PITCH_1_OUTPUT        = 27
SIGNAL_OSC_1_OUTPUT          = 28
SIGNAL_OSC_1_OUTPUT_SAW      = 29
SIGNAL_OSC_1_OUTPUT_PULSE    = 30
SIGNAL_OSC_2_OUTPUT          = 31
SIGNAL_OSC_2_OUTPUT_SAW      = 32
SIGNAL_OSC_2_OUTPUT_PULSE    = 33
SIGNAL_NOISE_1_OUTPUT        = 34
SIGNAL_NOISE_1_OUTPUT_WHITE  = 35
SIGNAL_NOISE_1_OUTPUT_RED    = 36
SIGNAL_MIXER_2_OUTPUT        = 37
SIGNAL_FILTER_1_OUTPUT       = 38
SIGNAL_FILTER_1_OUTPUT_LP    = 39
SIGNAL_FILTER_1_OUTPUT_HP    = 40
SIGNAL_FILTER_1_OUTPUT_BP    = 41
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

SLOT_EG_1_ATTACK         = 128
SLOT_EG_1_DECAY          = 129
SLOT_EG_1_SUSTAIN        = 130
SLOT_EG_1_LEVEL          = 131
SLOT_LFO_1_RATE          = 132
SLOT_LFO_1_RATE_MOD_AMT  = 133
SLOT_LFO_1_RATE_MOD_POL  = 134
SLOT_LFO_1_LEVEL         = 135
SLOT_LFO_1_WAVE          = 136
SLOT_LFO_1_LEVEL_MOD_AMT = 137
SLOT_LFO_1_LEVEL_MOD_POL = 138
SLOT_MIXER_1_LEVEL_1     = 139
SLOT_MIXER_1_POL_1       = 140
SLOT_MIXER_1_LEVEL_2     = 141
SLOT_MIXER_1_POL_2       = 142
SLOT_MIXER_1_BALANCE_1_2 = 143
SLOT_MIXER_1_LEVEL_3     = 144
SLOT_MIXER_1_POL_3       = 145
SLOT_MIXER_1_LEVEL_4     = 146
SLOT_MIXER_1_POL_4       = 147
SLOT_MIXER_1_BALANCE_3_4 = 148
SLOT_MIXER_1_BALANCE_LAW = 149
SLOT_MIXER_1_OUT_LEVEL   = 150
SLOT_PITCH_1_GLIDE       = 151
SLOT_PITCH_1_COARSE      = 152
SLOT_PITCH_1_FINE        = 153
SLOT_PITCH_1_STRETCH     = 154
SLOT_PITCH_1_BEND_AMT    = 155
SLOT_PITCH_1_BEND_POL    = 156
SLOT_OSC_1_PITCH_COARSE  = 157
SLOT_OSC_1_PITCH_FINE    = 158
SLOT_OSC_1_MOD_1_AMT     = 159
SLOT_OSC_1_MOD_1_POL     = 160
SLOT_OSC_1_MOD_2_AMT     = 161
SLOT_OSC_1_MOD_2_POL     = 162
SLOT_OSC_1_WAVE          = 163
SLOT_OSC_1_PULSE_WIDTH   = 164
SLOT_OSC_1_PW_MOD_1_AMT  = 165
SLOT_OSC_1_PW_MOD_1_POL  = 166
SLOT_OSC_1_PW_MOD_2_AMT  = 167
SLOT_OSC_1_PW_MOD_2_POL  = 168
SLOT_OSC_2_PITCH_COARSE  = 169
SLOT_OSC_2_PITCH_FINE    = 170
SLOT_OSC_2_MOD_1_AMT     = 171
SLOT_OSC_2_MOD_1_POL     = 172
SLOT_OSC_2_MOD_2_AMT     = 173
SLOT_OSC_2_MOD_2_POL     = 174
SLOT_OSC_2_WAVE          = 175
SLOT_OSC_2_PULSE_WIDTH   = 176
SLOT_OSC_2_PW_MOD_1_AMT  = 177
SLOT_OSC_2_PW_MOD_1_POL  = 178
SLOT_OSC_2_PW_MOD_2_AMT  = 179
SLOT_OSC_2_PW_MOD_2_POL  = 180
SLOT_NOISE_1_LEVEL       = 181
SLOT_NOISE_1_COLOR       = 182
SLOT_MIXER_2_LEVEL_1     = 183
SLOT_MIXER_2_POL_1       = 184
SLOT_MIXER_2_LEVEL_2     = 185
SLOT_MIXER_2_POL_2       = 186
SLOT_MIXER_2_BALANCE_1_2 = 187
SLOT_MIXER_2_LEVEL_3     = 188
SLOT_MIXER_2_POL_3       = 189
SLOT_MIXER_2_LEVEL_4     = 190
SLOT_MIXER_2_POL_4       = 191
SLOT_MIXER_2_BALANCE_3_4 = 192
SLOT_MIXER_2_BALANCE_LAW = 193
SLOT_MIXER_2_OUT_LEVEL   = 194
SLOT_FILTER_1_GAIN       = 195
SLOT_FILTER_1_CUTOFF     = 196
SLOT_FILTER_1_MOD_1_AMT  = 197
SLOT_FILTER_1_MOD_1_POL  = 198
SLOT_FILTER_1_MOD_2_AMT  = 199
SLOT_FILTER_1_MOD_2_POL  = 200
SLOT_FILTER_1_MOD_3_AMT  = 201
SLOT_FILTER_1_MOD_3_POL  = 202
SLOT_FILTER_1_RESONANCE  = 203
SLOT_FILTER_1_MODE       = 204
SLOT_AMP_1_GAIN          = 205
SLOT_AMP_1_GAIN_POL      = 206
SLOT_CHORUS_1_MIX        = 207
SLOT_CHORUS_1_RATE       = 208
SLOT_CHORUS_1_DEPTH      = 209
SLOT_DELAY_1_MIX         = 210
SLOT_DELAY_1_TIME        = 211
SLOT_DELAY_1_FEEDBACK    = 212

# NRPN parameter numbers: (MSB << 7) | LSB, where the MSB picks a category and the LSB an entry.
#   0..127   active_modules[slot]
# 128..255   what feeds each module input
# 256..383   where each parameter's value comes from
# 384..511   which CC fills each control slot
NRPN_ACTIVE_MODULE_BASE = 0

NRPN_SOURCE_EG_1_GATE       = 128
NRPN_SOURCE_LFO_1_RATE_MOD  = 129
NRPN_SOURCE_LFO_1_LEVEL_MOD = 130
NRPN_SOURCE_MIXER_1_IN_1    = 131
NRPN_SOURCE_MIXER_1_IN_2    = 132
NRPN_SOURCE_MIXER_1_IN_3    = 133
NRPN_SOURCE_MIXER_1_IN_4    = 134
NRPN_SOURCE_PITCH_1_PITCH   = 135
NRPN_SOURCE_PITCH_1_BEND    = 136
NRPN_SOURCE_OSC_1_PITCH     = 137
NRPN_SOURCE_OSC_1_MOD_1     = 138
NRPN_SOURCE_OSC_1_MOD_2     = 139
NRPN_SOURCE_OSC_1_PW_MOD_1  = 140
NRPN_SOURCE_OSC_1_PW_MOD_2  = 141
NRPN_SOURCE_OSC_2_PITCH     = 142
NRPN_SOURCE_OSC_2_MOD_1     = 143
NRPN_SOURCE_OSC_2_MOD_2     = 144
NRPN_SOURCE_OSC_2_PW_MOD_1  = 145
NRPN_SOURCE_OSC_2_PW_MOD_2  = 146
NRPN_SOURCE_MIXER_2_IN_1    = 147
NRPN_SOURCE_MIXER_2_IN_2    = 148
NRPN_SOURCE_MIXER_2_IN_3    = 149
NRPN_SOURCE_MIXER_2_IN_4    = 150
NRPN_SOURCE_FILTER_1_AUDIO  = 151
NRPN_SOURCE_FILTER_1_MOD_1  = 152
NRPN_SOURCE_FILTER_1_MOD_2  = 153
NRPN_SOURCE_FILTER_1_MOD_3  = 154
NRPN_SOURCE_AMP_1_AUDIO     = 155
NRPN_SOURCE_AMP_1_MOD       = 156
NRPN_SOURCE_CHORUS_1_AUDIO  = 157
NRPN_SOURCE_DELAY_1_AUDIO_L = 158
NRPN_SOURCE_DELAY_1_AUDIO_R = 159
NRPN_SOURCE_OUTPUT_L        = 160
NRPN_SOURCE_OUTPUT_R        = 161

NRPN_SOURCE_EG_1_ATTACK         = 256
NRPN_SOURCE_EG_1_DECAY          = 257
NRPN_SOURCE_EG_1_SUSTAIN        = 258
NRPN_SOURCE_EG_1_LEVEL          = 259
NRPN_SOURCE_LFO_1_RATE          = 260
NRPN_SOURCE_LFO_1_RATE_MOD_AMT  = 261
NRPN_SOURCE_LFO_1_RATE_MOD_POL  = 262
NRPN_SOURCE_LFO_1_LEVEL         = 263
NRPN_SOURCE_LFO_1_WAVE          = 264
NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT = 265
NRPN_SOURCE_LFO_1_LEVEL_MOD_POL = 266
NRPN_SOURCE_MIXER_1_LEVEL_1     = 267
NRPN_SOURCE_MIXER_1_POL_1       = 268
NRPN_SOURCE_MIXER_1_LEVEL_2     = 269
NRPN_SOURCE_MIXER_1_POL_2       = 270
NRPN_SOURCE_MIXER_1_BALANCE_1_2 = 271
NRPN_SOURCE_MIXER_1_LEVEL_3     = 272
NRPN_SOURCE_MIXER_1_POL_3       = 273
NRPN_SOURCE_MIXER_1_LEVEL_4     = 274
NRPN_SOURCE_MIXER_1_POL_4       = 275
NRPN_SOURCE_MIXER_1_BALANCE_3_4 = 276
NRPN_SOURCE_MIXER_1_BALANCE_LAW = 277
NRPN_SOURCE_MIXER_1_OUT_LEVEL   = 278
NRPN_SOURCE_PITCH_1_GLIDE       = 279
NRPN_SOURCE_PITCH_1_COARSE      = 280
NRPN_SOURCE_PITCH_1_FINE        = 281
NRPN_SOURCE_PITCH_1_STRETCH     = 282
NRPN_SOURCE_PITCH_1_BEND_AMT    = 283
NRPN_SOURCE_PITCH_1_BEND_POL    = 284
NRPN_SOURCE_OSC_1_PITCH_COARSE  = 285
NRPN_SOURCE_OSC_1_PITCH_FINE    = 286
NRPN_SOURCE_OSC_1_MOD_1_AMT     = 287
NRPN_SOURCE_OSC_1_MOD_1_POL     = 288
NRPN_SOURCE_OSC_1_MOD_2_AMT     = 289
NRPN_SOURCE_OSC_1_MOD_2_POL     = 290
NRPN_SOURCE_OSC_1_WAVE          = 291
NRPN_SOURCE_OSC_1_PULSE_WIDTH   = 292
NRPN_SOURCE_OSC_1_PW_MOD_1_AMT  = 293
NRPN_SOURCE_OSC_1_PW_MOD_1_POL  = 294
NRPN_SOURCE_OSC_1_PW_MOD_2_AMT  = 295
NRPN_SOURCE_OSC_1_PW_MOD_2_POL  = 296
NRPN_SOURCE_OSC_2_PITCH_COARSE  = 297
NRPN_SOURCE_OSC_2_PITCH_FINE    = 298
NRPN_SOURCE_OSC_2_MOD_1_AMT     = 299
NRPN_SOURCE_OSC_2_MOD_1_POL     = 300
NRPN_SOURCE_OSC_2_MOD_2_AMT     = 301
NRPN_SOURCE_OSC_2_MOD_2_POL     = 302
NRPN_SOURCE_OSC_2_WAVE          = 303
NRPN_SOURCE_OSC_2_PULSE_WIDTH   = 304
NRPN_SOURCE_OSC_2_PW_MOD_1_AMT  = 305
NRPN_SOURCE_OSC_2_PW_MOD_1_POL  = 306
NRPN_SOURCE_OSC_2_PW_MOD_2_AMT  = 307
NRPN_SOURCE_OSC_2_PW_MOD_2_POL  = 308
NRPN_SOURCE_NOISE_1_LEVEL       = 309
NRPN_SOURCE_NOISE_1_COLOR       = 310
NRPN_SOURCE_MIXER_2_LEVEL_1     = 311
NRPN_SOURCE_MIXER_2_POL_1       = 312
NRPN_SOURCE_MIXER_2_LEVEL_2     = 313
NRPN_SOURCE_MIXER_2_POL_2       = 314
NRPN_SOURCE_MIXER_2_BALANCE_1_2 = 315
NRPN_SOURCE_MIXER_2_LEVEL_3     = 316
NRPN_SOURCE_MIXER_2_POL_3       = 317
NRPN_SOURCE_MIXER_2_LEVEL_4     = 318
NRPN_SOURCE_MIXER_2_POL_4       = 319
NRPN_SOURCE_MIXER_2_BALANCE_3_4 = 320
NRPN_SOURCE_MIXER_2_BALANCE_LAW = 321
NRPN_SOURCE_MIXER_2_OUT_LEVEL   = 322
NRPN_SOURCE_FILTER_1_GAIN       = 323
NRPN_SOURCE_FILTER_1_CUTOFF     = 324
NRPN_SOURCE_FILTER_1_MOD_1_AMT  = 325
NRPN_SOURCE_FILTER_1_MOD_1_POL  = 326
NRPN_SOURCE_FILTER_1_MOD_2_AMT  = 327
NRPN_SOURCE_FILTER_1_MOD_2_POL  = 328
NRPN_SOURCE_FILTER_1_MOD_3_AMT  = 329
NRPN_SOURCE_FILTER_1_MOD_3_POL  = 330
NRPN_SOURCE_FILTER_1_RESONANCE  = 331
NRPN_SOURCE_FILTER_1_MODE       = 332
NRPN_SOURCE_AMP_1_GAIN          = 333
NRPN_SOURCE_AMP_1_GAIN_POL      = 334
NRPN_SOURCE_CHORUS_1_MIX        = 335
NRPN_SOURCE_CHORUS_1_RATE       = 336
NRPN_SOURCE_CHORUS_1_DEPTH      = 337
NRPN_SOURCE_DELAY_1_MIX         = 338
NRPN_SOURCE_DELAY_1_TIME        = 339
NRPN_SOURCE_DELAY_1_FEEDBACK    = 340

# A CC number of 0 means the parameter has no CC: its control slot holds 0.0 -- the bottom of a
# unipolar dial, the middle of a bipolar one -- whatever CC it had before, so a patch sets it alone.
NRPN_CC_EG_1_ATTACK         = 384
NRPN_CC_EG_1_DECAY          = 385
NRPN_CC_EG_1_SUSTAIN        = 386
NRPN_CC_EG_1_LEVEL          = 387
NRPN_CC_LFO_1_RATE          = 388
NRPN_CC_LFO_1_RATE_MOD_AMT  = 389
NRPN_CC_LFO_1_RATE_MOD_POL  = 390
NRPN_CC_LFO_1_LEVEL         = 391
NRPN_CC_LFO_1_WAVE          = 392
NRPN_CC_LFO_1_LEVEL_MOD_AMT = 393
NRPN_CC_LFO_1_LEVEL_MOD_POL = 394
NRPN_CC_MIXER_1_LEVEL_1     = 395
NRPN_CC_MIXER_1_POL_1       = 396
NRPN_CC_MIXER_1_LEVEL_2     = 397
NRPN_CC_MIXER_1_POL_2       = 398
NRPN_CC_MIXER_1_BALANCE_1_2 = 399
NRPN_CC_MIXER_1_LEVEL_3     = 400
NRPN_CC_MIXER_1_POL_3       = 401
NRPN_CC_MIXER_1_LEVEL_4     = 402
NRPN_CC_MIXER_1_POL_4       = 403
NRPN_CC_MIXER_1_BALANCE_3_4 = 404
NRPN_CC_MIXER_1_BALANCE_LAW = 405
NRPN_CC_MIXER_1_OUT_LEVEL   = 406
NRPN_CC_PITCH_1_GLIDE       = 407
NRPN_CC_PITCH_1_COARSE      = 408
NRPN_CC_PITCH_1_FINE        = 409
NRPN_CC_PITCH_1_STRETCH     = 410
NRPN_CC_PITCH_1_BEND_AMT    = 411
NRPN_CC_PITCH_1_BEND_POL    = 412
NRPN_CC_OSC_1_PITCH_COARSE  = 413
NRPN_CC_OSC_1_PITCH_FINE    = 414
NRPN_CC_OSC_1_MOD_1_AMT     = 415
NRPN_CC_OSC_1_MOD_1_POL     = 416
NRPN_CC_OSC_1_MOD_2_AMT     = 417
NRPN_CC_OSC_1_MOD_2_POL     = 418
NRPN_CC_OSC_1_WAVE          = 419
NRPN_CC_OSC_1_PULSE_WIDTH   = 420
NRPN_CC_OSC_1_PW_MOD_1_AMT  = 421
NRPN_CC_OSC_1_PW_MOD_1_POL  = 422
NRPN_CC_OSC_1_PW_MOD_2_AMT  = 423
NRPN_CC_OSC_1_PW_MOD_2_POL  = 424
NRPN_CC_OSC_2_PITCH_COARSE  = 425
NRPN_CC_OSC_2_PITCH_FINE    = 426
NRPN_CC_OSC_2_MOD_1_AMT     = 427
NRPN_CC_OSC_2_MOD_1_POL     = 428
NRPN_CC_OSC_2_MOD_2_AMT     = 429
NRPN_CC_OSC_2_MOD_2_POL     = 430
NRPN_CC_OSC_2_WAVE          = 431
NRPN_CC_OSC_2_PULSE_WIDTH   = 432
NRPN_CC_OSC_2_PW_MOD_1_AMT  = 433
NRPN_CC_OSC_2_PW_MOD_1_POL  = 434
NRPN_CC_OSC_2_PW_MOD_2_AMT  = 435
NRPN_CC_OSC_2_PW_MOD_2_POL  = 436
NRPN_CC_NOISE_1_LEVEL       = 437
NRPN_CC_NOISE_1_COLOR       = 438
NRPN_CC_MIXER_2_LEVEL_1     = 439
NRPN_CC_MIXER_2_POL_1       = 440
NRPN_CC_MIXER_2_LEVEL_2     = 441
NRPN_CC_MIXER_2_POL_2       = 442
NRPN_CC_MIXER_2_BALANCE_1_2 = 443
NRPN_CC_MIXER_2_LEVEL_3     = 444
NRPN_CC_MIXER_2_POL_3       = 445
NRPN_CC_MIXER_2_LEVEL_4     = 446
NRPN_CC_MIXER_2_POL_4       = 447
NRPN_CC_MIXER_2_BALANCE_3_4 = 448
NRPN_CC_MIXER_2_BALANCE_LAW = 449
NRPN_CC_MIXER_2_OUT_LEVEL   = 450
NRPN_CC_FILTER_1_GAIN       = 451
NRPN_CC_FILTER_1_CUTOFF     = 452
NRPN_CC_FILTER_1_MOD_1_AMT  = 453
NRPN_CC_FILTER_1_MOD_1_POL  = 454
NRPN_CC_FILTER_1_MOD_2_AMT  = 455
NRPN_CC_FILTER_1_MOD_2_POL  = 456
NRPN_CC_FILTER_1_MOD_3_AMT  = 457
NRPN_CC_FILTER_1_MOD_3_POL  = 458
NRPN_CC_FILTER_1_RESONANCE  = 459
NRPN_CC_FILTER_1_MODE       = 460
NRPN_CC_AMP_1_GAIN          = 461
NRPN_CC_AMP_1_GAIN_POL      = 462
NRPN_CC_CHORUS_1_MIX        = 463
NRPN_CC_CHORUS_1_RATE       = 464
NRPN_CC_CHORUS_1_DEPTH      = 465
NRPN_CC_DELAY_1_MIX         = 466
NRPN_CC_DELAY_1_TIME        = 467
NRPN_CC_DELAY_1_FEEDBACK    = 468
NRPN_CC_GENERAL_MOD_WHEEL   = 469
NRPN_CC_GENERAL_1           = 470
NRPN_CC_GENERAL_2           = 471
NRPN_CC_GENERAL_3           = 472
NRPN_CC_GENERAL_4           = 473

# The constants of the bus, which nothing else ever writes. A slot not written here holds 0.0.
def spms1_fill_constant_signals(signals)
  signals[SIGNAL_ONE]             =  1.0
  signals[SIGNAL_SQRT_HALF]       = 0.7071068
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
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_4   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_PITCH  , SIGNAL_NOTE_PITCH)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND   , SIGNAL_PITCH_BEND)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH    , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_1    , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_2    , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_1 , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_2 , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH    , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_1    , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_2    , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_1 , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_2 , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_1   , SIGNAL_OSC_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_2   , SIGNAL_OSC_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_3   , SIGNAL_NOISE_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_4   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_AUDIO , SIGNAL_MIXER_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1 , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2 , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_3 , SIGNAL_PITCH_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_AUDIO    , SIGNAL_FILTER_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_MOD      , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_AUDIO , SIGNAL_AMP_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_L, SIGNAL_CHORUS_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_R, SIGNAL_CHORUS_1_OUTPUT_R)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_L       , SIGNAL_DELAY_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_R       , SIGNAL_DELAY_1_OUTPUT_R)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_ATTACK        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_DECAY         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_SUSTAIN       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_LEVEL         , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_AMT , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_WAVE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT, SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_POL, SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_1    , SIGNAL_SQRT_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_1      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_2    , SIGNAL_SQRT_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_2      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_BALANCE_1_2, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_3    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_3      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_4    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_4      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_BALANCE_3_4, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_BALANCE_LAW, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_OUT_LEVEL  , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_GLIDE      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_COARSE     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_FINE       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_STRETCH    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_AMT   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_POL   , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_COARSE , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_FINE   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_1_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_1_POL    , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_2_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_MOD_2_POL    , SIGNAL_POINT_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_WAVE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PULSE_WIDTH  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_1_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_1_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_2_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_2_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_COARSE , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_FINE   , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_1_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_1_POL    , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_2_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_MOD_2_POL    , SIGNAL_POINT_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_WAVE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PULSE_WIDTH  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_1_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_1_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_2_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_2_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_NOISE_1_LEVEL      , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_NOISE_1_COLOR      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_1    , SIGNAL_SQRT_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_1      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_2    , SIGNAL_SQRT_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_2      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_BALANCE_1_2, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_3    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_3      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_4    , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_4      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_BALANCE_3_4, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_BALANCE_LAW, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_OUT_LEVEL  , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_GAIN      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_CUTOFF    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2_POL , SIGNAL_POINT_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_3_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_3_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_RESONANCE , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MODE      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_GAIN         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_GAIN_POL     , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_MIX       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_RATE      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_DEPTH     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_MIX        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_TIME       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_FEEDBACK   , SIGNAL_OWN)

  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_ATTACK        , 73)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_DECAY         , 75)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_SUSTAIN       , 30)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_RATE         , 3)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_LEVEL        , 113)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_WAVE         , 33)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_1_BALANCE_1_2, 119)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_GLIDE      , 5)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_COARSE     , 86)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_FINE       , 70)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_STRETCH    , 22)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_BEND_AMT   , 57)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_MOD_1_AMT    , 89)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_MOD_2_AMT    , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_WAVE         , 102)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PULSE_WIDTH  , 114)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_1_AMT , 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_2_AMT , 103)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_COARSE , 85)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_FINE   , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_MOD_1_AMT    , 89)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_MOD_2_AMT    , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_WAVE         , 104)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PULSE_WIDTH  , 114)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PW_MOD_1_AMT , 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PW_MOD_2_AMT , 103)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_NOISE_1_COLOR      , 115)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_BALANCE_1_2, 21)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_3    , 23)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_GAIN      , 112)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_CUTOFF    , 74)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_1_AMT , 24)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_2_AMT , 25)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_3_AMT , 9)
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

  C.set_midi_cc_value(midi_ch, 73 , 4  ) # EG 1 Attack
  C.set_midi_cc_value(midi_ch, 75 , 94 ) # EG 1 Decay
  C.set_midi_cc_value(midi_ch, 30 , 124) # EG 1 Sustain
  C.set_midi_cc_value(midi_ch, 3  , 64 ) # LFO 1 Rate
  C.set_midi_cc_value(midi_ch, 113, 124) # LFO 1 Level
  C.set_midi_cc_value(midi_ch, 33 , 4  ) # LFO 1 Wave
  C.set_midi_cc_value(midi_ch, 119, 64 ) # Mixer 1 Balance 1/2
  C.set_midi_cc_value(midi_ch, 5  , 4  ) # Pitch 1 Glide
  C.set_midi_cc_value(midi_ch, 86 , 64 ) # Pitch 1 Coarse
  C.set_midi_cc_value(midi_ch, 70 , 64 ) # Pitch 1 Fine
  C.set_midi_cc_value(midi_ch, 22 , 4  ) # Pitch 1 Stretch
  C.set_midi_cc_value(midi_ch, 57 , 8  ) # Pitch 1 Bend Amt
  C.set_midi_cc_value(midi_ch, 89 , 4  ) # Osc 1 Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 13 , 4  ) # Osc 1 Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 102, 4  ) # Osc 1 Wave
  C.set_midi_cc_value(midi_ch, 114, 64 ) # Osc 1 Pulse Width
  C.set_midi_cc_value(midi_ch, 8  , 4  ) # Osc 1 PW Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 103, 4  ) # Osc 1 PW Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 85 , 64 ) # Osc 2 Pitch Coarse
  C.set_midi_cc_value(midi_ch, 76 , 76 ) # Osc 2 Pitch Fine
  C.set_midi_cc_value(midi_ch, 89 , 4  ) # Osc 2 Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 13 , 4  ) # Osc 2 Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 104, 4  ) # Osc 2 Wave
  C.set_midi_cc_value(midi_ch, 114, 64 ) # Osc 2 Pulse Width
  C.set_midi_cc_value(midi_ch, 8  , 4  ) # Osc 2 PW Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 103, 4  ) # Osc 2 PW Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 115, 4  ) # Noise 1 Color
  C.set_midi_cc_value(midi_ch, 21 , 4  ) # Mixer 2 Balance 1/2
  C.set_midi_cc_value(midi_ch, 23 , 4  ) # Mixer 2 Level 3
  C.set_midi_cc_value(midi_ch, 112, 64 ) # Filter 1 Gain
  C.set_midi_cc_value(midi_ch, 74 , 100) # Filter 1 Cutoff
  C.set_midi_cc_value(midi_ch, 24 , 28 ) # Filter 1 Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 25 , 4  ) # Filter 1 Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 9  , 4  ) # Filter 1 Mod 3 Amt
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
