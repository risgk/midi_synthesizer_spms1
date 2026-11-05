/* Written by patch_gen/spms1_patch_gen.rb from spms1_patch.yaml: do not edit. The declaration of
   spms1_apply_parameters (spms1_main.rb), ahead of the one in spms1_main.c, so that it stays a
   function of its own rather than flattened into Spms1_main, in RAM as Spms1_main is, and
   flattened itself. spinel_rt_mcu_cold.h includes this, at the end of spinel_rt.h. */
#ifndef SPMS1_PARAMETERS_H
#define SPMS1_PARAMETERS_H

struct sp_SignalBus_s;
struct sp_Pitch_s;
struct sp_EnvGen_s;
struct sp_LFO_s;
struct sp_Mixer_s;
struct sp_Osc_s;
struct sp_Noise_s;
struct sp_Filter_s;
struct sp_Amp_s;
struct sp_Chorus_s;
struct sp_Delay_s;
static sp_float sp_spms1_apply_parameters(struct sp_SignalBus_s *, struct sp_Pitch_s *, struct sp_EnvGen_s *, struct sp_EnvGen_s *, struct sp_LFO_s *, struct sp_Mixer_s *, struct sp_Osc_s *, struct sp_Osc_s *, struct sp_Noise_s *, struct sp_Mixer_s *, struct sp_Filter_s *, struct sp_Filter_s *, struct sp_Amp_s *, struct sp_Chorus_s *, struct sp_Delay_s *)
  __attribute__((noinline, flatten, section(".time_critical")));

#endif /* SPMS1_PARAMETERS_H */
