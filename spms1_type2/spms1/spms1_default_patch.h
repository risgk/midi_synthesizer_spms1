/*
 * Generated from spms1_patch.yaml by patch_gen/spms1_patch_gen.rb. Do not edit; change the YAML
 * and run the generator.
 *
 * The default patch, as spms1_write_default_patch in spms1_patch.rb writes it at power-up: the
 * NRPN entries, then the values its CCs power up at. spms1_midi_state.h writes it back when the
 * reset NRPN arrives.
 */
#ifndef SPMS1_DEFAULT_PATCH_H
#define SPMS1_DEFAULT_PATCH_H

#include <stdint.h>

// NRPN parameter number (category << 7 | LSB), value
static const uint16_t g_spms1_default_nrpn[][2] = {
  {0,     1},  // Run order 0: Pitch 1
  {1,     2},  // Run order 1: EG 1
  {2,     3},  // Run order 2: EG 2
  {3,     4},  // Run order 3: LFO 1
  {4,     5},  // Run order 4: Mixer 1
  {5,     6},  // Run order 5: Osc 1
  {6,     7},  // Run order 6: Osc 2
  {7,     8},  // Run order 7: Noise 1
  {8,     9},  // Run order 8: Mixer 2
  {9,    10},  // Run order 9: Filter 1
  {10,   11},  // Run order 10: Amp 1
  {11,   12},  // Run order 11: Chorus 1
  {12,   13},  // Run order 12: Delay 1
  {128,   5},  // Pitch 1 Pitch In <- NOTE_PITCH
  {129,   6},  // Pitch 1 Gate In <- NOTE_GATE
  {130,   7},  // Pitch 1 Bend In <- PITCH_BEND
  {131,   6},  // EG 1 Gate In <- NOTE_GATE
  {132,   6},  // EG 2 Gate In <- NOTE_GATE
  {133,   0},  // LFO 1 Rate Mod In <- NONE
  {134,   8},  // LFO 1 Level Mod In <- MOD_WHEEL
  {135,   6},  // LFO 1 Reset In <- NOTE_GATE
  {136,   0},  // Mixer 1 In 1 <- NONE
  {137,   0},  // Mixer 1 In 2 <- NONE
  {138,   0},  // Mixer 1 In 3 <- NONE
  {139,   0},  // Mixer 1 In 4 <- NONE
  {140,  38},  // Osc 1 Pitch In <- PITCH_1_OUTPUT_1
  {141,  40},  // Osc 1 Mod 1 In <- EG_1_OUTPUT
  {142,  44},  // Osc 1 Mod 2 In <- LFO_1_OUTPUT
  {143,  39},  // Osc 2 Pitch In <- PITCH_1_OUTPUT_2
  {144,  40},  // Osc 2 Mod 1 In <- EG_1_OUTPUT
  {145,  44},  // Osc 2 Mod 2 In <- LFO_1_OUTPUT
  {146,  53},  // Osc 2 Sync In <- OSC_1_OUTPUT_SAW
  {147,  52},  // Mixer 2 In 1 <- OSC_1_OUTPUT
  {148,  56},  // Mixer 2 In 2 <- OSC_2_OUTPUT
  {149,  55},  // Mixer 2 In 3 <- OSC_1_OUTPUT_SUB
  {150,  59},  // Mixer 2 In 4 <- NOISE_1_OUTPUT
  {151,  62},  // Filter 1 Audio In <- MIXER_2_OUTPUT
  {152,  38},  // Filter 1 Pitch In <- PITCH_1_OUTPUT_1
  {153,  40},  // Filter 1 Mod 1 In <- EG_1_OUTPUT
  {154,  44},  // Filter 1 Mod 2 In <- LFO_1_OUTPUT
  {155,  64},  // Amp 1 Audio In <- FILTER_1_OUTPUT
  {156,  40},  // Amp 1 Mod 1 In <- EG_1_OUTPUT
  {157,  42},  // Amp 1 Mod 2 In <- EG_2_OUTPUT
  {158,  68},  // Chorus 1 Audio In <- AMP_1_OUTPUT
  {159,  69},  // Delay 1 Audio In L <- CHORUS_1_OUTPUT_L
  {160,  70},  // Delay 1 Audio In R <- CHORUS_1_OUTPUT_R
  {161,  72},  // L <- DELAY_1_OUTPUT_L
  {162,  73},  // R <- DELAY_1_OUTPUT_R
  {256, 127},  // Pitch 1 Glide <- OWN
  {257, 127},  // Pitch 1 Out 1 Glide Sw <- OWN
  {258, 127},  // Pitch 1 Out 2 Glide Sw <- OWN
  {259, 127},  // Pitch 1 Bend Amt <- OWN
  {260, 127},  // Pitch 1 Out 1 Bend Sw <- OWN
  {261, 127},  // Pitch 1 Out 2 Bend Sw <- OWN
  {262, 127},  // Pitch 1 Stretch <- OWN
  {263, 127},  // EG 1 Attack <- OWN
  {264, 127},  // EG 1 Decay <- OWN
  {265, 127},  // EG 1 Sustain <- OWN
  {266, 127},  // EG 1 Release Sw <- OWN
  {267, 127},  // EG 1 Level <- OWN
  {268, 127},  // EG 2 Attack <- OWN
  {269, 127},  // EG 2 Decay <- OWN
  {270, 127},  // EG 2 Sustain <- OWN
  {271, 127},  // EG 2 Release Sw <- OWN
  {272, 127},  // EG 2 Level <- OWN
  {273, 127},  // LFO 1 Wave <- OWN
  {274, 127},  // LFO 1 Rate <- OWN
  {275, 127},  // LFO 1 Level <- OWN
  {276, 127},  // LFO 1 Rate Mod Amt <- OWN
  {277, 127},  // LFO 1 Level Mod Amt <- OWN
  {278, 127},  // LFO 1 Reset Sw <- OWN
  {279, 127},  // Mixer 1 Level 1 <- OWN
  {280, 127},  // Mixer 1 Level 2 <- OWN
  {281, 127},  // Mixer 1 Level 3 <- OWN
  {282, 127},  // Mixer 1 Level 4 <- OWN
  {283, 127},  // Mixer 1 Out Level <- OWN
  {284, 127},  // Osc 1 Wave <- OWN
  {285, 127},  // Osc 1 PW <- OWN
  {286, 127},  // Osc 1 Pitch Coarse <- OWN
  {287, 127},  // Osc 1 Pitch <- OWN
  {288, 127},  // Osc 1 Pitch Fine <- OWN
  {289, 127},  // Osc 1 Pitch Mod 1 Amt <- OWN
  {290, 127},  // Osc 1 Pitch Mod 1 Pol <- OWN
  {291, 127},  // Osc 1 Pitch Mod 1 Sw <- OWN
  {292, 127},  // Osc 1 Pitch Mod 2 Amt <- OWN
  {293, 127},  // Osc 1 Pitch Mod 2 Pol <- OWN
  {294, 127},  // Osc 1 Pitch Mod 2 Sw <- OWN
  {295, 127},  // Osc 1 PW Mod 1 Amt <- OWN
  {296, 127},  // Osc 1 PW Mod 1 Pol <- OWN
  {297, 127},  // Osc 1 PW Mod 2 Amt <- OWN
  {298, 127},  // Osc 1 PW Mod 2 Pol <- OWN
  {299, 127},  // Osc 2 Wave <- OWN
  {300, 127},  // Osc 2 PW <- OWN
  {301, 127},  // Osc 2 Pitch Coarse <- OWN
  {302, 127},  // Osc 2 Pitch <- OWN
  {303, 127},  // Osc 2 Pitch Fine <- OWN
  {304, 127},  // Osc 2 Pitch Mod 1 Amt <- OWN
  {305, 127},  // Osc 2 Pitch Mod 1 Pol <- OWN
  {306, 127},  // Osc 2 Pitch Mod 1 Sw <- OWN
  {307, 127},  // Osc 2 Pitch Mod 2 Amt <- OWN
  {308, 127},  // Osc 2 Pitch Mod 2 Pol <- OWN
  {309, 127},  // Osc 2 Pitch Mod 2 Sw <- OWN
  {310, 127},  // Osc 2 PW Mod 1 Amt <- OWN
  {311, 127},  // Osc 2 PW Mod 1 Pol <- OWN
  {312, 127},  // Osc 2 PW Mod 2 Amt <- OWN
  {313, 127},  // Osc 2 PW Mod 2 Pol <- OWN
  {314, 127},  // Osc 2 Sync Sw <- OWN
  {315, 127},  // Noise 1 Color <- OWN
  {316, 127},  // Noise 1 Level <- OWN
  {317, 127},  // Mixer 2 Level 1 <- OWN
  {318, 127},  // Mixer 2 Level 2 <- OWN
  {319, 127},  // Mixer 2 Level 3 <- OWN
  {320, 127},  // Mixer 2 Level 4 <- OWN
  {321, 127},  // Mixer 2 Out Level <- OWN
  {322, 127},  // Filter 1 Cutoff <- OWN
  {323, 127},  // Filter 1 Resonance <- OWN
  {324, 127},  // Filter 1 Mode <- OWN
  {325, 127},  // Filter 1 Pitch Amt <- OWN
  {326, 127},  // Filter 1 Mod 1 Amt <- OWN
  {327, 127},  // Filter 1 Mod 1 Pol <- OWN
  {328, 127},  // Filter 1 Mod 2 Amt <- OWN
  {329, 127},  // Filter 1 Mod 2 Pol <- OWN
  {330, 127},  // Amp 1 Gain <- OWN
  {331, 127},  // Amp 1 Mod 1/2 Mix <- OWN
  {332, 127},  // Chorus 1 Mix <- OWN
  {333, 127},  // Chorus 1 Rate <- OWN
  {334, 127},  // Chorus 1 Depth <- OWN
  {335, 127},  // Delay 1 Mix <- OWN
  {336, 127},  // Delay 1 Time <- OWN
  {337, 127},  // Delay 1 Feedback <- OWN
  {341, 127},  // Amp 1 Limiter Sw <- OWN
  {384,   5},  // Pitch 1 Glide CC
  {385,  34},  // Pitch 1 Out 1 Glide Sw CC
  {386,  34},  // Pitch 1 Out 2 Glide Sw CC
  {387,  57},  // Pitch 1 Bend Amt CC
  {390,  22},  // Pitch 1 Stretch CC
  {391,  73},  // EG 1 Attack CC
  {392,  75},  // EG 1 Decay CC
  {393,  30},  // EG 1 Sustain CC
  {394, 105},  // EG 1 Release Sw CC
  {396,  52},  // EG 2 Attack CC
  {397,  53},  // EG 2 Decay CC
  {398,  54},  // EG 2 Sustain CC
  {399, 105},  // EG 2 Release Sw CC
  {401,  33},  // LFO 1 Wave CC
  {402,   3},  // LFO 1 Rate CC
  {403, 116},  // LFO 1 Level CC
  {406, 113},  // LFO 1 Reset Sw CC
  {412, 102},  // Osc 1 Wave CC
  {413, 114},  // Osc 1 PW CC
  {417,  89},  // Osc 1 Pitch Mod 1 Amt CC
  {419, 118},  // Osc 1 Pitch Mod 1 Sw CC
  {420,  13},  // Osc 1 Pitch Mod 2 Amt CC
  {423,   8},  // Osc 1 PW Mod 1 Amt CC
  {425, 103},  // Osc 1 PW Mod 2 Amt CC
  {427, 104},  // Osc 2 Wave CC
  {428, 114},  // Osc 2 PW CC
  {430,  85},  // Osc 2 Pitch CC
  {431,  76},  // Osc 2 Pitch Fine CC
  {432,  89},  // Osc 2 Pitch Mod 1 Amt CC
  {435,  13},  // Osc 2 Pitch Mod 2 Amt CC
  {438,   8},  // Osc 2 PW Mod 1 Amt CC
  {440, 103},  // Osc 2 PW Mod 2 Amt CC
  {442, 112},  // Osc 2 Sync Sw CC
  {443, 115},  // Noise 1 Color CC
  {445,  19},  // Mixer 2 Level 1 CC
  {446,  20},  // Mixer 2 Level 2 CC
  {447,  21},  // Mixer 2 Level 3 CC
  {448,  23},  // Mixer 2 Level 4 CC
  {450,  74},  // Filter 1 Cutoff CC
  {451,  71},  // Filter 1 Resonance CC
  {452,  39},  // Filter 1 Mode CC
  {453,   9},  // Filter 1 Pitch Amt CC
  {454,  24},  // Filter 1 Mod 1 Amt CC
  {455, 117},  // Filter 1 Mod 1 Pol CC
  {456,  25},  // Filter 1 Mod 2 Amt CC
  {458,  15},  // Amp 1 Gain CC
  {459,  36},  // Amp 1 Mod 1/2 Mix CC
  {460,  93},  // Chorus 1 Mix CC
  {461,  58},  // Chorus 1 Rate CC
  {462,  59},  // Chorus 1 Depth CC
  {463,  94},  // Delay 1 Mix CC
  {464,  90},  // Delay 1 Time CC
  {465,  92},  // Delay 1 Feedback CC
  {466,   1},  // Mod Wheel CC
  {467,  16},  // General 1 CC
  {468,  17},  // General 2 CC
  {512,   4},  // Pitch 1 Glide value
  {513, 124},  // Pitch 1 Out 1 Glide Sw value
  {514, 124},  // Pitch 1 Out 2 Glide Sw value
  {515,  28},  // Pitch 1 Bend Amt value
  {516, 124},  // Pitch 1 Out 1 Bend Sw value
  {517, 124},  // Pitch 1 Out 2 Bend Sw value
  {518,   4},  // Pitch 1 Stretch value
  {519,   4},  // EG 1 Attack value
  {520,  88},  // EG 1 Decay value
  {521, 124},  // EG 1 Sustain value
  {522, 124},  // EG 1 Release Sw value
  {523, 124},  // EG 1 Level value
  {524,   4},  // EG 2 Attack value
  {525,   4},  // EG 2 Decay value
  {526, 124},  // EG 2 Sustain value
  {527, 124},  // EG 2 Release Sw value
  {528, 124},  // EG 2 Level value
  {529,   4},  // LFO 1 Wave value
  {530,  64},  // LFO 1 Rate value
  {531, 124},  // LFO 1 Level value
  {532, 124},  // LFO 1 Rate Mod Amt value
  {533, 124},  // LFO 1 Level Mod Amt value
  {534,   4},  // LFO 1 Reset Sw value
  {535,   4},  // Mixer 1 Level 1 value
  {536,   4},  // Mixer 1 Level 2 value
  {537,   4},  // Mixer 1 Level 3 value
  {538,   4},  // Mixer 1 Level 4 value
  {539,  64},  // Mixer 1 Out Level value
  {540,   4},  // Osc 1 Wave value
  {541,  64},  // Osc 1 PW value
  {542,  64},  // Osc 1 Pitch Coarse value
  {543,   4},  // Osc 1 Pitch value
  {544,  64},  // Osc 1 Pitch Fine value
  {545,   4},  // Osc 1 Pitch Mod 1 Amt value
  {546,  76},  // Osc 1 Pitch Mod 1 Pol value
  {547, 124},  // Osc 1 Pitch Mod 1 Sw value
  {548,   4},  // Osc 1 Pitch Mod 2 Amt value
  {549,  76},  // Osc 1 Pitch Mod 2 Pol value
  {550, 124},  // Osc 1 Pitch Mod 2 Sw value
  {551,   4},  // Osc 1 PW Mod 1 Amt value
  {552, 124},  // Osc 1 PW Mod 1 Pol value
  {553,   4},  // Osc 1 PW Mod 2 Amt value
  {554, 124},  // Osc 1 PW Mod 2 Pol value
  {555,   4},  // Osc 2 Wave value
  {556,  64},  // Osc 2 PW value
  {557,  64},  // Osc 2 Pitch Coarse value
  {558,   5},  // Osc 2 Pitch value
  {559,  65},  // Osc 2 Pitch Fine value
  {560,   4},  // Osc 2 Pitch Mod 1 Amt value
  {561,  76},  // Osc 2 Pitch Mod 1 Pol value
  {562, 124},  // Osc 2 Pitch Mod 1 Sw value
  {563,   4},  // Osc 2 Pitch Mod 2 Amt value
  {564,  76},  // Osc 2 Pitch Mod 2 Pol value
  {565, 124},  // Osc 2 Pitch Mod 2 Sw value
  {566,   4},  // Osc 2 PW Mod 1 Amt value
  {567, 124},  // Osc 2 PW Mod 1 Pol value
  {568,   4},  // Osc 2 PW Mod 2 Amt value
  {569, 124},  // Osc 2 PW Mod 2 Pol value
  {570,   4},  // Osc 2 Sync Sw value
  {571,   4},  // Noise 1 Color value
  {572, 124},  // Noise 1 Level value
  {573,  88},  // Mixer 2 Level 1 value
  {574,  88},  // Mixer 2 Level 2 value
  {575,   4},  // Mixer 2 Level 3 value
  {576,   4},  // Mixer 2 Level 4 value
  {577,  64},  // Mixer 2 Out Level value
  {578, 100},  // Filter 1 Cutoff value
  {579,  64},  // Filter 1 Resonance value
  {580,   4},  // Filter 1 Mode value
  {581,   4},  // Filter 1 Pitch Amt value
  {582,  28},  // Filter 1 Mod 1 Amt value
  {583, 124},  // Filter 1 Mod 1 Pol value
  {584,   4},  // Filter 1 Mod 2 Amt value
  {585,  76},  // Filter 1 Mod 2 Pol value
  {586,  88},  // Amp 1 Gain value
  {587,   4},  // Amp 1 Mod 1/2 Mix value
  {588,  64},  // Chorus 1 Mix value
  {589,  64},  // Chorus 1 Rate value
  {590,  64},  // Chorus 1 Depth value
  {591,  34},  // Delay 1 Mix value
  {592,  64},  // Delay 1 Time value
  {593,  64},  // Delay 1 Feedback value
  {597, 124},  // Amp 1 Limiter Sw value
};

