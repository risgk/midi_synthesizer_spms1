/*
 * Generated from spms1_patch.yaml by patch_gen/spms1_patch_gen.rb. Do not edit; change the YAML
 * and run the generator.
 *
 * The default patch, as spms1_write_default_patch in spms1_patch.rb writes it at power-up: the
 * NRPN entries, then the values its CCs power up at. spms1_midi_state.h writes it back when the
 * reset NRPN arrives. And what a saved patch is checked against, and keeps of the CC values.
 */
#ifndef SPMS1_DEFAULT_PATCH_H
#define SPMS1_DEFAULT_PATCH_H

#include <stdint.h>

// The numbers of the patch and saved_patch_version, as one hash (see patch_spec_hash in
// patch_gen): a saved patch with another is not loaded.
#define SPMS1_PATCH_SPEC_HASH (0x4062907Cu)

// The category 3 entries -- the controls -- whose CCs' values a Save keeps: all but the
// performance controls', whose CCs are saved at 0.
static const uint8_t g_spms1_saved_cc_entries[] = {
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
  16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
  32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
  48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
  64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79,
  80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
  98, 99, 100
};

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
  {10,   11},  // Run order 10: Filter 2
  {11,   12},  // Run order 11: Amp 1
  {12,   13},  // Run order 12: Chorus 1
  {13,   14},  // Run order 13: Delay 1
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
  {140,  42},  // Osc 1 Pitch In <- PITCH_1_OUTPUT_1
  {141,  44},  // Osc 1 Pitch Mod 1 In <- EG_1_OUTPUT
  {142,  48},  // Osc 1 Pitch Mod 2 In <- LFO_1_OUTPUT
  {143,  44},  // Osc 1 PW Mod 1 In <- EG_1_OUTPUT
  {144,  48},  // Osc 1 PW Mod 2 In <- LFO_1_OUTPUT
  {145,  43},  // Osc 2 Pitch In <- PITCH_1_OUTPUT_2
  {146,  44},  // Osc 2 Pitch Mod 1 In <- EG_1_OUTPUT
  {147,  48},  // Osc 2 Pitch Mod 2 In <- LFO_1_OUTPUT
  {148,  44},  // Osc 2 PW Mod 1 In <- EG_1_OUTPUT
  {149,  48},  // Osc 2 PW Mod 2 In <- LFO_1_OUTPUT
  {150,  57},  // Osc 2 Sync In <- OSC_1_OUTPUT_SAW
  {151,  56},  // Mixer 2 In 1 <- OSC_1_OUTPUT
  {152,  60},  // Mixer 2 In 2 <- OSC_2_OUTPUT
  {153,  59},  // Mixer 2 In 3 <- OSC_1_OUTPUT_SUB
  {154,  63},  // Mixer 2 In 4 <- NOISE_1_OUTPUT
  {155,  66},  // Filter 1 Audio In 1 <- MIXER_2_OUTPUT
  {156,   0},  // Filter 1 Audio In 2 <- NONE
  {157,  42},  // Filter 1 Pitch In <- PITCH_1_OUTPUT_1
  {158,  44},  // Filter 1 Mod 1 In <- EG_1_OUTPUT
  {159,  48},  // Filter 1 Mod 2 In <- LFO_1_OUTPUT
  {160,  66},  // Filter 2 Audio In 1 <- MIXER_2_OUTPUT
  {161,  68},  // Filter 2 Audio In 2 <- FILTER_1_OUTPUT
  {162,  42},  // Filter 2 Pitch In <- PITCH_1_OUTPUT_1
  {163,  44},  // Filter 2 Mod 1 In <- EG_1_OUTPUT
  {164,  48},  // Filter 2 Mod 2 In <- LFO_1_OUTPUT
  {165,  68},  // Amp 1 Audio In 1 <- FILTER_1_OUTPUT
  {166,  72},  // Amp 1 Audio In 2 <- FILTER_2_OUTPUT
  {167,  44},  // Amp 1 Mod 1 In <- EG_1_OUTPUT
  {168,  46},  // Amp 1 Mod 2 In <- EG_2_OUTPUT
  {169,  76},  // Chorus 1 Audio In <- AMP_1_OUTPUT
  {170,  77},  // Delay 1 Audio In L <- CHORUS_1_OUTPUT_L
  {171,  78},  // Delay 1 Audio In R <- CHORUS_1_OUTPUT_R
  {172,  80},  // L <- DELAY_1_OUTPUT_L
  {173,  81},  // R <- DELAY_1_OUTPUT_R
  {256, 127},  // Pitch 1 Glide <- OWN
  {257, 127},  // Pitch 1 Out 1 Glide Sw <- OWN
  {258, 127},  // Pitch 1 Out 2 Glide Sw <- OWN
  {259, 127},  // Pitch 1 Bend Amt <- OWN
  {260, 127},  // Pitch 1 Bend Pol <- OWN
  {261, 127},  // Pitch 1 Out 1 Bend Sw <- OWN
  {262, 127},  // Pitch 1 Out 2 Bend Sw <- OWN
  {263, 127},  // Pitch 1 Stretch <- OWN
  {264, 127},  // EG 1 Attack <- OWN
  {265, 127},  // EG 1 Decay <- OWN
  {266, 127},  // EG 1 Sustain <- OWN
  {267, 127},  // EG 1 Release Sw <- OWN
  {268, 127},  // EG 1 Level <- OWN
  {269, 127},  // EG 2 Attack <- OWN
  {270, 127},  // EG 2 Decay <- OWN
  {271, 127},  // EG 2 Sustain <- OWN
  {272, 127},  // EG 2 Release Sw <- OWN
  {273, 127},  // EG 2 Level <- OWN
  {274, 127},  // LFO 1 Wave <- OWN
  {275, 127},  // LFO 1 Rate <- OWN
  {276, 127},  // LFO 1 Level <- OWN
  {277, 127},  // LFO 1 Rate Mod Amt <- OWN
  {278, 127},  // LFO 1 Level Mod Amt <- OWN
  {279, 127},  // LFO 1 Reset Sw <- OWN
  {280, 127},  // Mixer 1 Level 1 <- OWN
  {281, 127},  // Mixer 1 Level 2 <- OWN
  {282, 127},  // Mixer 1 Level 3 <- OWN
  {283, 127},  // Mixer 1 Level 4 <- OWN
  {284, 127},  // Mixer 1 Out Level <- OWN
  {285, 127},  // Osc 1 Wave <- OWN
  {286, 127},  // Osc 1 PW <- OWN
  {287, 127},  // Osc 1 Pitch Coarse <- OWN
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
  {302, 127},  // Osc 2 Pitch Fine <- OWN
  {303, 127},  // Osc 2 Pitch Mod 1 Amt <- OWN
  {304, 127},  // Osc 2 Pitch Mod 1 Pol <- OWN
  {305, 127},  // Osc 2 Pitch Mod 1 Sw <- OWN
  {306, 127},  // Osc 2 Pitch Mod 2 Amt <- OWN
  {307, 127},  // Osc 2 Pitch Mod 2 Pol <- OWN
  {308, 127},  // Osc 2 Pitch Mod 2 Sw <- OWN
  {309, 127},  // Osc 2 PW Mod 1 Amt <- OWN
  {310, 127},  // Osc 2 PW Mod 1 Pol <- OWN
  {311, 127},  // Osc 2 PW Mod 2 Amt <- OWN
  {312, 127},  // Osc 2 PW Mod 2 Pol <- OWN
  {313, 127},  // Osc 2 Sync Sw <- OWN
  {314, 127},  // Noise 1 Color <- OWN
  {315, 127},  // Noise 1 Level <- OWN
  {316, 127},  // Mixer 2 Level 1 <- OWN
  {317, 127},  // Mixer 2 Level 2 <- OWN
  {318, 127},  // Mixer 2 Level 3 <- OWN
  {319, 127},  // Mixer 2 Level 4 <- OWN
  {320, 127},  // Mixer 2 Out Level <- OWN
  {321, 127},  // Filter 1 Mode <- OWN
  {322, 127},  // Filter 1 Cutoff <- OWN
  {323, 127},  // Filter 1 Resonance <- OWN
  {324, 127},  // Filter 1 Gain 1 <- OWN
  {325, 127},  // Filter 1 Gain 2 <- OWN
  {326, 127},  // Filter 1 Pitch Amt <- OWN
  {327, 127},  // Filter 1 Pitch Pol <- OWN
  {328, 127},  // Filter 1 Mod 1 Amt <- OWN
  {329, 127},  // Filter 1 Mod 1 Pol <- OWN
  {330, 127},  // Filter 1 Mod 2 Amt <- OWN
  {331, 127},  // Filter 1 Mod 2 Pol <- OWN
  {332, 127},  // Filter 2 Mode <- OWN
  {333, 127},  // Filter 2 Cutoff <- OWN
  {334, 127},  // Filter 2 Resonance <- OWN
  {335, 127},  // Filter 2 Gain 1 <- OWN
  {336, 127},  // Filter 2 Gain 2 <- OWN
  {337, 127},  // Filter 2 Pitch Amt <- OWN
  {338, 127},  // Filter 2 Pitch Pol <- OWN
  {339, 127},  // Filter 2 Mod 1 Amt <- OWN
  {340, 127},  // Filter 2 Mod 1 Pol <- OWN
  {341, 127},  // Filter 2 Mod 2 Amt <- OWN
  {342, 127},  // Filter 2 Mod 2 Pol <- OWN
  {343, 127},  // Amp 1 Gain 1 <- OWN
  {344, 127},  // Amp 1 Gain 2 <- OWN
  {345, 127},  // Amp 1 Mod 1/2 Mix <- OWN
  {346, 127},  // Chorus 1 Mix <- OWN
  {347, 127},  // Chorus 1 Rate <- OWN
  {348, 127},  // Chorus 1 Depth <- OWN
  {349, 127},  // Delay 1 Mix <- OWN
  {350, 127},  // Delay 1 Time <- OWN
  {351, 127},  // Delay 1 Feedback <- OWN
  {356, 127},  // Amp 1 Limiter Sw <- OWN
  {384,   5},  // Pitch 1 Glide CC
  {385,  34},  // Pitch 1 Out 1 Glide Sw CC
  {386,  34},  // Pitch 1 Out 2 Glide Sw CC
  {387,  57},  // Pitch 1 Bend Amt CC
  {391,  22},  // Pitch 1 Stretch CC
  {392,  73},  // EG 1 Attack CC
  {393,  75},  // EG 1 Decay CC
  {394,  30},  // EG 1 Sustain CC
  {395, 105},  // EG 1 Release Sw CC
  {397,  52},  // EG 2 Attack CC
  {398,  53},  // EG 2 Decay CC
  {399,  54},  // EG 2 Sustain CC
  {400, 105},  // EG 2 Release Sw CC
  {402,  33},  // LFO 1 Wave CC
  {403,   3},  // LFO 1 Rate CC
  {404, 116},  // LFO 1 Level CC
  {407, 113},  // LFO 1 Reset Sw CC
  {413, 102},  // Osc 1 Wave CC
  {414, 114},  // Osc 1 PW CC
  {417,  89},  // Osc 1 Pitch Mod 1 Amt CC
  {419, 118},  // Osc 1 Pitch Mod 1 Sw CC
  {420,  13},  // Osc 1 Pitch Mod 2 Amt CC
  {423,   8},  // Osc 1 PW Mod 1 Amt CC
  {425, 103},  // Osc 1 PW Mod 2 Amt CC
  {427, 104},  // Osc 2 Wave CC
  {429,  85},  // Osc 2 Pitch Coarse CC
  {430,  76},  // Osc 2 Pitch Fine CC
  {431,  89},  // Osc 2 Pitch Mod 1 Amt CC
  {434,  13},  // Osc 2 Pitch Mod 2 Amt CC
  {441, 112},  // Osc 2 Sync Sw CC
  {442, 115},  // Noise 1 Color CC
  {444,  19},  // Mixer 2 Level 1 CC
  {445,  20},  // Mixer 2 Level 2 CC
  {446,  21},  // Mixer 2 Level 3 CC
  {447,  23},  // Mixer 2 Level 4 CC
  {449,  39},  // Filter 1 Mode CC
  {450,  74},  // Filter 1 Cutoff CC
  {454,   9},  // Filter 1 Pitch Amt CC
  {456,  24},  // Filter 1 Mod 1 Amt CC
  {457, 117},  // Filter 1 Mod 1 Pol CC
  {458,  25},  // Filter 1 Mod 2 Amt CC
  {460,  39},  // Filter 2 Mode CC
  {461,  74},  // Filter 2 Cutoff CC
  {462,  71},  // Filter 2 Resonance CC
  {465,   9},  // Filter 2 Pitch Amt CC
  {467,  24},  // Filter 2 Mod 1 Amt CC
  {468, 117},  // Filter 2 Mod 1 Pol CC
  {469,  25},  // Filter 2 Mod 2 Amt CC
  {472,  15},  // Amp 1 Gain 2 CC
  {473,  36},  // Amp 1 Mod 1/2 Mix CC
  {474,  93},  // Chorus 1 Mix CC
  {475,  58},  // Chorus 1 Rate CC
  {476,  59},  // Chorus 1 Depth CC
  {477,  94},  // Delay 1 Mix CC
  {478,  90},  // Delay 1 Time CC
  {479,  92},  // Delay 1 Feedback CC
  {480,   1},  // Mod Wheel CC
  {481,   2},  // Breath CC
  {482,  16},  // General 1 CC
  {483,  17},  // General 2 CC
  {512,   4},  // Pitch 1 Glide value
  {513, 124},  // Pitch 1 Out 1 Glide Sw value
  {514, 124},  // Pitch 1 Out 2 Glide Sw value
  {515,  28},  // Pitch 1 Bend Amt value
  {516, 124},  // Pitch 1 Bend Pol value
  {517, 124},  // Pitch 1 Out 1 Bend Sw value
  {518, 124},  // Pitch 1 Out 2 Bend Sw value
  {519,   4},  // Pitch 1 Stretch value
  {520,   4},  // EG 1 Attack value
  {521,  88},  // EG 1 Decay value
  {522, 124},  // EG 1 Sustain value
  {523, 124},  // EG 1 Release Sw value
  {524, 124},  // EG 1 Level value
  {525,   4},  // EG 2 Attack value
  {526,   4},  // EG 2 Decay value
  {527, 124},  // EG 2 Sustain value
  {528, 124},  // EG 2 Release Sw value
  {529, 124},  // EG 2 Level value
  {530,   4},  // LFO 1 Wave value
  {531,  64},  // LFO 1 Rate value
  {532, 124},  // LFO 1 Level value
  {533, 124},  // LFO 1 Rate Mod Amt value
  {534, 124},  // LFO 1 Level Mod Amt value
  {535,   4},  // LFO 1 Reset Sw value
  {536,   4},  // Mixer 1 Level 1 value
  {537,   4},  // Mixer 1 Level 2 value
  {538,   4},  // Mixer 1 Level 3 value
  {539,   4},  // Mixer 1 Level 4 value
  {540,  64},  // Mixer 1 Out Level value
  {541,   4},  // Osc 1 Wave value
  {542,  64},  // Osc 1 PW value
  {543,  64},  // Osc 1 Pitch Coarse value
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
  {558,  74},  // Osc 2 Pitch Fine value
  {559,   4},  // Osc 2 Pitch Mod 1 Amt value
  {560,  76},  // Osc 2 Pitch Mod 1 Pol value
  {561, 124},  // Osc 2 Pitch Mod 1 Sw value
  {562,   4},  // Osc 2 Pitch Mod 2 Amt value
  {563,  76},  // Osc 2 Pitch Mod 2 Pol value
  {564, 124},  // Osc 2 Pitch Mod 2 Sw value
  {565,   4},  // Osc 2 PW Mod 1 Amt value
  {566, 124},  // Osc 2 PW Mod 1 Pol value
  {567,   4},  // Osc 2 PW Mod 2 Amt value
  {568, 124},  // Osc 2 PW Mod 2 Pol value
  {569,   4},  // Osc 2 Sync Sw value
  {570,   4},  // Noise 1 Color value
  {571, 124},  // Noise 1 Level value
  {572, 124},  // Mixer 2 Level 1 value
  {573,   4},  // Mixer 2 Level 2 value
  {574,   4},  // Mixer 2 Level 3 value
  {575,   4},  // Mixer 2 Level 4 value
  {576,  64},  // Mixer 2 Out Level value
  {577,   4},  // Filter 1 Mode value
  {578, 100},  // Filter 1 Cutoff value
  {579,   4},  // Filter 1 Resonance value
  {580,  64},  // Filter 1 Gain 1 value
  {581,   4},  // Filter 1 Gain 2 value
  {582,   4},  // Filter 1 Pitch Amt value
  {583, 124},  // Filter 1 Pitch Pol value
  {584,  28},  // Filter 1 Mod 1 Amt value
  {585, 124},  // Filter 1 Mod 1 Pol value
  {586,   4},  // Filter 1 Mod 2 Amt value
  {587,  76},  // Filter 1 Mod 2 Pol value
  {588,   4},  // Filter 2 Mode value
  {589, 100},  // Filter 2 Cutoff value
  {590,  64},  // Filter 2 Resonance value
  {591,   4},  // Filter 2 Gain 1 value
  {592,  64},  // Filter 2 Gain 2 value
  {593,   4},  // Filter 2 Pitch Amt value
  {594, 124},  // Filter 2 Pitch Pol value
  {595,  28},  // Filter 2 Mod 1 Amt value
  {596, 124},  // Filter 2 Mod 1 Pol value
  {597,   4},  // Filter 2 Mod 2 Amt value
  {598,  76},  // Filter 2 Mod 2 Pol value
  {599,   4},  // Amp 1 Gain 1 value
  {600,  88},  // Amp 1 Gain 2 value
  {601,   4},  // Amp 1 Mod 1/2 Mix value
  {602,  64},  // Chorus 1 Mix value
  {603,  64},  // Chorus 1 Rate value
  {604,  64},  // Chorus 1 Depth value
  {605,  34},  // Delay 1 Mix value
  {606,  64},  // Delay 1 Time value
  {607,  64},  // Delay 1 Feedback value
  {610,   4},  // General 1 value
  {611,   4},  // General 2 value
  {612, 124},  // Amp 1 Limiter Sw value
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
  {85,   64},  // Osc 2 Pitch Coarse
  {76,   74},  // Osc 2 Pitch Fine
  {89,    4},  // Osc 2 Pitch Mod 1 Amt
  {13,    4},  // Osc 2 Pitch Mod 2 Amt
  {112,   4},  // Osc 2 Sync Sw
  {115,   4},  // Noise 1 Color
  {19,  124},  // Mixer 2 Level 1
  {20,    4},  // Mixer 2 Level 2
  {21,    4},  // Mixer 2 Level 3
  {23,    4},  // Mixer 2 Level 4
  {39,    4},  // Filter 1 Mode
  {74,  100},  // Filter 1 Cutoff
  {9,     4},  // Filter 1 Pitch Amt
  {24,   28},  // Filter 1 Mod 1 Amt
  {117, 124},  // Filter 1 Mod 1 Pol
  {25,    4},  // Filter 1 Mod 2 Amt
  {39,    4},  // Filter 2 Mode
  {74,  100},  // Filter 2 Cutoff
  {71,   64},  // Filter 2 Resonance
  {9,     4},  // Filter 2 Pitch Amt
  {24,   28},  // Filter 2 Mod 1 Amt
  {117, 124},  // Filter 2 Mod 1 Pol
  {25,    4},  // Filter 2 Mod 2 Amt
  {15,   88},  // Amp 1 Gain 2
  {36,    4},  // Amp 1 Mod 1/2 Mix
  {93,   64},  // Chorus 1 Mix
  {58,   64},  // Chorus 1 Rate
  {59,   64},  // Chorus 1 Depth
  {94,   34},  // Delay 1 Mix
  {90,   64},  // Delay 1 Time
  {92,   64},  // Delay 1 Feedback
  {1,     4},  // Mod Wheel
  {2,     4},  // Breath
  {16,    4},  // General 1
  {17,    4},  // General 2
};

#endif  // SPMS1_DEFAULT_PATCH_H
