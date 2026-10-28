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
MODULE_FILTER_2 = 11
MODULE_AMP_1    = 12
MODULE_CHORUS_1 = 13
MODULE_DELAY_1  = 14

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
SIGNAL_MOD_WHEEL_REV             = 9
SIGNAL_MOD_WHEEL_INV             = 10
SIGNAL_MOD_WHEEL_REV_INV         = 11
SIGNAL_BREATH                    = 12
SIGNAL_BREATH_REV                = 13
SIGNAL_BREATH_INV                = 14
SIGNAL_BREATH_REV_INV            = 15
SIGNAL_GENERAL_1                 = 16
SIGNAL_GENERAL_1_REV             = 17
SIGNAL_GENERAL_1_INV             = 18
SIGNAL_GENERAL_1_REV_INV         = 19
SIGNAL_GENERAL_1_BIPOLAR         = 20
SIGNAL_GENERAL_1_BIPOLAR_INV     = 21
SIGNAL_GENERAL_1_COS             = 22
SIGNAL_GENERAL_1_SIN             = 23
SIGNAL_GENERAL_1_LO              = 24
SIGNAL_GENERAL_1_HI              = 25
SIGNAL_GENERAL_1_NEG             = 26
SIGNAL_GENERAL_1_MID             = 27
SIGNAL_GENERAL_1_POS             = 28
SIGNAL_GENERAL_2                 = 29
SIGNAL_GENERAL_2_REV             = 30
SIGNAL_GENERAL_2_INV             = 31
SIGNAL_GENERAL_2_REV_INV         = 32
SIGNAL_GENERAL_2_BIPOLAR         = 33
SIGNAL_GENERAL_2_BIPOLAR_INV     = 34
SIGNAL_GENERAL_2_COS             = 35
SIGNAL_GENERAL_2_SIN             = 36
SIGNAL_GENERAL_2_LO              = 37
SIGNAL_GENERAL_2_HI              = 38
SIGNAL_GENERAL_2_NEG             = 39
SIGNAL_GENERAL_2_MID             = 40
SIGNAL_GENERAL_2_POS             = 41
SIGNAL_PITCH_1_OUTPUT_1          = 42
SIGNAL_PITCH_1_OUTPUT_2          = 43
SIGNAL_EG_1_OUTPUT               = 44
SIGNAL_EG_1_OUTPUT_INV           = 45
SIGNAL_EG_2_OUTPUT               = 46
SIGNAL_EG_2_OUTPUT_INV           = 47
SIGNAL_LFO_1_OUTPUT              = 48
SIGNAL_LFO_1_OUTPUT_INV          = 49
SIGNAL_LFO_1_OUTPUT_TRIANGLE     = 50
SIGNAL_LFO_1_OUTPUT_TRIANGLE_INV = 51
SIGNAL_LFO_1_OUTPUT_SQUARE       = 52
SIGNAL_LFO_1_OUTPUT_SQUARE_INV   = 53
SIGNAL_MIXER_1_OUTPUT            = 54
SIGNAL_MIXER_1_OUTPUT_INV        = 55
SIGNAL_OSC_1_OUTPUT              = 56
SIGNAL_OSC_1_OUTPUT_SAW          = 57
SIGNAL_OSC_1_OUTPUT_PULSE        = 58
SIGNAL_OSC_1_OUTPUT_SUB          = 59
SIGNAL_OSC_2_OUTPUT              = 60
SIGNAL_OSC_2_OUTPUT_SAW          = 61
SIGNAL_OSC_2_OUTPUT_PULSE        = 62
SIGNAL_NOISE_1_OUTPUT            = 63
SIGNAL_NOISE_1_OUTPUT_WHITE      = 64
SIGNAL_NOISE_1_OUTPUT_RED        = 65
SIGNAL_MIXER_2_OUTPUT            = 66
SIGNAL_MIXER_2_OUTPUT_INV        = 67
SIGNAL_FILTER_1_OUTPUT           = 68
SIGNAL_FILTER_1_OUTPUT_LP        = 69
SIGNAL_FILTER_1_OUTPUT_HP        = 70
SIGNAL_FILTER_1_OUTPUT_BP        = 71
SIGNAL_FILTER_2_OUTPUT           = 72
SIGNAL_FILTER_2_OUTPUT_LP        = 73
SIGNAL_FILTER_2_OUTPUT_HP        = 74
SIGNAL_FILTER_2_OUTPUT_BP        = 75
SIGNAL_AMP_1_OUTPUT              = 76
SIGNAL_CHORUS_1_OUTPUT_L         = 77
SIGNAL_CHORUS_1_OUTPUT_R         = 78
SIGNAL_CHORUS_1_OUTPUT_MONO      = 79
SIGNAL_DELAY_1_OUTPUT_L          = 80
SIGNAL_DELAY_1_OUTPUT_R          = 81
SIGNAL_DELAY_1_OUTPUT_MONO       = 82

# A parameter source of SIGNAL_OWN is the parameter's own control slot, at PARAM_SLOT_BASE + its
# entry, off the bus: the slots below.
SIGNAL_OWN      = 127
PARAM_SLOT_BASE = 128

