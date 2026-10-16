#ifndef SP_PROC_H
#define SP_PROC_H
/* sp_proc.h -- sp_Proc / sp_Curry struct layouts + cold ops.
 *
 * sp_proc_call itself (the hot per-call dispatch) stays a plain
 * (non-static) function defined directly in spinel_rt.h -- like
 * sp_sprintf/sp_argv, its body is resolved at the final link against the
 * generated TU, so it doesn't need to move for lib/sp_proc.c to reach it.
 * _sp_proc_poly_args/_sp_proc_poly_ret (the boxed calling-convention side
 * channel) are likewise already non-static SP_TLS globals in
 * spinel_rt.h; only extern declarations are needed here.
 *
 * Proc#>>/<</compose and the Proc-return (non-local return via longjmp)
 * machinery stay in spinel_rt.h: sp_proc_compose_fn calls sp_poly_to_i
 * (a value-dispatch function that's hot in optcarrot and excluded from
 * eviction), and proc-return threads through the TU-local exception-stack
 * globals (sp_exc_top / sp_unwind_kind / sp_proc_ret_head).
 *
 * 0 optcarrot uses for every function below.
 */
#include "sp_types.h"   /* sp_int, sp_sym, sp_bool */
#include "sp_gc.h"      /* sp_RbVal, sp_gc_alloc, sp_gc_mark */
#include "sp_alloc.h"   /* sp_PolyArray, sp_box_sym, sp_box_poly_array, sp_raise_cls */

typedef struct sp_Proc { void *fn; void *cap; void (*cap_scan)(void *); sp_int arity; sp_bool lambda_p; sp_int param_count; const sp_sym *param_kinds; const sp_sym *param_names; sp_bool frozen; /* Object#freeze observed (sp_gc_alloc zero-fills) */ void *origin; /* dup/clone lineage root for Proc#== (NULL: self is the root) */ } sp_Proc;
/* arity: the count this accumulator realizes at -- Proc#curry(n)'s n, else
   the target's required-parameter count (CRuby's min arity, so a variadic
   base realizes on its first call). Carried here so a curry that travels
   through a container or an untyped slot still knows when it is done. */
typedef struct { sp_Proc *target; sp_int arity; sp_int nargs; sp_RbVal args[16]; } sp_Curry;

sp_int sp_proc_call(sp_Proc *p, sp_int argc, sp_int *args);   /* defined in the generated TU */
extern SP_TLS sp_RbVal _sp_proc_poly_args[16];                   /* defined in the generated TU */
extern SP_TLS sp_RbVal _sp_proc_poly_ret;                        /* defined in the generated TU */

/* The lineage root of a proc: dups/clones of one proc share it, so Proc#== /
   #eql? compare roots (a dup == its original) while distinct literals differ. */
static inline sp_Proc *sp_proc_root(sp_Proc *p) { return (p && p->origin) ? (sp_Proc *)p->origin : p; }

void sp_Proc_scan(void *p);
sp_Proc *sp_proc_new_meta(void *fn, void *cap, void (*cap_scan)(void *), sp_int arity, sp_bool lambda_p, sp_int param_count, const sp_sym *param_kinds, const sp_sym *param_names);
sp_Proc *sp_proc_dup(sp_Proc *p, int keep_frozen);
sp_Proc *sp_proc_new(void *fn, void *cap, void (*cap_scan)(void *));
sp_int sp_proc_arity(sp_Proc *p);
sp_bool sp_proc_lambda_p(sp_Proc *p);
const char *sp_proc_inspect(sp_Proc *p);
void sp_proc_lambda_arity_check(sp_int argc, sp_int req, sp_int opt, sp_bool has_rest, sp_bool has_kw);
sp_PolyArray *sp_proc_parameters_ids(sp_Proc *p, int mode, sp_sym req_id, sp_sym opt_id);
sp_PolyArray *sp_proc_parameters(sp_Proc *p);
void sp_curry_scan(void *p);
sp_Curry *sp_curry_new(sp_Proc *p);
sp_Curry *sp_curry_new_n(sp_Proc *p, sp_int n, sp_int max);
sp_Curry *sp_curry_apply(sp_Curry *c, sp_RbVal arg);
void sp_curry_publish_args(sp_Curry *c);

