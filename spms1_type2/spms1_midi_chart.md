```
  [MIDI Synthesizer]                                              Date: 2026-10-19                      
  Model: SPMS-1 (type-2)          MIDI Implementation Chart       Version: 0.0.4                        
+-------------------------------+---------------+---------------+--------------------------------------+
| Function...                   | Transmitted   | Recognized    | Remarks                              |
+-------------------------------+---------------+---------------+--------------------------------------+
| Basic        Default          | x             | 1             |                                      |
| Channel      Changed          | x             | x             |                                      |
+-------------------------------+---------------+---------------+--------------------------------------+
| Mode         Default          | x             | Mode 4        |                                      |
|              Messages         | x             | x             |                                      |
|              Altered          | ************* |               |                                      |
+-------------------------------+---------------+---------------+--------------------------------------+
| Note                          | x             | 0-127         |                                      |
| Number       : True Voice     | ************* | 0-120         |                                      |
+-------------------------------+---------------+---------------+--------------------------------------+
| Velocity     Note ON          | x             | x             |                                      |
|              Note OFF         | x             | x             |                                      |
+-------------------------------+---------------+---------------+--------------------------------------+
| After        Key's            | x             | x             |                                      |
| Touch        Ch's             | x             | x             |                                      |
+-------------------------------+---------------+---------------+--------------------------------------+
| Pitch Bend                    | x             | o             | Pitch 1 Bend In, +-12 Semitones      |
+-------------------------------+---------------+---------------+--------------------------------------+
| Control                   102 | x             | o             | Osc 1 Wave (Saw to Square)           |
| Change                    104 | x             | o             | Osc 2 Wave (Saw to Square)           |
|                            89 | x             | o             | Osc Pitch Mod 1 Amt (EG)             |
|                            13 | x             | o             | Osc Pitch Mod 2 Amt (LFO)            |
|                           114 | x             | o             | Osc PW (50% to 0%)                   |
|                             8 | x             | o             | Osc PW Mod 1 Amt (EG)                |
|                           103 | x             | o             | Osc PW Mod 2 Amt (LFO)               |
|                            85 | x             | o             | Osc 2 Pitch Coarse (+-5 Octaves)     |
|                            76 | x             | o             | Osc 2 Pitch Fine (+-60 Cents)        |
|                           112 | x             | o             | Osc 2 Sync Switch [Off|On]           |
|                            74 | x             | o             | Filter Cutoff                        |
|                            71 | x             | o             | Filter Resonance                     |
|                            24 | x             | o             | Filter Mod 1 Amt (EG)                |
|                            25 | x             | o             | Filter Mod 2 Amt (LFO)               |
|                            51 | x             | o             | Filter Mod Polarity (-1 to +1)       |
|                             9 | x             | o             | Filter Pitch Amt                     |
|                            39 | x             | o             | Filter Mode (LP, Notch, HP)          |
|                            19 | x             | o             | Mixer 2 Level 1 (Osc 1 Level)        |
|                            20 | x             | o             | Mixer 2 Level 2 (Osc 2 Level)        |
|                            21 | x             | o             | Mixer 2 Level 3 (Osc 1 Sub Level)    |
|                            23 | x             | o             | Mixer 2 Level 4 (Noise Level)        |
|                           115 | x             | o             | Noise Color (White to Red)           |
|                            15 | x             | o             | Amp Gain                             |
|                            36 | x             | o             | Amp Mod 1/2 Mix (EG 1 to EG 2)       |
|                            73 | x             | o             | EG 1 Attack (Time)                   |
|                            75 | x             | o             | EG 1 Decay (Time)                    |
|                            30 | x             | o             | EG 1 Sustain (Level)                 |
|                           105 | x             | o             | EG 1/2 Release Switch [Off|On]       |
|                            52 | x             | o             | EG 2 Attack (Time)                   |
|                            53 | x             | o             | EG 2 Decay (Time)                    |
|                            54 | x             | o             | EG 2 Sustain (Level)                 |
|                             3 | x             | o             | LFO Rate                             |
|                            17 | x             | o             | LFO Level                            |
|                            33 | x             | o             | LFO Wave (Triangle to Square)        |
|                           113 | x             | o             | LFO Reset Switch [Off|On]            |
|                            93 | x             | o             | Chorus Mix                           |
|                            58 | x             | o             | Chorus Rate                          |
|                            59 | x             | o             | Chorus Depth                         |
|                            90 | x             | o             | Delay Time                           |
|                            94 | x             | o             | Delay Mix                            |
|                            92 | x             | o             | Delay Feedback                       |
|                             5 | x             | o             | Pitch Glide (Portamento Time)        |
|                            34 | x             | o             | Pitch Glide Switch [Off|On]          |
|                            57 | x             | o             | Pitch Bend Amt (Pitch Bend Range)    |
|                            22 | x             | o             | Pitch Stretch                        |
|                             1 | x             | o             | Mod Wheel (Unipolar)                 |
|                            99 | x             | o             | NRPN MSB                             |
|                            98 | x             | o             | NRPN LSB                             |
|                             6 | x             | o             | Data Entry MSB (NRPN value)          |
|                       101,100 | x             | o             | RPN select: suspends NRPN data entry |
+-------------------------------+---------------+---------------+--------------------------------------+
| Program                       | x             | x             |                                      |
| Change       : True #         | ************* | ************* |                                      |
+-------------------------------+---------------+---------------+--------------------------------------+
| System Exclusive              | x             | x             |                                      |
+-------------------------------+---------------+---------------+--------------------------------------+
| System       : Song Pos       | x             | x             |                                      |
| Common       : Song Sel       | x             | x             |                                      |
|              : Tune           | x             | x             |                                      |
+-------------------------------+---------------+---------------+--------------------------------------+
| System       : Clock          | x             | x             |                                      |
| Real Time    : Commands       | x             | x             |                                      |
+-------------------------------+---------------+---------------+--------------------------------------+
| Aux          : All Sound OFF  | x             | x             |                                      |
| Messages     : Reset All Ctrl | x             | x             |                                      |
|              : Local ON/OFF   | x             | x             |                                      |
|              : All Notes OFF  | x             | x             |                                      |
|              : Active Sense   | x             | x             |                                      |
|              : Reset          | x             | x             |                                      |
+-------------------------------+---------------+---------------+--------------------------------------+
| Notes                         | Control Change 4-124, centred on 64. NRPN is 7-bit, CC 6 only.       |
+-------------------------------+----------------------------------------------------------------------+
  Mode 1: Omni On,  Poly          Mode 2: Omni On,  Mono          o: Yes                                
  Mode 3: Omni Off, Poly          Mode 4: Omni Off, Mono          x: No                                 
```
