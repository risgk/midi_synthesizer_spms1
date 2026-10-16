/* sp_proc.c -- cold sp_Proc/sp_Curry ops (see sp_proc.h). 0 optcarrot uses. */
#include "sp_proc.h"

void sp_Proc_scan(void *p) { sp_Proc *pr = (sp_Proc *)p; if (pr->cap && pr->cap_scan) pr->cap_scan(pr->cap); }
sp_Proc *sp_proc_new_meta(void *fn, void *cap, void (*cap_scan)(void *), sp_int arity, sp_bool lambda_p, sp_int param_count, const sp_sym *param_kinds, const sp_sym *param_names) { sp_Proc *p = (sp_Proc *)sp_gc_alloc(sizeof(sp_Proc), NULL, sp_Proc_scan); p->fn = fn; p->cap = cap; p->cap_scan = cap_scan; p->arity = arity; p->lambda_p = lambda_p; p->param_count = param_count; p->param_kinds = param_kinds; p->param_names = param_names; return p; }
/* Proc#dup / #clone: a fresh shallow copy (distinct identity; the capture
   environment is shared, like CRuby). dup drops the frozen flag, clone keeps
   it (#3048). */
sp_Proc *sp_proc_dup(sp_Proc *p, int keep_frozen) {
  if (!p) return p;
  SP_GC_ROOT(p);
  sp_Proc *r = (sp_Proc *)sp_gc_alloc(sizeof(sp_Proc), NULL, sp_Proc_scan);
  *r = *p;
  if (!keep_frozen) r->frozen = 0;
  r->origin = sp_proc_root(p);   /* share the lineage root so dup == original */
  return r;
}
sp_Proc *sp_proc_new(void *fn, void *cap, void (*cap_scan)(void *)) { return sp_proc_new_meta(fn, cap, cap_scan, 0, FALSE, 0, NULL, NULL); }
sp_int sp_proc_arity(sp_Proc *p) { return p ? p->arity : 0; }
sp_bool sp_proc_lambda_p(sp_Proc *p) { return p ? p->lambda_p : FALSE; }
/* Proc#inspect: CRuby prints "#<Proc:0xADDR file:line (lambda)>"; the
   source location is not tracked, so the address form (+ lambda marker) is
   the best-effort rendering. */
const char *sp_proc_inspect(sp_Proc *p) {SP_GC_ROOT(p);
  if (!p) return SPL("nil");
  return sp_sprintf(p->lambda_p ? "#<Proc:0x%016llx (lambda)>" : "#<Proc:0x%016llx>",
                    (unsigned long long)(uintptr_t)p);
}
/* Lambda strict-arity check: raise ArgumentError if argc is outside
   [req, req+opt] (no upper bound with a rest param). Procs are lenient. */
void sp_proc_lambda_arity_check(sp_int argc, sp_int req, sp_int opt, sp_bool has_rest, sp_bool has_kw) {
  /* a lambda with keyword parameters accepts one extra trailing argument (the
     keyword hash) beyond its positional maximum. */
  sp_int max = req + opt + (has_kw ? 1 : 0);
  if (argc < req || (!has_rest && argc > max)) sp_raise_cls("ArgumentError", "wrong number of arguments");
}
/* Proc#parameters with an explicit mode. Kinds are stored canonically
   (lambda-style: a plain positional is "req"); printing for proc mode remaps
   req -> opt, which leaves defaulted positionals (stored "opt") and every
   non-positional kind untouched -- exactly CRuby's parameters(lambda:) rule.
   mode: 1 = lambda view, 0 = proc view, -1 = the receiver's own nature.
   req_id/opt_id are the generated TU's interned ids for those kinds. #2693 */