SLOT_PITCH_1_GLIDE          = 128
SLOT_PITCH_1_OUT_1_GLIDE_SW = 129
SLOT_PITCH_1_OUT_2_GLIDE_SW = 130
SLOT_PITCH_1_BEND_AMT       = 131
SLOT_PITCH_1_BEND_POL       = 132
SLOT_PITCH_1_OUT_1_BEND_SW  = 133
SLOT_PITCH_1_OUT_2_BEND_SW  = 134
SLOT_PITCH_1_STRETCH        = 135
SLOT_EG_1_ATTACK            = 136
SLOT_EG_1_DECAY             = 137
SLOT_EG_1_SUSTAIN           = 138
SLOT_EG_1_RELEASE_SW        = 139
SLOT_EG_1_LEVEL             = 140
SLOT_EG_2_ATTACK            = 141
SLOT_EG_2_DECAY             = 142
SLOT_EG_2_SUSTAIN           = 143
SLOT_EG_2_RELEASE_SW        = 144
SLOT_EG_2_LEVEL             = 145
SLOT_LFO_1_WAVE             = 146
SLOT_LFO_1_RATE             = 147
SLOT_LFO_1_LEVEL            = 148
SLOT_LFO_1_RATE_MOD_AMT     = 149
SLOT_LFO_1_LEVEL_MOD_AMT    = 150
SLOT_LFO_1_RESET_SW         = 151
SLOT_MIXER_1_LEVEL_1        = 152
SLOT_MIXER_1_LEVEL_2        = 153
SLOT_MIXER_1_LEVEL_3        = 154
SLOT_MIXER_1_LEVEL_4        = 155
SLOT_MIXER_1_OUT_LEVEL      = 156
SLOT_OSC_1_WAVE             = 157
SLOT_OSC_1_PW               = 158
SLOT_OSC_1_PITCH_COARSE     = 159
SLOT_OSC_1_PITCH_FINE       = 160
SLOT_OSC_1_PITCH_MOD_1_AMT  = 161
SLOT_OSC_1_PITCH_MOD_1_POL  = 162
SLOT_OSC_1_PITCH_MOD_1_SW   = 163
SLOT_OSC_1_PITCH_MOD_2_AMT  = 164
SLOT_OSC_1_PITCH_MOD_2_POL  = 165
SLOT_OSC_1_PITCH_MOD_2_SW   = 166
SLOT_OSC_1_PW_MOD_1_AMT     = 167
SLOT_OSC_1_PW_MOD_1_POL     = 168
SLOT_OSC_1_PW_MOD_2_AMT     = 169
SLOT_OSC_1_PW_MOD_2_POL     = 170
SLOT_OSC_2_WAVE             = 171
SLOT_OSC_2_PW               = 172
SLOT_OSC_2_PITCH_COARSE     = 173
SLOT_OSC_2_PITCH_FINE       = 174
SLOT_OSC_2_PITCH_MOD_1_AMT  = 175
SLOT_OSC_2_PITCH_MOD_1_POL  = 176
SLOT_OSC_2_PITCH_MOD_1_SW   = 177
SLOT_OSC_2_PITCH_MOD_2_AMT  = 178
SLOT_OSC_2_PITCH_MOD_2_POL  = 179
SLOT_OSC_2_PITCH_MOD_2_SW   = 180
SLOT_OSC_2_PW_MOD_1_AMT     = 181
SLOT_OSC_2_PW_MOD_1_POL     = 182
SLOT_OSC_2_PW_MOD_2_AMT     = 183
SLOT_OSC_2_PW_MOD_2_POL     = 184
SLOT_OSC_2_SYNC_SW          = 185
SLOT_NOISE_1_COLOR          = 186
SLOT_NOISE_1_LEVEL          = 187
SLOT_MIXER_2_LEVEL_1        = 188
SLOT_MIXER_2_LEVEL_2        = 189
SLOT_MIXER_2_LEVEL_3        = 190
SLOT_MIXER_2_LEVEL_4        = 191
SLOT_MIXER_2_OUT_LEVEL      = 192
SLOT_FILTER_1_MODE          = 193
SLOT_FILTER_1_CUTOFF        = 194
SLOT_FILTER_1_RESONANCE     = 195
SLOT_FILTER_1_GAIN_1        = 196
SLOT_FILTER_1_GAIN_2        = 197
SLOT_FILTER_1_PITCH_AMT     = 198
SLOT_FILTER_1_PITCH_POL     = 199
SLOT_FILTER_1_MOD_1_AMT     = 200
SLOT_FILTER_1_MOD_1_POL     = 201
SLOT_FILTER_1_MOD_2_AMT     = 202
SLOT_FILTER_1_MOD_2_POL     = 203
SLOT_FILTER_2_MODE          = 204
SLOT_FILTER_2_CUTOFF        = 205
SLOT_FILTER_2_RESONANCE     = 206
SLOT_FILTER_2_GAIN_1        = 207
SLOT_FILTER_2_GAIN_2        = 208
SLOT_FILTER_2_PITCH_AMT     = 209
SLOT_FILTER_2_PITCH_POL     = 210
SLOT_FILTER_2_MOD_1_AMT     = 211
SLOT_FILTER_2_MOD_1_POL     = 212
SLOT_FILTER_2_MOD_2_AMT     = 213
SLOT_FILTER_2_MOD_2_POL     = 214
SLOT_AMP_1_GAIN_1           = 215
SLOT_AMP_1_GAIN_2           = 216
SLOT_AMP_1_MOD_1_2_MIX      = 217
SLOT_CHORUS_1_MIX           = 218
SLOT_CHORUS_1_RATE          = 219
SLOT_CHORUS_1_DEPTH         = 220
SLOT_DELAY_1_MIX            = 221
SLOT_DELAY_1_TIME           = 222
SLOT_DELAY_1_FEEDBACK       = 223
SLOT_AMP_1_LIMITER_SW       = 228

# The controller slots, the mod wheel's and the general controls', and where a smoothed copy of each
# sits, off the bus at its slot + SMOOTHED_SLOT_OFFSET, with each controller's first smoothing
# stage above them. A module input reads the copy (see spms1_main.rb).
CONTROLLER_SLOT_FIRST      = 8
CONTROLLER_SLOT_LAST       = 41
SMOOTHED_SLOT_OFFSET       = 466
SMOOTHED_STAGE_1_MOD_WHEEL = 508
SMOOTHED_STAGE_1_BREATH    = 509
SMOOTHED_STAGE_1_GENERAL_1 = 510
SMOOTHED_STAGE_1_GENERAL_2 = 511

# NRPN parameter numbers: (category << 7) | LSB, where the MSB, 112 + category, picks a category
# and the LSB an entry.
#   0..127   the run order, the module of each slot
# 128..255   what feeds each module input
# 256..383   where each parameter's value comes from
# 384..511   which CC fills each control slot
# 512..639   the value of each parameter's control slot while it has no CC
NRPN_ACTIVE_MODULE_BASE = 0

