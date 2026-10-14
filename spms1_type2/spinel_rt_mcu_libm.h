/* float for double in the Spinel runtime, the RP2350 having a single-precision FPU only.
   spinel_rt.h includes this right after <math.h>, so that the prototypes there keep double.
   Kept out of spinel_rt.h for the same reason as spinel_rt_mcu_head.h. */
#ifndef SPINEL_RT_MCU_LIBM_H
#define SPINEL_RT_MCU_LIBM_H

#define double float
#define sin(x) sinf(x)
#define cos(x) cosf(x)
#define tan(x) tanf(x)
#define atan2(y,x) atan2f(y,x)
#define sqrt(x) sqrtf(x)
#define fabs(x) fabsf(x)
#define pow(x,y) powf(x,y)
#define exp(x) expf(x)
#define log(x) logf(x)

#endif /* SPINEL_RT_MCU_LIBM_H */
