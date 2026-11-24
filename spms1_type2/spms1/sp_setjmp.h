/* sp_setjmp.h -- the runtime's setjmp/longjmp, or none of it.
 *
 * Built --exceptions=abort (wasm32-wasi, for a host without the
 * exception-handling proposal: #8401), the runtime has no setjmp/longjmp at
 * all. wasi-libc's <setjmp.h> refuses to compile without that proposal, and
 * a function that calls either is lowered to its instructions, which such a
 * host refuses for the whole module. So jmp_buf is a stand-in, a frame's
 * setjmp answers "entered normally", and an unwind that would have
 * longjmp'd to one traps (sp_exc_abort_trap, lib/sp_exc.c): the driver
 * refuses every construct that needs a frame to catch it, and sp_raise_cls
 * reports a raise as uncaught before it traps.
 *
 * Otherwise the platform's <setjmp.h>, with the _ variants on Darwin, whose
 * setjmp saves the signal mask -- a sigprocmask syscall on every
 * begin/rescue that nothing here needs (glibc's longjmp does not restore it
 * either). Here so the generated TU and the runtime agree on the pair. */
#ifndef SP_SETJMP_H
#define SP_SETJMP_H

#ifdef SP_EXC_ABORT
typedef long jmp_buf[1];
typedef jmp_buf sigjmp_buf;
#ifdef __GNUC__
__attribute__((noreturn))
#endif
void sp_exc_abort_trap(void);
#define setjmp(env) ((void)(env), 0)
#define longjmp(env, val) ((void)(env), (void)(val), sp_exc_abort_trap())
#define sigsetjmp(env, save) ((void)(env), (void)(save), 0)
#define siglongjmp(env, val) longjmp(env, val)
#else
#include <setjmp.h>
#ifdef __APPLE__
#define setjmp(env) _setjmp(env)
#define longjmp(env, val) _longjmp(env, val)
#endif
#endif

#endif