// CC number, value
static const uint8_t g_spms1_default_cc[][2] = {
  {5,     4},  // Pitch 1 Glide
  {34,  124},  // Pitch 1 Out 1 Glide Sw
  {34,  124},  // Pitch 1 Out 2 Glide Sw
  {57,   28},  // Pitch 1 Bend Amt
  {22,    4},  // Pitch 1 Stretch
  {73,    4},  // EG 1 Attack
  {75,   88},  // EG 1 Decay
  {30,  124},  // EG 1 Sustain
  {105, 124},  // EG 1 Release Sw
  {52,    4},  // EG 2 Attack
  {53,    4},  // EG 2 Decay
  {54,  124},  // EG 2 Sustain
  {105, 124},  // EG 2 Release Sw
  {33,    4},  // LFO 1 Wave
  {3,    64},  // LFO 1 Rate
  {116, 124},  // LFO 1 Level
  {113,   4},  // LFO 1 Reset Sw
  {102,   4},  // Osc 1 Wave
  {114,  64},  // Osc 1 PW
  {89,    4},  // Osc 1 Pitch Mod 1 Amt
  {118, 124},  // Osc 1 Pitch Mod 1 Sw
  {13,    4},  // Osc 1 Pitch Mod 2 Amt
  {8,     4},  // Osc 1 PW Mod 1 Amt
  {103,   4},  // Osc 1 PW Mod 2 Amt
  {104,   4},  // Osc 2 Wave
  {114,  64},  // Osc 2 PW
  {85,    5},  // Osc 2 Pitch
  {76,   65},  // Osc 2 Pitch Fine
  {89,    4},  // Osc 2 Pitch Mod 1 Amt
  {13,    4},  // Osc 2 Pitch Mod 2 Amt
  {8,     4},  // Osc 2 PW Mod 1 Amt
  {103,   4},  // Osc 2 PW Mod 2 Amt
  {112,   4},  // Osc 2 Sync Sw
  {115,   4},  // Noise 1 Color
  {19,   88},  // Mixer 2 Level 1
  {20,   88},  // Mixer 2 Level 2
  {21,    4},  // Mixer 2 Level 3
  {23,    4},  // Mixer 2 Level 4
  {74,  100},  // Filter 1 Cutoff
  {71,   64},  // Filter 1 Resonance
  {39,    4},  // Filter 1 Mode
  {9,     4},  // Filter 1 Pitch Amt
  {24,   28},  // Filter 1 Mod 1 Amt
  {117, 124},  // Filter 1 Mod 1 Pol
  {25,    4},  // Filter 1 Mod 2 Amt
  {15,   88},  // Amp 1 Gain
  {36,    4},  // Amp 1 Mod 1/2 Mix
  {93,   64},  // Chorus 1 Mix
  {58,   64},  // Chorus 1 Rate
  {59,   64},  // Chorus 1 Depth
  {94,   34},  // Delay 1 Mix
  {90,   64},  // Delay 1 Time
  {92,   64},  // Delay 1 Feedback
  {1,     4},  // Mod Wheel
  {16,    4},  // General 1
  {17,    4},  // General 2
};

#endif  // SPMS1_DEFAULT_PATCH_H
