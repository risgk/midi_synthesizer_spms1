#ifndef SP_EXC_CTX_H
#define SP_EXC_CTX_H
/* sp_exc_ctx.h -- the per-fiber exception/catch handler context (#1474) and
 * the proc-return home node whose chain it carries.
 *
 * Types only, plus the three context operations that touch nothing else
 * (sp_exc_ctx_new/free/mark, lib/sp_exc.c). sp_exc_ctx_save/load copy the
 * handler stacks in and out, and those stacks are TU-local statics of
 * spinel_rt.h, so the two stay there. */
#include "sp_setjmp.h"
#include "sp_types.h"   /* sp_int */
#include "sp_gc.h"      /* sp_RbVal */
#include "sp_inspect.h" /* sp_poly_recur_frame */
#ifdef SP_CEXT
#include "sp_cext.h"
#endif

/* A non-lambda proc's home method: a node on that method's C stack, linked
   onto the per-fiber chain sp_proc_ret_head (see the proc-return machinery in
   spinel_rt.h). */
typedef struct sp_proc_home {
  jmp_buf jb;                 /* the home method's setjmp target (on its C stack) */
  sp_RbVal val;               /* the in-flight return value (nil until delivered) */
  int exc_top;                /* sp_exc_top at the method's entry */
  int catch_top;              /* sp_catch_top at the method's entry */
  int brk_top;                /* sp_brk_top at the method's entry: the break scopes a
                                 return longjmps past are dropped at the landing */
  int recur_mark;             /* walk-path depth at the method's entry (see sp_poly_recur_mark) */
  sp_int id;                 /* fresh id captured by the home's returning procs */
  struct sp_proc_home *prev;  /* enclosing home, forming the per-fiber chain */
} sp_proc_home;

/* The live prefix of every handler array, saved into the outgoing fiber's
   context and loaded from the incoming one's at each switch. */
typedef struct {
#ifdef SP_CEXT
  sp_cext_arena_mark *cext_marks;
  sp_cext_arena_context cext_arena;
#endif
  jmp_buf *es; const char **em; const char **ec; void **eo; int en, ecap;
  jmp_buf *cs; const char **ct; unsigned char *ctk; sp_RbVal *cv; int *cet;  int cn, ccap;
  jmp_buf *bs; sp_RbVal *bv; sp_int *bser; int *bet;     int bn, bcap;  /* break scopes */
  sp_proc_home *prhead;  /* this fiber's proc-return chain head (nodes on its C stack) */
  int uk, ut, ue; sp_proc_home *uh;  /* transient unwind state (in flight only while running ensures) */
  void **shand; int rn, rcap;        /* sp_exc_handling prefix [0..sp_rescue_sp) */
  void *pcause;                      /* sp_pending_cause */
  void *icause;                      /* sp_inflight_cause: the exception an ensure body runs for */
  sp_poly_recur_frame *rrf; int rrn, rrcap;  /* sp_poly_recur_stack prefix [0..sp_poly_recur_top) */
  int *rrem, *rrcm, *rrbm;           /* the walk-path marks of the exception, catch and break arms */
  int *erm, *ersm, *crm;             /* the GC-root and rescue-stack watermarks of the exception
                                        arms and the GC-root watermark of the catch arms: what a
                                        handler restores sp_gc_nroots / sp_rescue_sp to. They are
                                        per worker like the arms, so without travelling with the
                                        context a green thread that parked inside a begin and
                                        resumed after another fiber's arm sat at the same index
                                        restored the OTHER fiber's watermark: a raise's dead root
                                        stayed on the list and the next collection read a stack
                                        slot that was no longer a string (#4546) */
} sp_exc_ctx_t;

void *sp_exc_ctx_new(void);
void sp_exc_ctx_free(void *p);
void sp_exc_ctx_mark(void *p);   /* GC: a suspended fiber's carried exc objects */

#endif
