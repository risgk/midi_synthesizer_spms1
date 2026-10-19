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
SIGNAL_LFO_1_OUTPUT          = 22
SIGNAL_LFO_1_OUTPUT_TRIANGLE = 23
SIGNAL_LFO_1_OUTPUT_SQUARE   = 24
SIGNAL_MIXER_1_OUTPUT        = 25
SIGNAL_PITCH_1_OUTPUT        = 26
SIGNAL_OSC_1_OUTPUT          = 27
SIGNAL_OSC_1_OUTPUT_SAW      = 28
SIGNAL_OSC_1_OUTPUT_PULSE    = 29
SIGNAL_OSC_2_OUTPUT          = 30
SIGNAL_OSC_2_OUTPUT_SAW      = 31
SIGNAL_OSC_2_OUTPUT_PULSE    = 32
SIGNAL_NOISE_1_OUTPUT        = 33
SIGNAL_NOISE_1_OUTPUT_WHITE  = 34
SIGNAL_NOISE_1_OUTPUT_RED    = 35
SIGNAL_MIXER_2_OUTPUT        = 36
SIGNAL_FILTER_1_OUTPUT       = 37
SIGNAL_FILTER_1_OUTPUT_LP    = 38
SIGNAL_FILTER_1_OUTPUT_HP    = 39
SIGNAL_AMP_1_OUTPUT          = 40
SIGNAL_CHORUS_1_OUTPUT_L     = 41
SIGNAL_CHORUS_1_OUTPUT_R     = 42
SIGNAL_CHORUS_1_OUTPUT_MONO  = 43
SIGNAL_DELAY_1_OUTPUT_L      = 44
SIGNAL_DELAY_1_OUTPUT_R      = 45
SIGNAL_DELAY_1_OUTPUT_MONO   = 46

# A parameter source of SIGNAL_OWN is the parameter's own control slot, at PARAM_SLOT_BASE + its
# entry, off the bus: the slots below.
SIGNAL_OWN      = 127
PARAM_SLOT_BASE = 128