sp_PolyArray *sp_proc_parameters_ids(sp_Proc *p, int mode, sp_sym req_id, sp_sym opt_id) { SP_GC_ROOT(p);
  sp_PolyArray *r = sp_PolyArray_new();
  if (!p || p->param_count <= 0 || !p->param_kinds) return r;
  SP_GC_ROOT(r);
  int want_lambda = mode >= 0 ? mode : (p->lambda_p ? 1 : 0);
  for (sp_int i = 0; i < p->param_count; i++) {
    sp_sym k = p->param_kinds[i];
    if (!want_lambda && k == req_id) k = opt_id;
    sp_PolyArray *pair = sp_PolyArray_new();
    sp_PolyArray_push(pair, sp_box_sym(k));
    if (p->param_names && p->param_names[i] >= 0) sp_PolyArray_push(pair, sp_box_sym(p->param_names[i]));
    sp_PolyArray_push(r, sp_box_poly_array(pair));
  }
  return r;
}
sp_PolyArray *sp_proc_parameters(sp_Proc *p) { SP_GC_ROOT(p); sp_PolyArray *r = sp_PolyArray_new(); if (!p || p->param_count <= 0 || !p->param_kinds) return r; SP_GC_ROOT(r); for (sp_int i = 0; i < p->param_count; i++) { sp_PolyArray *pair = sp_PolyArray_new(); sp_PolyArray_push(pair, sp_box_sym(p->param_kinds[i])); if (p->param_names && p->param_names[i] >= 0) sp_PolyArray_push(pair, sp_box_sym(p->param_names[i])); sp_PolyArray_push(r, sp_box_poly_array(pair)); } return r; }
void sp_curry_scan(void *p) { sp_Curry *c = (sp_Curry *)p; if (c->target) sp_gc_mark(c->target); for (sp_int i = 0; i < c->nargs && i < 16; i++) sp_mark_rbval(c->args[i]); }
sp_Curry *sp_curry_new(sp_Proc *p) {
  SP_GC_ROOT(p);  /* the target proc has no other root across this alloc */
  sp_Curry *c = (sp_Curry *)sp_gc_alloc(sizeof(sp_Curry), NULL, sp_curry_scan);
  c->target = p; c->nargs = 0;
  /* no count given: realize at the target's required-parameter count (CRuby's
     min arity; a negative arity encodes it as -req-1) */
  c->arity = p ? (p->arity < 0 ? -p->arity - 1 : p->arity) : 0;
  return c;
}
/* Proc#curry(n): the count overrides the default. CRuby validates n against
   a lambda's min..max arity at the curry call, before anything is applied.
   The min comes off the target's arity; the max only the compiler can see
   (an optional widens it, a rest lifts it), so the call site passes it in --
   max < 0 means unlimited-or-unknown, and the message then says "min+". */
sp_Curry *sp_curry_new_n(sp_Proc *p, sp_int n, sp_int max) {
  /* an int-typed slot's nil sentinel is CRuby's nil count: no count at all */
  if (n == SP_INT_NIL) return sp_curry_new(p);
  if (p && p->lambda_p) {
    sp_int min = p->arity < 0 ? -p->arity - 1 : p->arity;
    sp_int mx = max >= 0 ? max : (p->arity >= 0 ? p->arity : -1);
    /* the max is the compiler's guess from a visible parameter list; the min
       is the target's own truth. A guess below it names a different write of
       the same name -- trust the target, drop the guess. */
    if (mx >= 0 && mx < min) mx = -1;
    if (n < min || (mx >= 0 && n > mx)) {
      const char *want = mx < 0 ? sp_sprintf("%lld+", (long long)min)
                       : mx == min ? sp_sprintf("%lld", (long long)min)
                       : sp_sprintf("%lld..%lld", (long long)min, (long long)mx);
      /* both strings live on the collected heap; the second sp_sprintf and
         the raise path itself allocate, so root them across those */
      SP_GC_ROOT_STR(want);
      const char *msg = sp_sprintf("wrong number of arguments (given %lld, expected %s)",
                                   (long long)n, want);
      SP_GC_ROOT_STR(msg);
      sp_raise_cls("ArgumentError", msg);
    }
  }
  sp_Curry *c = sp_curry_new(p);
  c->arity = n < 0 ? 0 : n;
  return c;
}
/* Each accumulated argument is stored boxed so a non-int arg (a String, an
   object, ...) keeps its type through the deferred call (#3183). */
sp_Curry *sp_curry_apply(sp_Curry *c, sp_RbVal arg) {SP_GC_ROOT_RBVAL(arg);
  /* root the source accumulator: in a chained apply it is only referenced
     from a C argument slot, and this allocation can collect */
  SP_GC_ROOT(c);
  sp_Curry *n = (sp_Curry *)sp_gc_alloc(sizeof(sp_Curry), NULL, sp_curry_scan);
  *n = *c;
  if (n->nargs < 16) n->args[n->nargs++] = arg;
  return n;
}
/* Publish the accumulated (boxed) args on the side-channel: a poly-param
   target reads its arguments back from there, keeping each arg's real type. */
