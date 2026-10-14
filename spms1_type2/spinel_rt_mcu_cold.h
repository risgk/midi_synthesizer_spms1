/* For the MCU, at the end of spinel_rt.h: what binds the generated code to the runtime. Kept out of
   spinel_rt.h for the same reason as spinel_rt_mcu_head.h. */
#ifndef SPINEL_RT_MCU_COLD_H
#define SPINEL_RT_MCU_COLD_H

/* Float#to_i, which the synth calls every sample (index = pitch.to_i and the like). sp_cold.c has
   it, out of line; this copy is here so that flatten can inline it into Spms1_main, as it could
   when it was static in sp_runtime.h, rather than call into flash every sample. Under another
   name, through a #define that only the generated code below sees, so that the runtime keeps
   sp_cold.c's. */
static inline sp_int sp_mcu_float_to_i_checked(sp_float f) {
  if (isnan(f) || isinf(f)) sp_raise_cls("FloatDomainError", sp_sprintf("%g", f));
  /* The range of sp_int, which is pointer-width (see sp_cold.c) */
#if INTPTR_MAX == INT32_MAX
  if (f >= 2147483648.0 || f < -2147483648.0)
#else
  if (f >= 9223372036854775808.0 || f < -9223372036854775808.0)
#endif
    sp_raise_cls("RangeError", "float out of Integer range (Bignum promotion pending)");
  return (sp_int)f;
}
#define sp_float_to_i_checked sp_mcu_float_to_i_checked

/* sp_types.h declares sp_float as float for the MCU (see spinel_mcu/spinel_mcu.patch). This stops the build
   if a new release declares it in a way the patch no longer reaches. */
_Static_assert(!SPINEL_FLOAT32 || sizeof(sp_float) == sizeof(float), "sp_float must be float for the MCU");

/* What follows spinel_rt.h is the generated code, which spells double itself where it means
   Float: in casts and temporaries ((double)(n), double _t1 = x for Float#floor) and in the Float
   constants (DBL_EPSILON for Float::EPSILON). The runtime above is written in sp_float, and these
   bind the generated code to it. They are all that is left of float for double, and they are
   for the generated code only: a Spinel that spelled sp_float and SP_FLOAT_EPSILON there would
   need none of them (see spinel_mcu/UPSTREAM_PROPOSAL_DRAFT.md). */
#if SPINEL_FLOAT32
#define double float
#undef DBL_DIG
#define DBL_DIG FLT_DIG
#undef DBL_EPSILON
#define DBL_EPSILON FLT_EPSILON
#undef DBL_MANT_DIG
#define DBL_MANT_DIG FLT_MANT_DIG
#undef DBL_MAX
#define DBL_MAX FLT_MAX
#undef DBL_MAX_EXP
#define DBL_MAX_EXP FLT_MAX_EXP
#undef DBL_MIN
#define DBL_MIN FLT_MIN
#undef DBL_MIN_EXP
#define DBL_MIN_EXP FLT_MIN_EXP
#endif

#endif /* SPINEL_RT_MCU_COLD_H */