SLOT_EG_1_ATTACK         = 128
SLOT_EG_1_DECAY          = 129
SLOT_EG_1_SUSTAIN        = 130
SLOT_EG_1_RELEASE_SW     = 131
SLOT_EG_1_LEVEL          = 132
SLOT_LFO_1_RATE          = 133
SLOT_LFO_1_RATE_MOD_AMT  = 134
SLOT_LFO_1_RATE_MOD_POL  = 135
SLOT_LFO_1_LEVEL         = 136
SLOT_LFO_1_WAVE          = 137
SLOT_LFO_1_LEVEL_MOD_AMT = 138
SLOT_LFO_1_LEVEL_MOD_POL = 139
SLOT_MIXER_1_LEVEL_1     = 140
SLOT_MIXER_1_POL_1       = 141
SLOT_MIXER_1_LEVEL_2     = 142
SLOT_MIXER_1_POL_2       = 143
SLOT_MIXER_1_LEVEL_3     = 144
SLOT_MIXER_1_POL_3       = 145
SLOT_MIXER_1_OUT_LEVEL   = 146
SLOT_PITCH_1_GLIDE       = 147
SLOT_PITCH_1_GLIDE_SW    = 148
SLOT_PITCH_1_COARSE      = 149
SLOT_PITCH_1_FINE        = 150
SLOT_PITCH_1_STRETCH     = 151
SLOT_PITCH_1_BEND_AMT    = 152
SLOT_PITCH_1_BEND_POL    = 153
SLOT_OSC_1_PITCH_COARSE  = 154
SLOT_OSC_1_PITCH_FINE    = 155
SLOT_OSC_1_MOD_1_AMT     = 156
SLOT_OSC_1_MOD_1_POL     = 157
SLOT_OSC_1_MOD_2_AMT     = 158
SLOT_OSC_1_MOD_2_POL     = 159
SLOT_OSC_1_WAVE          = 160
SLOT_OSC_1_PULSE_WIDTH   = 161
SLOT_OSC_1_PW_MOD_1_AMT  = 162
SLOT_OSC_1_PW_MOD_1_POL  = 163
SLOT_OSC_1_PW_MOD_2_AMT  = 164
SLOT_OSC_1_PW_MOD_2_POL  = 165
SLOT_OSC_2_PITCH_COARSE  = 166
SLOT_OSC_2_PITCH_FINE    = 167
SLOT_OSC_2_MOD_1_AMT     = 168
SLOT_OSC_2_MOD_1_POL     = 169
SLOT_OSC_2_MOD_2_AMT     = 170
SLOT_OSC_2_MOD_2_POL     = 171
SLOT_OSC_2_WAVE          = 172
SLOT_OSC_2_PULSE_WIDTH   = 173
SLOT_OSC_2_PW_MOD_1_AMT  = 174
SLOT_OSC_2_PW_MOD_1_POL  = 175
SLOT_OSC_2_PW_MOD_2_AMT  = 176
SLOT_OSC_2_PW_MOD_2_POL  = 177
SLOT_NOISE_1_LEVEL       = 178
SLOT_NOISE_1_COLOR       = 179
SLOT_MIXER_2_LEVEL_1     = 180
SLOT_MIXER_2_POL_1       = 181
SLOT_MIXER_2_LEVEL_2     = 182
SLOT_MIXER_2_POL_2       = 183
SLOT_MIXER_2_LEVEL_3     = 184
SLOT_MIXER_2_POL_3       = 185
SLOT_MIXER_2_OUT_LEVEL   = 186
SLOT_FILTER_1_GAIN       = 187
SLOT_FILTER_1_CUTOFF     = 188
SLOT_FILTER_1_MOD_1_AMT  = 189
SLOT_FILTER_1_MOD_1_POL  = 190
SLOT_FILTER_1_MOD_2_AMT  = 191
SLOT_FILTER_1_MOD_2_POL  = 192
SLOT_FILTER_1_MOD_3_AMT  = 193
SLOT_FILTER_1_MOD_3_POL  = 194
SLOT_FILTER_1_RESONANCE  = 195
SLOT_FILTER_1_MODE       = 196
SLOT_AMP_1_GAIN          = 197
SLOT_AMP_1_GAIN_POL      = 198
SLOT_CHORUS_1_MIX        = 199
SLOT_CHORUS_1_RATE       = 200
SLOT_CHORUS_1_DEPTH      = 201
SLOT_DELAY_1_MIX         = 202
SLOT_DELAY_1_TIME        = 203
SLOT_DELAY_1_FEEDBACK    = 204

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
NRPN_SOURCE_FILTER_1_MOD_1  = 146
NRPN_SOURCE_FILTER_1_MOD_2  = 147
NRPN_SOURCE_FILTER_1_MOD_3  = 148
NRPN_SOURCE_AMP_1_AUDIO     = 149
NRPN_SOURCE_AMP_1_MOD       = 150
NRPN_SOURCE_CHORUS_1_AUDIO  = 151
NRPN_SOURCE_DELAY_1_AUDIO_L = 152
NRPN_SOURCE_DELAY_1_AUDIO_R = 153
NRPN_SOURCE_OUTPUT_L        = 154
NRPN_SOURCE_OUTPUT_R        = 155