/* ---- BoundMethod (Method object): sp_bound_method_new is hot in
   optcarrot (69 uses), so it stays static inline here -- pure textual
   move, same per-TU inlining as before. sp_BoundMethod_scan is a GC
   callback (only ever invoked indirectly through the function pointer
   sp_bound_method_new hands to sp_gc_alloc), so moving its body to
   lib/sp_proc.c costs nothing -- taking its address from an inline
   context is just an embedded constant, not a call site. ---- */
/* What `self` holds, so the scan knows whether to follow it: a Method can be
   bound to an Integer or a Float as easily as to an object, and marking the
   raw value as a pointer reads whatever address it names. */
#define SP_BM_SELF_NONE 0   /* not a reference: a number, a class value, unbound */
#define SP_BM_SELF_OBJ  1
#define SP_BM_SELF_STR  2
/* How the legacy sp_int C return is boxed back into a Ruby value. A regular
   method riding the cast can only return TY_INT, but a synthesized typed-array
   adapter (`<int_array>.method(:push)`) has an sp_int C return whose Ruby value
   is the array/string it launder through the register. */
#define SP_BM_RET_INT       0
#define SP_BM_RET_STR       1
#define SP_BM_RET_INT_ARRAY 2
#define SP_BM_RET_STR_ARRAY 3
/* A void C return (a Ruby method whose value is nil, or unused): the cast
   reads an undefined register and the answer is nil regardless. */
#define SP_BM_RET_NIL       4
/* The C function returns sp_RbVal (a poly Ruby return): a 16-byte struct
   comes back in two registers, which no sp_int cast can read, so the call
   arms take the sp_RbVal cast for this kind and box nothing. */
#define SP_BM_RET_POLY      5
/* A bool C return: the callee writes the low byte of the return register and
   leaves the rest undefined (SysV x86-64 and AArch64 both), so the low byte
   is the whole answer. A Symbol is its id in an sp_int. */
#define SP_BM_RET_BOOL      6
#define SP_BM_RET_SYM       7
/* A user-class pointer return: the low byte is the kind and the bits above it
   carry the class id the bind site knew statically (a class without
   subclasses), or nothing when the object carries its own id in its first
   field (a subclassed class: the _dyn box reads it, as the generated boxing
   sites do). Unlike the kinds above, this one is NOT a plain enumerator, so
   sp_bm_box_ret matches on the low byte. */
#define SP_BM_RET_OBJ       8
#define SP_BM_RET_OBJ_DYN   9
#define SP_BM_RET_KIND(r)   ((r) & 0xff)
#define SP_BM_RET_OBJ_OF(cls) (SP_BM_RET_OBJ | ((sp_int)(cls) << 8))
typedef struct sp_BoundMethod { void *self; sp_int fn; const char *name; sp_int arity;
  const char *desc;   /* compile-time #inspect rendering ("#<Method: Owner#name(params)>"), or NULL */
  sp_int self_kind;  /* SP_BM_SELF_* */
  sp_int unbound;    /* built by #unbind on a boxed Method: reports UnboundMethod */
  sp_int recv_bound; /* the target's C ABI takes the bound receiver as its leading
                        argument, so the self-ful cast must be used even when
                        `self` is NULL because the receiver VALUE is zero
                        (Integer 0, false, nil) (#4395). `self != NULL` cannot
                        tell a top-level method (self-less) from a
                        receiver-bound wrapper whose value is 0 (#4395); this
                        flag is the bind site's receiver-bound fact. It is
                        independent of legacy_int_abi: an object-bound Method
                        with a non-int return still needs its self slot. */
  sp_int legacy_int_abi; /* whether the target can ride the legacy sp_int-cast poly-call
                            path: 0 declines, 1 callable. A regular method is only
                            callable with a TY_INT C return; a synthesized __bam_
                            wrapper and the typed-array adapters may instead launder a
                            String/array, recorded by legacy_ret. See
                            method_legacy_int_abi (#4395). */
  const char *legacy_sig; /* per-position C ABI type tokens, eight chars each, or NULL.
                             Each scalar kind (int/bool/symbol/nil) has its own token,
                             TY_UNKNOWN is the wildcard 0, and every other kind uses
                             100000 + TyKind (an object class encodes its class id in
                             TyKind), so a bool parameter never accepts an int and a
                             String parameter never accepts an IntArray. */
  sp_int legacy_fixed;  /* number of fixed positional C slots the signature fills */
  sp_int legacy_rest;   /* always 0 now: method_legacy_int_abi declines every rest
                           parameter (its trailing sp_PolyArray* has no slot in the
                           static cast), but the runtime gate keeps the rest-form
                           check for any future caller that stamps it */
  sp_int legacy_ret;    /* SP_BM_RET_*: how to box the sp_int C return */
} sp_BoundMethod;
void sp_bm_cap_scan(void *p);
sp_int sp_method_proc_tramp(void *cap, sp_int argc, sp_int *args);
sp_Proc *sp_method_to_proc(sp_BoundMethod *m);
void sp_BoundMethod_scan(void *p);

