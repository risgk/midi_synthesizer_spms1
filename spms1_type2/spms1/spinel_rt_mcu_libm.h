/* For the MCU: the float versions of the math functions, where Float is float (SPINEL_FLOAT32 in
   sp_types.h), the RP2350 having a single-precision FPU only. spinel_rt.h includes this right after
   <math.h>, so that the prototypes there are left as they are. Kept out of spinel_rt.h for the
   same reason as spinel_rt_mcu_head.h. */
#ifndef SPINEL_RT_MCU_LIBM_H
#define SPINEL_RT_MCU_LIBM_H

#if SPINEL_FLOAT32

/* Every function of <math.h> that the generated code or the runtime calls with sp_float, to its
   float version: one left out would convert to double and back around a call done in software.
   <tgmath.h> would do this by itself, but its macros spell long double, which the #define double
   float for the generated code (spinel_rt_mcu_cold.h) makes long float. */
#define sin(x) sinf(x)
#define cos(x) cosf(x)
#define tan(x) tanf(x)
#define asin(x) asinf(x)
#define acos(x) acosf(x)
#define atan(x) atanf(x)
#define sinh(x) sinhf(x)
#define cosh(x) coshf(x)
#define tanh(x) tanhf(x)
#define asinh(x) asinhf(x)
#define acosh(x) acoshf(x)
#define atanh(x) atanhf(x)
#define exp(x) expf(x)
#define exp2(x) exp2f(x)
#define expm1(x) expm1f(x)
#define log(x) logf(x)
#define log2(x) log2f(x)
#define log10(x) log10f(x)
#define log1p(x) log1pf(x)
#define sqrt(x) sqrtf(x)
#define cbrt(x) cbrtf(x)
#define fabs(x) fabsf(x)
#define floor(x) floorf(x)
#define ceil(x) ceilf(x)
#define round(x) roundf(x)
#define trunc(x) truncf(x)
#define erf(x) erff(x)
#define erfc(x) erfcf(x)
#define lgamma(x) lgammaf(x)
#define tgamma(x) tgammaf(x)
#define atan2(x,y) atan2f(x,y)
#define pow(x,y) powf(x,y)
#define hypot(x,y) hypotf(x,y)
#define fmod(x,y) fmodf(x,y)
#define remainder(x,y) remainderf(x,y)
#define copysign(x,y) copysignf(x,y)
#define nextafter(x,y) nextafterf(x,y)
#define fmin(x,y) fminf(x,y)
#define fmax(x,y) fmaxf(x,y)
#define frexp(x,e) frexpf(x,e)
#define ldexp(x,e) ldexpf(x,e)

#endif /* SPINEL_FLOAT32 */

#endif /* SPINEL_RT_MCU_LIBM_H */