NRPN_SOURCE_EG_1_ATTACK         = 256
NRPN_SOURCE_EG_1_DECAY          = 257
NRPN_SOURCE_EG_1_SUSTAIN        = 258
NRPN_SOURCE_EG_1_RELEASE_SW     = 259
NRPN_SOURCE_EG_1_LEVEL          = 260
NRPN_SOURCE_LFO_1_RATE          = 261
NRPN_SOURCE_LFO_1_RATE_MOD_AMT  = 262
NRPN_SOURCE_LFO_1_RATE_MOD_POL  = 263
NRPN_SOURCE_LFO_1_LEVEL         = 264
NRPN_SOURCE_LFO_1_WAVE          = 265
NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT = 266
NRPN_SOURCE_LFO_1_LEVEL_MOD_POL = 267
NRPN_SOURCE_MIXER_1_LEVEL_1     = 268
NRPN_SOURCE_MIXER_1_POL_1       = 269
NRPN_SOURCE_MIXER_1_LEVEL_2     = 270
NRPN_SOURCE_MIXER_1_POL_2       = 271
NRPN_SOURCE_MIXER_1_LEVEL_3     = 272
NRPN_SOURCE_MIXER_1_POL_3       = 273
NRPN_SOURCE_MIXER_1_OUT_LEVEL   = 274
NRPN_SOURCE_PITCH_1_GLIDE       = 275
NRPN_SOURCE_PITCH_1_GLIDE_SW    = 276
NRPN_SOURCE_PITCH_1_COARSE      = 277
NRPN_SOURCE_PITCH_1_FINE        = 278
NRPN_SOURCE_PITCH_1_STRETCH     = 279
NRPN_SOURCE_PITCH_1_BEND_AMT    = 280
NRPN_SOURCE_PITCH_1_BEND_POL    = 281
NRPN_SOURCE_OSC_1_PITCH_COARSE  = 282
NRPN_SOURCE_OSC_1_PITCH_FINE    = 283
NRPN_SOURCE_OSC_1_MOD_1_AMT     = 284
NRPN_SOURCE_OSC_1_MOD_1_POL     = 285
NRPN_SOURCE_OSC_1_MOD_2_AMT     = 286
NRPN_SOURCE_OSC_1_MOD_2_POL     = 287
NRPN_SOURCE_OSC_1_WAVE          = 288
NRPN_SOURCE_OSC_1_PULSE_WIDTH   = 289
NRPN_SOURCE_OSC_1_PW_MOD_1_AMT  = 290
NRPN_SOURCE_OSC_1_PW_MOD_1_POL  = 291
NRPN_SOURCE_OSC_1_PW_MOD_2_AMT  = 292
NRPN_SOURCE_OSC_1_PW_MOD_2_POL  = 293
NRPN_SOURCE_OSC_2_PITCH_COARSE  = 294
NRPN_SOURCE_OSC_2_PITCH_FINE    = 295
NRPN_SOURCE_OSC_2_MOD_1_AMT     = 296
NRPN_SOURCE_OSC_2_MOD_1_POL     = 297
NRPN_SOURCE_OSC_2_MOD_2_AMT     = 298
NRPN_SOURCE_OSC_2_MOD_2_POL     = 299
NRPN_SOURCE_OSC_2_WAVE          = 300
NRPN_SOURCE_OSC_2_PULSE_WIDTH   = 301
NRPN_SOURCE_OSC_2_PW_MOD_1_AMT  = 302
NRPN_SOURCE_OSC_2_PW_MOD_1_POL  = 303
NRPN_SOURCE_OSC_2_PW_MOD_2_AMT  = 304
NRPN_SOURCE_OSC_2_PW_MOD_2_POL  = 305
NRPN_SOURCE_NOISE_1_LEVEL       = 306
NRPN_SOURCE_NOISE_1_COLOR       = 307
NRPN_SOURCE_MIXER_2_LEVEL_1     = 308
NRPN_SOURCE_MIXER_2_POL_1       = 309
NRPN_SOURCE_MIXER_2_LEVEL_2     = 310
NRPN_SOURCE_MIXER_2_POL_2       = 311
NRPN_SOURCE_MIXER_2_LEVEL_3     = 312
NRPN_SOURCE_MIXER_2_POL_3       = 313
NRPN_SOURCE_MIXER_2_OUT_LEVEL   = 314
NRPN_SOURCE_FILTER_1_GAIN       = 315
NRPN_SOURCE_FILTER_1_CUTOFF     = 316
NRPN_SOURCE_FILTER_1_MOD_1_AMT  = 317
NRPN_SOURCE_FILTER_1_MOD_1_POL  = 318
NRPN_SOURCE_FILTER_1_MOD_2_AMT  = 319
NRPN_SOURCE_FILTER_1_MOD_2_POL  = 320
NRPN_SOURCE_FILTER_1_MOD_3_AMT  = 321
NRPN_SOURCE_FILTER_1_MOD_3_POL  = 322
NRPN_SOURCE_FILTER_1_RESONANCE  = 323
NRPN_SOURCE_FILTER_1_MODE       = 324
NRPN_SOURCE_AMP_1_GAIN          = 325
NRPN_SOURCE_AMP_1_GAIN_POL      = 326
NRPN_SOURCE_CHORUS_1_MIX        = 327
NRPN_SOURCE_CHORUS_1_RATE       = 328
NRPN_SOURCE_CHORUS_1_DEPTH      = 329
NRPN_SOURCE_DELAY_1_MIX         = 330
NRPN_SOURCE_DELAY_1_TIME        = 331
NRPN_SOURCE_DELAY_1_FEEDBACK    = 332