static inline sp_BoundMethod *sp_bound_method_new(void *self, sp_int self_kind, sp_int fn, const char *name, sp_int arity) { sp_BoundMethod *m = (sp_BoundMethod *)sp_gc_alloc(sizeof(sp_BoundMethod), NULL, sp_BoundMethod_scan); m->self = self; m->self_kind = self_kind; m->fn = fn; m->name = name; m->arity = arity; m->desc = NULL; m->unbound = 0; m->recv_bound = 0; m->legacy_int_abi = 0; m->legacy_sig = NULL; m->legacy_fixed = 0; m->legacy_rest = 0; m->legacy_ret = SP_BM_RET_INT; return m; }
/* Tag a freshly-built Method with whether its target has the legacy sp_int C
   ABI, the per-position type signature, the fixed/rest slot counts, and how
   its sp_int C return boxes. The constructors default to 0 (unsafe), so every
   statically-known binding sets this before the Method can reach a poly slot
   (#4395). */
static inline sp_BoundMethod *sp_bm_set_abi(sp_BoundMethod *m, sp_int recv_bound, sp_int legacy_int_abi, const char *legacy_sig, sp_int legacy_fixed, sp_int legacy_rest, sp_int legacy_ret) { m->recv_bound = recv_bound; m->legacy_int_abi = legacy_int_abi; m->legacy_sig = legacy_sig; m->legacy_fixed = legacy_fixed; m->legacy_rest = legacy_rest; m->legacy_ret = legacy_ret; return m; }
/* Box the raw sp_int a legacy-ABI Method returned according to the Ruby return
   the bind site recorded. A regular method is always SP_BM_RET_INT; a typed
   array adapter that returns self (push) or a laundered element (StrArray
   get/set) boxes the real value instead of mis-tagging the pointer as an
   Integer (#4395). SP_BM_RET_INT goes through sp_box_int_or_nil: an IntArray
   `[]` out of range answers the nullable SP_INT_NIL sentinel (INTPTR_MIN),
   which sp_box_int would hand back as a truthy Integer instead of nil, and a
   regular TY_INT method uses the same reserved sentinel for nil (see
   sp_poly_as_int_or_nil / sp_box_int_or_nil in sp_alloc.h) so boxing it as nil
   is the documented invariant. */
static inline sp_RbVal sp_bm_box_ret(sp_BoundMethod *m, sp_int raw) {
  sp_int r = m ? m->legacy_ret : SP_BM_RET_INT;
  switch (SP_BM_RET_KIND(r)) {
    case SP_BM_RET_STR:       return sp_box_str((const char *)(uintptr_t)raw);
    case SP_BM_RET_INT_ARRAY: return sp_box_nullable_obj((void *)(uintptr_t)raw, SP_BUILTIN_INT_ARRAY);
    case SP_BM_RET_STR_ARRAY: return sp_box_nullable_obj((void *)(uintptr_t)raw, SP_BUILTIN_STR_ARRAY);
    case SP_BM_RET_NIL:       return sp_box_nil();
    case SP_BM_RET_BOOL:      return sp_box_bool((raw & 0xff) != 0);
    case SP_BM_RET_SYM:       return (sp_sym)raw != (sp_sym)-1 ? sp_box_sym((sp_sym)raw) : sp_box_nil();
    case SP_BM_RET_OBJ:       return sp_box_nullable_obj((void *)(uintptr_t)raw, (int)(r >> 8));
    case SP_BM_RET_OBJ_DYN:   return sp_box_nullable_obj_dyn((void *)(uintptr_t)raw, 0);
    default:                  return sp_box_int_or_nil(raw);
  }
}
/* The raw register as the trampoline hands it back untouched to a typed
   caller: a bool callee wrote only the low byte, so normalise it to 0/1 there;
   every other kind is already the value (an int, a Symbol id, a pointer). */