void sp_curry_publish_args(sp_Curry *c) {
  for (sp_int i = 0; i < c->nargs && i < 16; i++)
    _sp_proc_poly_args[i] = c->args[i];
}

/* Method#to_proc: wrap the bound method in a Proc whose trampoline forwards
   through the (void *self, sp_int...) ABI (the arity dispatches the cast). */
void sp_bm_cap_scan(void *p) { sp_gc_mark(p); }
/* Whether every fixed position of the stamped signature is a scalar-kind
   token (the TY_UNKNOWN wildcard 0 through TY_NIL 4; see abi_sig_token in
   codegen_call.c). A pointer token is 100000 + TyKind. The generic
   Method#to_proc trampoline has only the raw sp_int register args the proc
   ABI hands it and cannot check each argument's Ruby class the way a typed
   call site's sp_bm_legacy_abi_ok does, so a pointer-typed parameter would
   take an Integer argument as a raw address and dereference it -- e.g.
   `[obj.method(:str_method)][0].to_proc.call(1)` reached sp_str_length(1)
   and segfaulted (#4395). Decline such signatures here. */
static int sp_bm_sig_scalar_only(const char *sig, sp_int n) {
  if (!sig) return 0;
  for (sp_int k = 0; k < n; k++) {
    sp_int code = 0;
    for (int i = 0; i < 8; i++) code = code * 10 + (sig[8 * k + i] - '0');
    if (code >= 100000) return 0;
  }
  return 1;
}
sp_int sp_method_proc_tramp(void *cap, sp_int argc, sp_int *args) {
  sp_BoundMethod *m = (sp_BoundMethod *)cap;
  if (!m || !m->fn) return 0;
  /* A Method read out of a poly slot carries no call-site types, so this
     generic trampoline may only forward to a target whose stamped legacy ABI
     is callable at the exact fixed arity the C signature reads, and whose
     parameters are all scalar. Any other target -- a rest/optional/keyword
     parameter, a float/poly/by-value-struct parameter, a pointer-typed
     parameter (this route cannot check the argument's class), an unbound
     Method, or a mismatched argument count -- would take the sp_int register
     as the wrong C type: the callee prologue roots a garbage rest pointer
     (SP_GC_ROOT(lv_<rest>)) and the next collection dereferences it, or a
     pointer parameter dereferences an Integer, a SIGSEGV (#4395). The typed
     `.to_proc` path emits a per-signature trampoline and never reaches here,
     so declining here only affects a Method that travelled through a poly
     slot; raise the same NoMethodError the poly-call gate produces instead of
     reading garbage. */
  if (!m->legacy_int_abi || m->unbound || m->legacy_fixed > 16 || (m->legacy_ret == SP_BM_RET_POLY && m->legacy_fixed > 8) ||
      (m->legacy_rest ? argc < m->legacy_fixed : argc != m->legacy_fixed) ||
      !sp_bm_sig_scalar_only(m->legacy_sig, m->legacy_fixed))
    sp_raise_cls("NoMethodError", "undefined method 'call' for an instance of Method");
  /* A proc publishes its result through the boxed side-channel, which every
     generated proc body writes; this trampoline only returned it, so a caller
     reading the slot saw a stale value (#3692). The casts below already assume
     the target's sp_int ABI, so box the same answer. */
  #define SP_BM_TRAMP_RET(EXPR) do { sp_int _r = sp_bm_norm_ret(m, (EXPR)); _sp_proc_poly_ret = sp_bm_box_ret(m, _r); return _r; } while (0)
  /* A poly-returning target answers a 16-byte sp_RbVal in two registers that
     no sp_int cast can read: take the sp_RbVal cast, publish the value in the
     boxed slot and return 0, the way a generated poly-valued proc body does. */
  #define SP_BM_TRAMP_POLY(EXPR) do { _sp_proc_poly_ret = (EXPR); return 0; } while (0)
  if (m->legacy_ret == SP_BM_RET_POLY) {
    if (!m->recv_bound) {
      switch (argc) {
        case 0: SP_BM_TRAMP_POLY(((sp_RbVal (*)(void))(uintptr_t)m->fn)());
        case 1: SP_BM_TRAMP_POLY(((sp_RbVal (*)(sp_int))(uintptr_t)m->fn)(args[0]));
        case 2: SP_BM_TRAMP_POLY(((sp_RbVal (*)(sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1]));
        case 3: SP_BM_TRAMP_POLY(((sp_RbVal (*)(sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2]));
        case 4: SP_BM_TRAMP_POLY(((sp_RbVal (*)(sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3]));
        case 5: SP_BM_TRAMP_POLY(((sp_RbVal (*)(sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4]));
        case 6: SP_BM_TRAMP_POLY(((sp_RbVal (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5]));
        case 7: SP_BM_TRAMP_POLY(((sp_RbVal (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6]));
        default: SP_BM_TRAMP_POLY(((sp_RbVal (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]));
      }
    }
    switch (argc) {
      case 0: SP_BM_TRAMP_POLY(((sp_RbVal (*)(void *))(uintptr_t)m->fn)(m->self));
      case 1: SP_BM_TRAMP_POLY(((sp_RbVal (*)(void *, sp_int))(uintptr_t)m->fn)(m->self, args[0]));
      case 2: SP_BM_TRAMP_POLY(((sp_RbVal (*)(void *, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1]));
      case 3: SP_BM_TRAMP_POLY(((sp_RbVal (*)(void *, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2]));
      case 4: SP_BM_TRAMP_POLY(((sp_RbVal (*)(void *, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3]));
      case 5: SP_BM_TRAMP_POLY(((sp_RbVal (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4]));
      case 6: SP_BM_TRAMP_POLY(((sp_RbVal (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5]));
      case 7: SP_BM_TRAMP_POLY(((sp_RbVal (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6]));
      default: SP_BM_TRAMP_POLY(((sp_RbVal (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]));
    }
  }
  #undef SP_BM_TRAMP_POLY
  /* A top-level method has no self parameter. The self-ful casts below would
     put `m->self` (NULL) in the leading C slot, shifting every argument by
     one -- `[method(:top_add)][0].to_proc.call(1, 2)` answered 1 instead of 3
     (#4395). Select the cast by whether the Method carries a receiver, the
     same way the emitted `.call`/`[]` arms do. */
  if (!m->recv_bound) {
    switch (argc) {
      case 0: SP_BM_TRAMP_RET(((sp_int (*)(void))(uintptr_t)m->fn)());
      case 1: SP_BM_TRAMP_RET(((sp_int (*)(sp_int))(uintptr_t)m->fn)(args[0]));
      case 2: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1]));
      case 3: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2]));
      case 4: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3]));
      case 5: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4]));
      case 6: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5]));
      case 7: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6]));
      case 8: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]));
      case 9: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8]));
      case 10: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9]));
      case 11: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10]));
      case 12: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11]));
      case 13: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12]));
      case 14: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13]));
      case 15: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14]));
      default: SP_BM_TRAMP_RET(((sp_int (*)(sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15]));
    }
  }
  switch (argc) {
    case 0: SP_BM_TRAMP_RET(((sp_int (*)(void *))(uintptr_t)m->fn)(m->self));
    case 1: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int))(uintptr_t)m->fn)(m->self, args[0]));
    case 2: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1]));
    case 3: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2]));
    case 4: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3]));
    case 5: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4]));
    case 6: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5]));
    case 7: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6]));
    case 8: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]));
    case 9: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8]));
    case 10: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9]));
    case 11: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10]));
    case 12: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11]));
    case 13: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12]));
    case 14: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13]));
    case 15: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14]));
    default: SP_BM_TRAMP_RET(((sp_int (*)(void *, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int, sp_int))(uintptr_t)m->fn)(m->self, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11], args[12], args[13], args[14], args[15]));
  }
  #undef SP_BM_TRAMP_RET
}
sp_Proc *sp_method_to_proc(sp_BoundMethod *m) {
  return sp_proc_new_meta((void *)sp_method_proc_tramp, m, sp_bm_cap_scan, 1, TRUE, 0, NULL, NULL);
}
/* Bound Method object: `obj.method(:foo)` / `method(:foo)`. `self` is the
   bound receiver (NULL for a top-level method), `fn` the function address
   (cast to the right signature at the call site), `name` the method name
   (a string literal). `self_kind` says whether `self` is a reference
   the collector should follow, and of which kind. */
void sp_BoundMethod_scan(void *p) {
  sp_BoundMethod *m = (sp_BoundMethod *)p;
  if (!m->self) return;
  if (m->self_kind == SP_BM_SELF_OBJ) sp_gc_mark(m->self);
  else if (m->self_kind == SP_BM_SELF_STR) sp_mark_string((const char *)m->self);
}