NRPN_SOURCE_PITCH_1_PITCH_IN     = 128
NRPN_SOURCE_PITCH_1_GATE_IN      = 129
NRPN_SOURCE_PITCH_1_BEND_IN      = 130
NRPN_SOURCE_EG_1_GATE_IN         = 131
NRPN_SOURCE_EG_2_GATE_IN         = 132
NRPN_SOURCE_LFO_1_RATE_MOD_IN    = 133
NRPN_SOURCE_LFO_1_LEVEL_MOD_IN   = 134
NRPN_SOURCE_LFO_1_RESET_IN       = 135
NRPN_SOURCE_MIXER_1_IN_1         = 136
NRPN_SOURCE_MIXER_1_IN_2         = 137
NRPN_SOURCE_MIXER_1_IN_3         = 138
NRPN_SOURCE_MIXER_1_IN_4         = 139
NRPN_SOURCE_OSC_1_PITCH_IN       = 140
NRPN_SOURCE_OSC_1_PITCH_MOD_1_IN = 141
NRPN_SOURCE_OSC_1_PITCH_MOD_2_IN = 142
NRPN_SOURCE_OSC_1_PW_MOD_1_IN    = 143
NRPN_SOURCE_OSC_1_PW_MOD_2_IN    = 144
NRPN_SOURCE_OSC_2_PITCH_IN       = 145
NRPN_SOURCE_OSC_2_PITCH_MOD_1_IN = 146
NRPN_SOURCE_OSC_2_PITCH_MOD_2_IN = 147
NRPN_SOURCE_OSC_2_PW_MOD_1_IN    = 148
NRPN_SOURCE_OSC_2_PW_MOD_2_IN    = 149
NRPN_SOURCE_OSC_2_SYNC_IN        = 150
NRPN_SOURCE_MIXER_2_IN_1         = 151
NRPN_SOURCE_MIXER_2_IN_2         = 152
NRPN_SOURCE_MIXER_2_IN_3         = 153
NRPN_SOURCE_MIXER_2_IN_4         = 154
NRPN_SOURCE_FILTER_1_AUDIO_IN_1  = 155
NRPN_SOURCE_FILTER_1_AUDIO_IN_2  = 156
NRPN_SOURCE_FILTER_1_PITCH_IN    = 157
NRPN_SOURCE_FILTER_1_MOD_1_IN    = 158
NRPN_SOURCE_FILTER_1_MOD_2_IN    = 159
NRPN_SOURCE_FILTER_2_AUDIO_IN_1  = 160
NRPN_SOURCE_FILTER_2_AUDIO_IN_2  = 161
NRPN_SOURCE_FILTER_2_PITCH_IN    = 162
NRPN_SOURCE_FILTER_2_MOD_1_IN    = 163
NRPN_SOURCE_FILTER_2_MOD_2_IN    = 164
NRPN_SOURCE_AMP_1_AUDIO_IN_1     = 165
NRPN_SOURCE_AMP_1_AUDIO_IN_2     = 166
NRPN_SOURCE_AMP_1_MOD_1_IN       = 167
NRPN_SOURCE_AMP_1_MOD_2_IN       = 168
NRPN_SOURCE_CHORUS_1_AUDIO_IN    = 169
NRPN_SOURCE_DELAY_1_AUDIO_IN_L   = 170
NRPN_SOURCE_DELAY_1_AUDIO_IN_R   = 171
NRPN_SOURCE_OUTPUT_L             = 172
NRPN_SOURCE_OUTPUT_R             = 173

NRPN_SOURCE_PITCH_1_GLIDE          = 256
NRPN_SOURCE_PITCH_1_OUT_1_GLIDE_SW = 257
NRPN_SOURCE_PITCH_1_OUT_2_GLIDE_SW = 258
NRPN_SOURCE_PITCH_1_BEND_AMT       = 259
NRPN_SOURCE_PITCH_1_BEND_POL       = 260
NRPN_SOURCE_PITCH_1_OUT_1_BEND_SW  = 261
NRPN_SOURCE_PITCH_1_OUT_2_BEND_SW  = 262
NRPN_SOURCE_PITCH_1_STRETCH        = 263
NRPN_SOURCE_EG_1_ATTACK            = 264
NRPN_SOURCE_EG_1_DECAY             = 265
NRPN_SOURCE_EG_1_SUSTAIN           = 266
NRPN_SOURCE_EG_1_RELEASE_SW        = 267
NRPN_SOURCE_EG_1_LEVEL             = 268
NRPN_SOURCE_EG_2_ATTACK            = 269
NRPN_SOURCE_EG_2_DECAY             = 270
NRPN_SOURCE_EG_2_SUSTAIN           = 271
NRPN_SOURCE_EG_2_RELEASE_SW        = 272
NRPN_SOURCE_EG_2_LEVEL             = 273
NRPN_SOURCE_LFO_1_WAVE             = 274
NRPN_SOURCE_LFO_1_RATE             = 275
NRPN_SOURCE_LFO_1_LEVEL            = 276
NRPN_SOURCE_LFO_1_RATE_MOD_AMT     = 277
NRPN_SOURCE_LFO_1_LEVEL_MOD_AMT    = 278
NRPN_SOURCE_LFO_1_RESET_SW         = 279
NRPN_SOURCE_MIXER_1_LEVEL_1        = 280
NRPN_SOURCE_MIXER_1_LEVEL_2        = 281
NRPN_SOURCE_MIXER_1_LEVEL_3        = 282
NRPN_SOURCE_MIXER_1_LEVEL_4        = 283
NRPN_SOURCE_MIXER_1_OUT_LEVEL      = 284
NRPN_SOURCE_OSC_1_WAVE             = 285
NRPN_SOURCE_OSC_1_PW               = 286
NRPN_SOURCE_OSC_1_PITCH_COARSE     = 287
NRPN_SOURCE_OSC_1_PITCH_FINE       = 288
NRPN_SOURCE_OSC_1_PITCH_MOD_1_AMT  = 289
NRPN_SOURCE_OSC_1_PITCH_MOD_1_POL  = 290
NRPN_SOURCE_OSC_1_PITCH_MOD_1_SW   = 291
NRPN_SOURCE_OSC_1_PITCH_MOD_2_AMT  = 292
NRPN_SOURCE_OSC_1_PITCH_MOD_2_POL  = 293
NRPN_SOURCE_OSC_1_PITCH_MOD_2_SW   = 294
NRPN_SOURCE_OSC_1_PW_MOD_1_AMT     = 295
NRPN_SOURCE_OSC_1_PW_MOD_1_POL     = 296
NRPN_SOURCE_OSC_1_PW_MOD_2_AMT     = 297
NRPN_SOURCE_OSC_1_PW_MOD_2_POL     = 298
NRPN_SOURCE_OSC_2_WAVE             = 299
NRPN_SOURCE_OSC_2_PW               = 300
NRPN_SOURCE_OSC_2_PITCH_COARSE     = 301
NRPN_SOURCE_OSC_2_PITCH_FINE       = 302
NRPN_SOURCE_OSC_2_PITCH_MOD_1_AMT  = 303
NRPN_SOURCE_OSC_2_PITCH_MOD_1_POL  = 304
NRPN_SOURCE_OSC_2_PITCH_MOD_1_SW   = 305
NRPN_SOURCE_OSC_2_PITCH_MOD_2_AMT  = 306
NRPN_SOURCE_OSC_2_PITCH_MOD_2_POL  = 307
NRPN_SOURCE_OSC_2_PITCH_MOD_2_SW   = 308
NRPN_SOURCE_OSC_2_PW_MOD_1_AMT     = 309
NRPN_SOURCE_OSC_2_PW_MOD_1_POL     = 310
NRPN_SOURCE_OSC_2_PW_MOD_2_AMT     = 311
NRPN_SOURCE_OSC_2_PW_MOD_2_POL     = 312
NRPN_SOURCE_OSC_2_SYNC_SW          = 313
NRPN_SOURCE_NOISE_1_COLOR          = 314
NRPN_SOURCE_NOISE_1_LEVEL          = 315
NRPN_SOURCE_MIXER_2_LEVEL_1        = 316
NRPN_SOURCE_MIXER_2_LEVEL_2        = 317
NRPN_SOURCE_MIXER_2_LEVEL_3        = 318
NRPN_SOURCE_MIXER_2_LEVEL_4        = 319
NRPN_SOURCE_MIXER_2_OUT_LEVEL      = 320
NRPN_SOURCE_FILTER_1_MODE          = 321
NRPN_SOURCE_FILTER_1_CUTOFF        = 322
NRPN_SOURCE_FILTER_1_RESONANCE     = 323
NRPN_SOURCE_FILTER_1_GAIN_1        = 324
NRPN_SOURCE_FILTER_1_GAIN_2        = 325
NRPN_SOURCE_FILTER_1_PITCH_AMT     = 326
NRPN_SOURCE_FILTER_1_PITCH_POL     = 327
NRPN_SOURCE_FILTER_1_MOD_1_AMT     = 328
NRPN_SOURCE_FILTER_1_MOD_1_POL     = 329
NRPN_SOURCE_FILTER_1_MOD_2_AMT     = 330
NRPN_SOURCE_FILTER_1_MOD_2_POL     = 331
NRPN_SOURCE_FILTER_2_MODE          = 332
NRPN_SOURCE_FILTER_2_CUTOFF        = 333
NRPN_SOURCE_FILTER_2_RESONANCE     = 334
NRPN_SOURCE_FILTER_2_GAIN_1        = 335
NRPN_SOURCE_FILTER_2_GAIN_2        = 336
NRPN_SOURCE_FILTER_2_PITCH_AMT     = 337
NRPN_SOURCE_FILTER_2_PITCH_POL     = 338
NRPN_SOURCE_FILTER_2_MOD_1_AMT     = 339
NRPN_SOURCE_FILTER_2_MOD_1_POL     = 340
NRPN_SOURCE_FILTER_2_MOD_2_AMT     = 341
NRPN_SOURCE_FILTER_2_MOD_2_POL     = 342
NRPN_SOURCE_AMP_1_GAIN_1           = 343
NRPN_SOURCE_AMP_1_GAIN_2           = 344
NRPN_SOURCE_AMP_1_MOD_1_2_MIX      = 345
NRPN_SOURCE_CHORUS_1_MIX           = 346
NRPN_SOURCE_CHORUS_1_RATE          = 347
NRPN_SOURCE_CHORUS_1_DEPTH         = 348
NRPN_SOURCE_DELAY_1_MIX            = 349
NRPN_SOURCE_DELAY_1_TIME           = 350
NRPN_SOURCE_DELAY_1_FEEDBACK       = 351
NRPN_SOURCE_AMP_1_LIMITER_SW       = 356