static inline sp_int sp_bm_norm_ret(sp_BoundMethod *m, sp_int raw) {
  return (m && SP_BM_RET_KIND(m->legacy_ret) == SP_BM_RET_BOOL) ? ((raw & 0xff) != 0) : raw;
}
/* Mark a statically-built instance_method/#unbind result as an UnboundMethod,
   so a later dynamic .call/[] through a container sees m->unbound and raises
   instead of invoking the instance C function with no self (#4395). */
static inline sp_BoundMethod *sp_bm_set_unbound(sp_BoundMethod *m) { if (m) m->unbound = 1; return m; }
/* Whether a call passing `argc` arguments whose per-position ABI type tokens
   (eight chars each; see abi_sig_token in codegen_call.c) are `arg_sig` can
   ride the target's legacy sp_int ABI.
   The count must fit the target's fixed signature and every fixed position's
   C type must match exactly: a bool parameter is never handed an int, a
   String* is never handed an IntArray*, and an sp_Foo* is never handed an
   sp_Bar*. An optional parameter is only safe at full arity (the C signature
   reads every fixed slot), so a shorter call declines. Declines a non-callable
   target, an unbound Method, and a non-int return (legacy_int_abi == 0). */
static inline sp_bool sp_bm_sig_pos_match(const char *a, const char *b) {
  if (memcmp(a, b, 8) == 0) return TRUE;
  /* 0 is the TY_UNKNOWN wildcard: it accepts any scalar-kind token, and a
     scalar-kind arg accepts an unknown parameter. Pointer tokens carry the
     100000 offset, so they never match the wildcard. */
  sp_int va = 0, vb = 0;
  for (int i = 0; i < 8; i++) { va = va * 10 + (a[i] - '0'); vb = vb * 10 + (b[i] - '0'); }
  if (va == 0) return vb < 100000;
  if (vb == 0) return va < 100000;
  return FALSE;
}
static inline sp_bool sp_bm_legacy_abi_ok(sp_BoundMethod *m, sp_int argc, const char *arg_sig) {
  if (!m || m->unbound || !m->legacy_int_abi || !m->legacy_sig || !arg_sig) return FALSE;
  if (m->legacy_rest) { if (argc < m->legacy_fixed) return FALSE; }
  else if (argc != m->legacy_fixed) return FALSE;
  sp_int n = argc < m->legacy_fixed ? argc : m->legacy_fixed;
  for (sp_int k = 0; k < n; k++)
    if (!sp_bm_sig_pos_match(arg_sig + 8 * k, m->legacy_sig + 8 * k)) return FALSE;
  return TRUE;
}
static inline sp_BoundMethod *sp_bound_method_new_d(void *self, sp_int self_kind, sp_int fn, const char *name, sp_int arity, const char *desc) { sp_BoundMethod *m = sp_bound_method_new(self, self_kind, fn, name, arity); m->desc = desc; return m; }
/* Method#unbind on a BOXED method: the same target with the receiver dropped.
   A boxed value carries no syntax for the compile-time unbound rendering, so
   the copy records it (the #class arm reads `unbound`) (#3692). */
static inline sp_BoundMethod *sp_bm_unbind(sp_BoundMethod *m) {
  if (!m) return NULL;
  sp_BoundMethod *u = sp_bound_method_new(NULL, SP_BM_SELF_NONE, m->fn, m->name, m->arity);
  u->desc = m->desc;
  u->unbound = 1;
  u->legacy_int_abi = m->legacy_int_abi;
  u->legacy_sig = m->legacy_sig;
  u->legacy_fixed = m->legacy_fixed;
  u->legacy_rest = m->legacy_rest;
  u->legacy_ret = m->legacy_ret;
  return u;
}

#endif
