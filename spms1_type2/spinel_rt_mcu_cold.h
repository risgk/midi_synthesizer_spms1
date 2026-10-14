/* Definitions the generated code needs from Spinel's lib/sp_cold.c, which is not built for
   the MCU. spinel_rt.h includes this at its end. Kept out of spinel_rt.h for the same reason as
   spinel_rt_mcu_head.h. */
#ifndef SPINEL_RT_MCU_COLD_H
#define SPINEL_RT_MCU_COLD_H

/* Definitions that Spinel keeps in lib/sp_cold.c, copied here for the MCU. sp_cold.c is the
   runtime's POSIX side (sockets, poll, dirent, ...) and is not built for the MCU, but the
   generated code still calls or names these. sp_float_to_i_checked is here so that flatten can
   inline it into Spms1_main, as it could when it was static in sp_runtime.h. The nil check in
   the Integer operators calls sp_raise_nil_int_op, so it stays noinline, out of line as it is
   in sp_cold.c, rather than adding a copy of itself to each of those sites in Spms1_main. */
__attribute__((noinline)) SP_NORETURN void sp_raise_nil_int_op(sp_int a, sp_int b, const char *op) {SP_GC_ROOT_STR(op);
  (void)b;
  if (a == SP_INT_NIL)
    sp_raise_cls("NoMethodError", sp_sprintf("undefined method '%s' for nil", op));
  /* nil on the RIGHT is the coercion failure CRuby reports from Integer#+ */
  sp_raise_cls("TypeError", "nil can't be coerced into Integer");
}
sp_int sp_float_to_i_checked(sp_float f) {
  if (isnan(f) || isinf(f)) sp_raise_cls("FloatDomainError", sp_sprintf("%g", f));
  if (f >= 9223372036854775808.0 || f < -9223372036854775808.0)
    sp_raise_cls("RangeError", "float out of Integer range (Bignum promotion pending)");
  return (sp_int)f;
}
void sp_Dir_scan(void *p) { sp_Dir *d = (sp_Dir *)p; if (d->path) sp_mark_string(d->path); }
void sp_Enumerator_scan(void *p) {
  sp_Enumerator *e = (sp_Enumerator *)p;
  if (e->items) sp_gc_mark(e->items);
  if (e->fib) sp_gc_mark(e->fib);
  if (e->gen_cap) sp_gc_mark(e->gen_cap);
  if (e->peeked) sp_mark_rbval(e->peek_val);
  sp_mark_rbval(e->size);
  if (e->has_feed) sp_mark_rbval(e->feed);
  sp_mark_rbval(e->gen_result);
  sp_mark_rbval(e->source);
  sp_mark_string(e->meth);
}

/* sp_types.h declares sp_float as float for the MCU (see spinel_mcu/spinel_mcu.patch). This stops the build
   if a new release declares it in a way the patch no longer reaches. */
_Static_assert(sizeof(sp_float) == sizeof(float), "sp_float must be float for the MCU");

#endif /* SPINEL_RT_MCU_COLD_H */