# A CC number of 0 means the control has no CC: a parameter's control slot then holds its NRPN_VALUE_*
# below, whatever CC it had before, so a patch sets it alone, as General 1 and 2 do theirs, and
# the Mod Wheel's slot holds 0.0.
NRPN_CC_PITCH_1_GLIDE          = 384
NRPN_CC_PITCH_1_OUT_1_GLIDE_SW = 385
NRPN_CC_PITCH_1_OUT_2_GLIDE_SW = 386
NRPN_CC_PITCH_1_BEND_AMT       = 387
NRPN_CC_PITCH_1_BEND_POL       = 388
NRPN_CC_PITCH_1_OUT_1_BEND_SW  = 389
NRPN_CC_PITCH_1_OUT_2_BEND_SW  = 390
NRPN_CC_PITCH_1_STRETCH        = 391
NRPN_CC_EG_1_ATTACK            = 392
NRPN_CC_EG_1_DECAY             = 393
NRPN_CC_EG_1_SUSTAIN           = 394
NRPN_CC_EG_1_RELEASE_SW        = 395
NRPN_CC_EG_1_LEVEL             = 396
NRPN_CC_EG_2_ATTACK            = 397
NRPN_CC_EG_2_DECAY             = 398
NRPN_CC_EG_2_SUSTAIN           = 399
NRPN_CC_EG_2_RELEASE_SW        = 400
NRPN_CC_EG_2_LEVEL             = 401
NRPN_CC_LFO_1_WAVE             = 402
NRPN_CC_LFO_1_RATE             = 403
NRPN_CC_LFO_1_LEVEL            = 404
NRPN_CC_LFO_1_RATE_MOD_AMT     = 405
NRPN_CC_LFO_1_LEVEL_MOD_AMT    = 406
NRPN_CC_LFO_1_RESET_SW         = 407
NRPN_CC_MIXER_1_LEVEL_1        = 408
NRPN_CC_MIXER_1_LEVEL_2        = 409
NRPN_CC_MIXER_1_LEVEL_3        = 410
NRPN_CC_MIXER_1_LEVEL_4        = 411
NRPN_CC_MIXER_1_OUT_LEVEL      = 412
NRPN_CC_OSC_1_WAVE             = 413
NRPN_CC_OSC_1_PW               = 414
NRPN_CC_OSC_1_PITCH_COARSE     = 415
NRPN_CC_OSC_1_PITCH_FINE       = 416
NRPN_CC_OSC_1_PITCH_MOD_1_AMT  = 417
NRPN_CC_OSC_1_PITCH_MOD_1_POL  = 418
NRPN_CC_OSC_1_PITCH_MOD_1_SW   = 419
NRPN_CC_OSC_1_PITCH_MOD_2_AMT  = 420
NRPN_CC_OSC_1_PITCH_MOD_2_POL  = 421
NRPN_CC_OSC_1_PITCH_MOD_2_SW   = 422
NRPN_CC_OSC_1_PW_MOD_1_AMT     = 423
NRPN_CC_OSC_1_PW_MOD_1_POL     = 424
NRPN_CC_OSC_1_PW_MOD_2_AMT     = 425
NRPN_CC_OSC_1_PW_MOD_2_POL     = 426
NRPN_CC_OSC_2_WAVE             = 427
NRPN_CC_OSC_2_PW               = 428
NRPN_CC_OSC_2_PITCH_COARSE     = 429
NRPN_CC_OSC_2_PITCH_FINE       = 430
NRPN_CC_OSC_2_PITCH_MOD_1_AMT  = 431
NRPN_CC_OSC_2_PITCH_MOD_1_POL  = 432
NRPN_CC_OSC_2_PITCH_MOD_1_SW   = 433
NRPN_CC_OSC_2_PITCH_MOD_2_AMT  = 434
NRPN_CC_OSC_2_PITCH_MOD_2_POL  = 435
NRPN_CC_OSC_2_PITCH_MOD_2_SW   = 436
NRPN_CC_OSC_2_PW_MOD_1_AMT     = 437
NRPN_CC_OSC_2_PW_MOD_1_POL     = 438
NRPN_CC_OSC_2_PW_MOD_2_AMT     = 439
NRPN_CC_OSC_2_PW_MOD_2_POL     = 440
NRPN_CC_OSC_2_SYNC_SW          = 441
NRPN_CC_NOISE_1_COLOR          = 442
NRPN_CC_NOISE_1_LEVEL          = 443
NRPN_CC_MIXER_2_LEVEL_1        = 444
NRPN_CC_MIXER_2_LEVEL_2        = 445
NRPN_CC_MIXER_2_LEVEL_3        = 446
NRPN_CC_MIXER_2_LEVEL_4        = 447
NRPN_CC_MIXER_2_OUT_LEVEL      = 448
NRPN_CC_FILTER_1_MODE          = 449
NRPN_CC_FILTER_1_CUTOFF        = 450
NRPN_CC_FILTER_1_RESONANCE     = 451
NRPN_CC_FILTER_1_GAIN_1        = 452
NRPN_CC_FILTER_1_GAIN_2        = 453
NRPN_CC_FILTER_1_PITCH_AMT     = 454
NRPN_CC_FILTER_1_PITCH_POL     = 455
NRPN_CC_FILTER_1_MOD_1_AMT     = 456
NRPN_CC_FILTER_1_MOD_1_POL     = 457
NRPN_CC_FILTER_1_MOD_2_AMT     = 458
NRPN_CC_FILTER_1_MOD_2_POL     = 459
NRPN_CC_FILTER_2_MODE          = 460
NRPN_CC_FILTER_2_CUTOFF        = 461
NRPN_CC_FILTER_2_RESONANCE     = 462
NRPN_CC_FILTER_2_GAIN_1        = 463
NRPN_CC_FILTER_2_GAIN_2        = 464
NRPN_CC_FILTER_2_PITCH_AMT     = 465
NRPN_CC_FILTER_2_PITCH_POL     = 466
NRPN_CC_FILTER_2_MOD_1_AMT     = 467
NRPN_CC_FILTER_2_MOD_1_POL     = 468
NRPN_CC_FILTER_2_MOD_2_AMT     = 469
NRPN_CC_FILTER_2_MOD_2_POL     = 470
NRPN_CC_AMP_1_GAIN_1           = 471
NRPN_CC_AMP_1_GAIN_2           = 472
NRPN_CC_AMP_1_MOD_1_2_MIX      = 473
NRPN_CC_CHORUS_1_MIX           = 474
NRPN_CC_CHORUS_1_RATE          = 475
NRPN_CC_CHORUS_1_DEPTH         = 476
NRPN_CC_DELAY_1_MIX            = 477
NRPN_CC_DELAY_1_TIME           = 478
NRPN_CC_DELAY_1_FEEDBACK       = 479
NRPN_CC_MOD_WHEEL              = 480
NRPN_CC_BREATH                 = 481
NRPN_CC_GENERAL_1              = 482
NRPN_CC_GENERAL_2              = 483
NRPN_CC_AMP_1_LIMITER_SW       = 484