# A CC number of 0 means the parameter has no CC: its control slot holds 0.0 -- the bottom of a
# unipolar dial, the middle of a bipolar one -- whatever CC it had before, so a patch sets it alone.
NRPN_CC_EG_1_ATTACK         = 384
NRPN_CC_EG_1_DECAY          = 385
NRPN_CC_EG_1_SUSTAIN        = 386
NRPN_CC_EG_1_RELEASE_SW     = 387
NRPN_CC_EG_1_LEVEL          = 388
NRPN_CC_LFO_1_RATE          = 389
NRPN_CC_LFO_1_RATE_MOD_AMT  = 390
NRPN_CC_LFO_1_RATE_MOD_POL  = 391
NRPN_CC_LFO_1_LEVEL         = 392
NRPN_CC_LFO_1_WAVE          = 393
NRPN_CC_LFO_1_LEVEL_MOD_AMT = 394
NRPN_CC_LFO_1_LEVEL_MOD_POL = 395
NRPN_CC_MIXER_1_LEVEL_1     = 396
NRPN_CC_MIXER_1_POL_1       = 397
NRPN_CC_MIXER_1_LEVEL_2     = 398
NRPN_CC_MIXER_1_POL_2       = 399
NRPN_CC_MIXER_1_LEVEL_3     = 400
NRPN_CC_MIXER_1_POL_3       = 401
NRPN_CC_MIXER_1_OUT_LEVEL   = 402
NRPN_CC_PITCH_1_GLIDE       = 403
NRPN_CC_PITCH_1_GLIDE_SW    = 404
NRPN_CC_PITCH_1_COARSE      = 405
NRPN_CC_PITCH_1_FINE        = 406
NRPN_CC_PITCH_1_STRETCH     = 407
NRPN_CC_PITCH_1_BEND_AMT    = 408
NRPN_CC_PITCH_1_BEND_POL    = 409
NRPN_CC_OSC_1_PITCH_COARSE  = 410
NRPN_CC_OSC_1_PITCH_FINE    = 411
NRPN_CC_OSC_1_MOD_1_AMT     = 412
NRPN_CC_OSC_1_MOD_1_POL     = 413
NRPN_CC_OSC_1_MOD_2_AMT     = 414
NRPN_CC_OSC_1_MOD_2_POL     = 415
NRPN_CC_OSC_1_WAVE          = 416
NRPN_CC_OSC_1_PULSE_WIDTH   = 417
NRPN_CC_OSC_1_PW_MOD_1_AMT  = 418
NRPN_CC_OSC_1_PW_MOD_1_POL  = 419
NRPN_CC_OSC_1_PW_MOD_2_AMT  = 420
NRPN_CC_OSC_1_PW_MOD_2_POL  = 421
NRPN_CC_OSC_2_PITCH_COARSE  = 422
NRPN_CC_OSC_2_PITCH_FINE    = 423
NRPN_CC_OSC_2_MOD_1_AMT     = 424
NRPN_CC_OSC_2_MOD_1_POL     = 425
NRPN_CC_OSC_2_MOD_2_AMT     = 426
NRPN_CC_OSC_2_MOD_2_POL     = 427
NRPN_CC_OSC_2_WAVE          = 428
NRPN_CC_OSC_2_PULSE_WIDTH   = 429
NRPN_CC_OSC_2_PW_MOD_1_AMT  = 430
NRPN_CC_OSC_2_PW_MOD_1_POL  = 431
NRPN_CC_OSC_2_PW_MOD_2_AMT  = 432
NRPN_CC_OSC_2_PW_MOD_2_POL  = 433
NRPN_CC_NOISE_1_LEVEL       = 434
NRPN_CC_NOISE_1_COLOR       = 435
NRPN_CC_MIXER_2_LEVEL_1     = 436
NRPN_CC_MIXER_2_POL_1       = 437
NRPN_CC_MIXER_2_LEVEL_2     = 438
NRPN_CC_MIXER_2_POL_2       = 439
NRPN_CC_MIXER_2_LEVEL_3     = 440
NRPN_CC_MIXER_2_POL_3       = 441
NRPN_CC_MIXER_2_OUT_LEVEL   = 442
NRPN_CC_FILTER_1_GAIN       = 443
NRPN_CC_FILTER_1_CUTOFF     = 444
NRPN_CC_FILTER_1_MOD_1_AMT  = 445
NRPN_CC_FILTER_1_MOD_1_POL  = 446
NRPN_CC_FILTER_1_MOD_2_AMT  = 447
NRPN_CC_FILTER_1_MOD_2_POL  = 448
NRPN_CC_FILTER_1_MOD_3_AMT  = 449
NRPN_CC_FILTER_1_MOD_3_POL  = 450
NRPN_CC_FILTER_1_RESONANCE  = 451
NRPN_CC_FILTER_1_MODE       = 452
NRPN_CC_AMP_1_GAIN          = 453
NRPN_CC_AMP_1_GAIN_POL      = 454
NRPN_CC_CHORUS_1_MIX        = 455
NRPN_CC_CHORUS_1_RATE       = 456
NRPN_CC_CHORUS_1_DEPTH      = 457
NRPN_CC_DELAY_1_MIX         = 458
NRPN_CC_DELAY_1_TIME        = 459
NRPN_CC_DELAY_1_FEEDBACK    = 460
NRPN_CC_GENERAL_MOD_WHEEL   = 461
NRPN_CC_GENERAL_1           = 462
NRPN_CC_GENERAL_2           = 463
NRPN_CC_GENERAL_3           = 464
NRPN_CC_GENERAL_4           = 465

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
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_RELEASE_SW    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_LEVEL         , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_AMT , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_POL , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_WAVE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT, SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_POL, SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_1    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_1      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_2    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_2      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_LEVEL_3    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_POL_3      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_OUT_LEVEL  , SIGNAL_ONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_GLIDE      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_GLIDE_SW   , SIGNAL_OWN)
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
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_1    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_1      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_2    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_2      , SIGNAL_HALF)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_3    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_POL_3      , SIGNAL_HALF)
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

  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_ATTACK       , 73)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_DECAY        , 75)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_SUSTAIN      , 30)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_EG_1_RELEASE_SW   , 105)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_RATE        , 3)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_LEVEL       , 113)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_LFO_1_WAVE        , 33)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_1_LEVEL_1   , 118)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_1_LEVEL_2   , 119)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_GLIDE     , 5)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_GLIDE_SW  , 34)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_COARSE    , 86)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_FINE      , 70)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_STRETCH   , 22)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_PITCH_1_BEND_AMT  , 57)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_MOD_1_AMT   , 89)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_MOD_2_AMT   , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_WAVE        , 102)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PULSE_WIDTH , 114)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_1_AMT, 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_2_AMT, 103)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_COARSE, 85)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_FINE  , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_MOD_1_AMT   , 89)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_MOD_2_AMT   , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_WAVE        , 104)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PULSE_WIDTH , 114)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PW_MOD_1_AMT, 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PW_MOD_2_AMT, 103)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_NOISE_1_COLOR     , 115)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_1   , 116)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_2   , 21)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_3   , 23)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_GAIN     , 112)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_CUTOFF   , 74)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_1_AMT, 24)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_2_AMT, 25)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_3_AMT, 9)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_RESONANCE, 71)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MODE     , 39)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_AMP_1_GAIN        , 15)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_MIX      , 93)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_RATE     , 58)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_DEPTH    , 59)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_MIX       , 94)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_TIME      , 90)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_FEEDBACK  , 92)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_MOD_WHEEL , 1)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_1         , 16)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_2         , 17)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_3         , 18)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_4         , 19)

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
  C.set_midi_cc_value(midi_ch, 116, 124) # Mixer 2 Level 1
  C.set_midi_cc_value(midi_ch, 21 , 4  ) # Mixer 2 Level 2
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