# The value of each control slot while it has no CC, as a CC value, but the Mod Wheel's.
NRPN_VALUE_PITCH_1_GLIDE          = 512
NRPN_VALUE_PITCH_1_OUT_1_GLIDE_SW = 513
NRPN_VALUE_PITCH_1_OUT_2_GLIDE_SW = 514
NRPN_VALUE_PITCH_1_BEND_AMT       = 515
NRPN_VALUE_PITCH_1_BEND_POL       = 516
NRPN_VALUE_PITCH_1_OUT_1_BEND_SW  = 517
NRPN_VALUE_PITCH_1_OUT_2_BEND_SW  = 518
NRPN_VALUE_PITCH_1_STRETCH        = 519
NRPN_VALUE_EG_1_ATTACK            = 520
NRPN_VALUE_EG_1_DECAY             = 521
NRPN_VALUE_EG_1_SUSTAIN           = 522
NRPN_VALUE_EG_1_RELEASE_SW        = 523
NRPN_VALUE_EG_1_LEVEL             = 524
NRPN_VALUE_EG_2_ATTACK            = 525
NRPN_VALUE_EG_2_DECAY             = 526
NRPN_VALUE_EG_2_SUSTAIN           = 527
NRPN_VALUE_EG_2_RELEASE_SW        = 528
NRPN_VALUE_EG_2_LEVEL             = 529
NRPN_VALUE_LFO_1_WAVE             = 530
NRPN_VALUE_LFO_1_RATE             = 531
NRPN_VALUE_LFO_1_LEVEL            = 532
NRPN_VALUE_LFO_1_RATE_MOD_AMT     = 533
NRPN_VALUE_LFO_1_LEVEL_MOD_AMT    = 534
NRPN_VALUE_LFO_1_RESET_SW         = 535
NRPN_VALUE_MIXER_1_LEVEL_1        = 536
NRPN_VALUE_MIXER_1_LEVEL_2        = 537
NRPN_VALUE_MIXER_1_LEVEL_3        = 538
NRPN_VALUE_MIXER_1_LEVEL_4        = 539
NRPN_VALUE_MIXER_1_OUT_LEVEL      = 540
NRPN_VALUE_OSC_1_WAVE             = 541
NRPN_VALUE_OSC_1_PW               = 542
NRPN_VALUE_OSC_1_PITCH_COARSE     = 543
NRPN_VALUE_OSC_1_PITCH_FINE       = 544
NRPN_VALUE_OSC_1_PITCH_MOD_1_AMT  = 545
NRPN_VALUE_OSC_1_PITCH_MOD_1_POL  = 546
NRPN_VALUE_OSC_1_PITCH_MOD_1_SW   = 547
NRPN_VALUE_OSC_1_PITCH_MOD_2_AMT  = 548
NRPN_VALUE_OSC_1_PITCH_MOD_2_POL  = 549
NRPN_VALUE_OSC_1_PITCH_MOD_2_SW   = 550
NRPN_VALUE_OSC_1_PW_MOD_1_AMT     = 551
NRPN_VALUE_OSC_1_PW_MOD_1_POL     = 552
NRPN_VALUE_OSC_1_PW_MOD_2_AMT     = 553
NRPN_VALUE_OSC_1_PW_MOD_2_POL     = 554
NRPN_VALUE_OSC_2_WAVE             = 555
NRPN_VALUE_OSC_2_PW               = 556
NRPN_VALUE_OSC_2_PITCH_COARSE     = 557
NRPN_VALUE_OSC_2_PITCH_FINE       = 558
NRPN_VALUE_OSC_2_PITCH_MOD_1_AMT  = 559
NRPN_VALUE_OSC_2_PITCH_MOD_1_POL  = 560
NRPN_VALUE_OSC_2_PITCH_MOD_1_SW   = 561
NRPN_VALUE_OSC_2_PITCH_MOD_2_AMT  = 562
NRPN_VALUE_OSC_2_PITCH_MOD_2_POL  = 563
NRPN_VALUE_OSC_2_PITCH_MOD_2_SW   = 564
NRPN_VALUE_OSC_2_PW_MOD_1_AMT     = 565
NRPN_VALUE_OSC_2_PW_MOD_1_POL     = 566
NRPN_VALUE_OSC_2_PW_MOD_2_AMT     = 567
NRPN_VALUE_OSC_2_PW_MOD_2_POL     = 568
NRPN_VALUE_OSC_2_SYNC_SW          = 569
NRPN_VALUE_NOISE_1_COLOR          = 570
NRPN_VALUE_NOISE_1_LEVEL          = 571
NRPN_VALUE_MIXER_2_LEVEL_1        = 572
NRPN_VALUE_MIXER_2_LEVEL_2        = 573
NRPN_VALUE_MIXER_2_LEVEL_3        = 574
NRPN_VALUE_MIXER_2_LEVEL_4        = 575
NRPN_VALUE_MIXER_2_OUT_LEVEL      = 576
NRPN_VALUE_FILTER_1_MODE          = 577
NRPN_VALUE_FILTER_1_CUTOFF        = 578
NRPN_VALUE_FILTER_1_RESONANCE     = 579
NRPN_VALUE_FILTER_1_GAIN_1        = 580
NRPN_VALUE_FILTER_1_GAIN_2        = 581
NRPN_VALUE_FILTER_1_PITCH_AMT     = 582
NRPN_VALUE_FILTER_1_PITCH_POL     = 583
NRPN_VALUE_FILTER_1_MOD_1_AMT     = 584
NRPN_VALUE_FILTER_1_MOD_1_POL     = 585
NRPN_VALUE_FILTER_1_MOD_2_AMT     = 586
NRPN_VALUE_FILTER_1_MOD_2_POL     = 587
NRPN_VALUE_FILTER_2_MODE          = 588
NRPN_VALUE_FILTER_2_CUTOFF        = 589
NRPN_VALUE_FILTER_2_RESONANCE     = 590
NRPN_VALUE_FILTER_2_GAIN_1        = 591
NRPN_VALUE_FILTER_2_GAIN_2        = 592
NRPN_VALUE_FILTER_2_PITCH_AMT     = 593
NRPN_VALUE_FILTER_2_PITCH_POL     = 594
NRPN_VALUE_FILTER_2_MOD_1_AMT     = 595
NRPN_VALUE_FILTER_2_MOD_1_POL     = 596
NRPN_VALUE_FILTER_2_MOD_2_AMT     = 597
NRPN_VALUE_FILTER_2_MOD_2_POL     = 598
NRPN_VALUE_AMP_1_GAIN_1           = 599
NRPN_VALUE_AMP_1_GAIN_2           = 600
NRPN_VALUE_AMP_1_MOD_1_2_MIX      = 601
NRPN_VALUE_CHORUS_1_MIX           = 602
NRPN_VALUE_CHORUS_1_RATE          = 603
NRPN_VALUE_CHORUS_1_DEPTH         = 604
NRPN_VALUE_DELAY_1_MIX            = 605
NRPN_VALUE_DELAY_1_TIME           = 606
NRPN_VALUE_DELAY_1_FEEDBACK       = 607
NRPN_VALUE_GENERAL_1              = 610
NRPN_VALUE_GENERAL_2              = 611
NRPN_VALUE_AMP_1_LIMITER_SW       = 612

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
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 10, MODULE_FILTER_2)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 11, MODULE_AMP_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 12, MODULE_CHORUS_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_ACTIVE_MODULE_BASE + 13, MODULE_DELAY_1)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_PITCH_IN    , SIGNAL_NOTE_PITCH)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_GATE_IN     , SIGNAL_NOTE_GATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_IN     , SIGNAL_PITCH_BEND)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_1_GATE_IN        , SIGNAL_NOTE_GATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_EG_2_GATE_IN        , SIGNAL_NOTE_GATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RATE_MOD_IN   , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_LEVEL_MOD_IN  , SIGNAL_MOD_WHEEL)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_LFO_1_RESET_IN      , SIGNAL_NOTE_GATE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_1        , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_2        , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_3        , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_1_IN_4        , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_IN      , SIGNAL_PITCH_1_OUTPUT_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_1_IN, SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_2_IN, SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_1_IN   , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_2_IN   , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_IN      , SIGNAL_PITCH_1_OUTPUT_2)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_1_IN, SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_2_IN, SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_1_IN   , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_2_IN   , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_SYNC_IN       , SIGNAL_OSC_1_OUTPUT_SAW)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_1        , SIGNAL_OSC_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_2        , SIGNAL_OSC_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_3        , SIGNAL_OSC_1_OUTPUT_SUB)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_IN_4        , SIGNAL_NOISE_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_AUDIO_IN_1 , SIGNAL_MIXER_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_AUDIO_IN_2 , SIGNAL_NONE)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_PITCH_IN   , SIGNAL_PITCH_1_OUTPUT_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1_IN   , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2_IN   , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_AUDIO_IN_1 , SIGNAL_MIXER_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_AUDIO_IN_2 , SIGNAL_FILTER_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_PITCH_IN   , SIGNAL_PITCH_1_OUTPUT_1)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_MOD_1_IN   , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_MOD_2_IN   , SIGNAL_LFO_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_AUDIO_IN_1    , SIGNAL_FILTER_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_AUDIO_IN_2    , SIGNAL_FILTER_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_MOD_1_IN      , SIGNAL_EG_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_MOD_2_IN      , SIGNAL_EG_2_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_AUDIO_IN   , SIGNAL_AMP_1_OUTPUT)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_IN_L  , SIGNAL_CHORUS_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_AUDIO_IN_R  , SIGNAL_CHORUS_1_OUTPUT_R)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_L            , SIGNAL_DELAY_1_OUTPUT_L)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OUTPUT_R            , SIGNAL_DELAY_1_OUTPUT_R)

  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_GLIDE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_OUT_1_GLIDE_SW, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_OUT_2_GLIDE_SW, SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_AMT      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_PITCH_1_BEND_POL      , SIGNAL_OWN)
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
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_1_POL , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_1_SW  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_2_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_2_POL , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PITCH_MOD_2_SW  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_1_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_1_POL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_2_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_1_PW_MOD_2_POL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_WAVE            , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW              , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_COARSE    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_FINE      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_1_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_1_POL , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_1_SW  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_2_AMT , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_2_POL , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PITCH_MOD_2_SW  , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_1_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_1_POL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_2_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_PW_MOD_2_POL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_OSC_2_SYNC_SW         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_NOISE_1_COLOR         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_NOISE_1_LEVEL         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_1       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_2       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_3       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_LEVEL_4       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_MIXER_2_OUT_LEVEL     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MODE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_CUTOFF       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_RESONANCE    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_GAIN_1       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_GAIN_2       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_PITCH_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_PITCH_POL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_1_POL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_1_MOD_2_POL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_MODE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_CUTOFF       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_RESONANCE    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_GAIN_1       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_GAIN_2       , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_PITCH_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_PITCH_POL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_MOD_1_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_MOD_1_POL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_MOD_2_AMT    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_FILTER_2_MOD_2_POL    , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_GAIN_1          , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_GAIN_2          , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_MOD_1_2_MIX     , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_MIX          , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_RATE         , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_CHORUS_1_DEPTH        , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_MIX           , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_TIME          , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_DELAY_1_FEEDBACK      , SIGNAL_OWN)
  C.set_midi_nrpn_value(midi_ch, NRPN_SOURCE_AMP_1_LIMITER_SW      , SIGNAL_OWN)

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
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PITCH_MOD_1_SW  , 118)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PITCH_MOD_2_AMT , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_1_AMT    , 8)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_1_PW_MOD_2_AMT    , 103)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_WAVE            , 104)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_COARSE    , 85)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_FINE      , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_MOD_1_AMT , 89)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_PITCH_MOD_2_AMT , 13)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_OSC_2_SYNC_SW         , 112)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_NOISE_1_COLOR         , 115)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_1       , 19)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_2       , 20)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_3       , 21)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MIXER_2_LEVEL_4       , 23)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MODE         , 39)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_CUTOFF       , 74)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_PITCH_AMT    , 9)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_1_AMT    , 24)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_1_POL    , 117)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_1_MOD_2_AMT    , 25)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_2_MODE         , 39)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_2_CUTOFF       , 74)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_2_RESONANCE    , 71)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_2_PITCH_AMT    , 9)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_2_MOD_1_AMT    , 24)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_2_MOD_1_POL    , 117)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_FILTER_2_MOD_2_AMT    , 25)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_AMP_1_GAIN_2          , 15)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_AMP_1_MOD_1_2_MIX     , 36)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_MIX          , 93)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_RATE         , 58)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_CHORUS_1_DEPTH        , 59)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_MIX           , 94)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_TIME          , 90)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_DELAY_1_FEEDBACK      , 92)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_MOD_WHEEL             , 1)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_BREATH                , 2)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_1             , 16)
  C.set_midi_nrpn_value(midi_ch, NRPN_CC_GENERAL_2             , 17)

  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_GLIDE         , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_OUT_1_GLIDE_SW, 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_OUT_2_GLIDE_SW, 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_BEND_AMT      , 28)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_BEND_POL      , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_OUT_1_BEND_SW , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_OUT_2_BEND_SW , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_PITCH_1_STRETCH       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_ATTACK           , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_EG_1_DECAY            , 88)
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
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_LFO_1_LEVEL           , 124)
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
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_1_POL , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_1_SW  , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_2_AMT , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_2_POL , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PITCH_MOD_2_SW  , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PW_MOD_1_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PW_MOD_1_POL    , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PW_MOD_2_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_1_PW_MOD_2_POL    , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_WAVE            , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PW              , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_COARSE    , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_FINE      , 75)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_1_AMT , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_1_POL , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_1_SW  , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_2_AMT , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_2_POL , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PITCH_MOD_2_SW  , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PW_MOD_1_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PW_MOD_1_POL    , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PW_MOD_2_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_PW_MOD_2_POL    , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_OSC_2_SYNC_SW         , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_NOISE_1_COLOR         , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_NOISE_1_LEVEL         , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_LEVEL_1       , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_LEVEL_2       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_LEVEL_3       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_LEVEL_4       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_MIXER_2_OUT_LEVEL     , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MODE         , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_CUTOFF       , 100)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_RESONANCE    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_GAIN_1       , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_GAIN_2       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_PITCH_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_PITCH_POL    , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MOD_1_AMT    , 28)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MOD_1_POL    , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MOD_2_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_1_MOD_2_POL    , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_2_MODE         , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_2_CUTOFF       , 100)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_2_RESONANCE    , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_2_GAIN_1       , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_2_GAIN_2       , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_2_PITCH_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_2_PITCH_POL    , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_2_MOD_1_AMT    , 28)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_2_MOD_1_POL    , 124)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_2_MOD_2_AMT    , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_FILTER_2_MOD_2_POL    , 76)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_AMP_1_GAIN_1          , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_AMP_1_GAIN_2          , 88)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_AMP_1_MOD_1_2_MIX     , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_CHORUS_1_MIX          , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_CHORUS_1_RATE         , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_CHORUS_1_DEPTH        , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_DELAY_1_MIX           , 34)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_DELAY_1_TIME          , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_DELAY_1_FEEDBACK      , 64)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_GENERAL_1             , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_GENERAL_2             , 4)
  C.set_midi_nrpn_value(midi_ch, NRPN_VALUE_AMP_1_LIMITER_SW      , 124)

  C.set_midi_cc_value(midi_ch, 5  , 4  ) # Pitch 1 Glide
  C.set_midi_cc_value(midi_ch, 34 , 124) # Pitch 1 Out 1 Glide Sw
  C.set_midi_cc_value(midi_ch, 34 , 124) # Pitch 1 Out 2 Glide Sw
  C.set_midi_cc_value(midi_ch, 57 , 28 ) # Pitch 1 Bend Amt
  C.set_midi_cc_value(midi_ch, 22 , 4  ) # Pitch 1 Stretch
  C.set_midi_cc_value(midi_ch, 73 , 4  ) # EG 1 Attack
  C.set_midi_cc_value(midi_ch, 75 , 88 ) # EG 1 Decay
  C.set_midi_cc_value(midi_ch, 30 , 124) # EG 1 Sustain
  C.set_midi_cc_value(midi_ch, 105, 124) # EG 1 Release Sw
  C.set_midi_cc_value(midi_ch, 52 , 4  ) # EG 2 Attack
  C.set_midi_cc_value(midi_ch, 53 , 4  ) # EG 2 Decay
  C.set_midi_cc_value(midi_ch, 54 , 124) # EG 2 Sustain
  C.set_midi_cc_value(midi_ch, 105, 124) # EG 2 Release Sw
  C.set_midi_cc_value(midi_ch, 33 , 4  ) # LFO 1 Wave
  C.set_midi_cc_value(midi_ch, 3  , 64 ) # LFO 1 Rate
  C.set_midi_cc_value(midi_ch, 116, 124) # LFO 1 Level
  C.set_midi_cc_value(midi_ch, 113, 4  ) # LFO 1 Reset Sw
  C.set_midi_cc_value(midi_ch, 102, 4  ) # Osc 1 Wave
  C.set_midi_cc_value(midi_ch, 114, 64 ) # Osc 1 PW
  C.set_midi_cc_value(midi_ch, 89 , 4  ) # Osc 1 Pitch Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 118, 124) # Osc 1 Pitch Mod 1 Sw
  C.set_midi_cc_value(midi_ch, 13 , 4  ) # Osc 1 Pitch Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 8  , 4  ) # Osc 1 PW Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 103, 4  ) # Osc 1 PW Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 104, 4  ) # Osc 2 Wave
  C.set_midi_cc_value(midi_ch, 85 , 64 ) # Osc 2 Pitch Coarse
  C.set_midi_cc_value(midi_ch, 76 , 75 ) # Osc 2 Pitch Fine
  C.set_midi_cc_value(midi_ch, 89 , 4  ) # Osc 2 Pitch Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 13 , 4  ) # Osc 2 Pitch Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 112, 4  ) # Osc 2 Sync Sw
  C.set_midi_cc_value(midi_ch, 115, 4  ) # Noise 1 Color
  C.set_midi_cc_value(midi_ch, 19 , 124) # Mixer 2 Level 1
  C.set_midi_cc_value(midi_ch, 20 , 4  ) # Mixer 2 Level 2
  C.set_midi_cc_value(midi_ch, 21 , 4  ) # Mixer 2 Level 3
  C.set_midi_cc_value(midi_ch, 23 , 4  ) # Mixer 2 Level 4
  C.set_midi_cc_value(midi_ch, 39 , 4  ) # Filter 1 Mode
  C.set_midi_cc_value(midi_ch, 74 , 100) # Filter 1 Cutoff
  C.set_midi_cc_value(midi_ch, 9  , 4  ) # Filter 1 Pitch Amt
  C.set_midi_cc_value(midi_ch, 24 , 28 ) # Filter 1 Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 117, 124) # Filter 1 Mod 1 Pol
  C.set_midi_cc_value(midi_ch, 25 , 4  ) # Filter 1 Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 39 , 4  ) # Filter 2 Mode
  C.set_midi_cc_value(midi_ch, 74 , 100) # Filter 2 Cutoff
  C.set_midi_cc_value(midi_ch, 71 , 64 ) # Filter 2 Resonance
  C.set_midi_cc_value(midi_ch, 9  , 4  ) # Filter 2 Pitch Amt
  C.set_midi_cc_value(midi_ch, 24 , 28 ) # Filter 2 Mod 1 Amt
  C.set_midi_cc_value(midi_ch, 117, 124) # Filter 2 Mod 1 Pol
  C.set_midi_cc_value(midi_ch, 25 , 4  ) # Filter 2 Mod 2 Amt
  C.set_midi_cc_value(midi_ch, 15 , 88 ) # Amp 1 Gain 2
  C.set_midi_cc_value(midi_ch, 36 , 4  ) # Amp 1 Mod 1/2 Mix
  C.set_midi_cc_value(midi_ch, 93 , 64 ) # Chorus 1 Mix
  C.set_midi_cc_value(midi_ch, 58 , 64 ) # Chorus 1 Rate
  C.set_midi_cc_value(midi_ch, 59 , 64 ) # Chorus 1 Depth
  C.set_midi_cc_value(midi_ch, 94 , 34 ) # Delay 1 Mix
  C.set_midi_cc_value(midi_ch, 90 , 64 ) # Delay 1 Time
  C.set_midi_cc_value(midi_ch, 92 , 64 ) # Delay 1 Feedback
  C.set_midi_cc_value(midi_ch, 1  , 4  ) # Mod Wheel
  C.set_midi_cc_value(midi_ch, 2  , 4  ) # Breath
  C.set_midi_cc_value(midi_ch, 16 , 4  ) # General 1
  C.set_midi_cc_value(midi_ch, 17 , 4  ) # General 2
end
