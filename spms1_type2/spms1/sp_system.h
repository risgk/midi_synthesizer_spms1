/* sp_system.h -- system()/backtick support in libspinel_rt.a.
 *
 * `sp_last_status` backs Ruby's `$?` (the exit status of the last
 * `system` / backtick). `sp_system_args` runs argv[0] with the rest as
 * arguments (the multi-arg `system(...)` form), setting `sp_last_status`
 * and returning 1 when the child exited 0, 0 for another exit, and -1 when
 * the command could not run (CRuby's true, false and nil; see
 * sp_system_answer). The result is an `int` to stay decoupled from the
 * runtime's typedefs.
 */
#ifndef SP_SYSTEM_H
#define SP_SYSTEM_H

extern int sp_last_status;
/* the pid of the child sp_last_status is from; 0 until a child is waited
   for, when `$?` is nil */
extern int sp_last_pid;
int sp_system_args(int argc, const char *const *argv);
/* the same with envp (NULL-terminated "NAME=value" entries) as the child's
   whole environment, or this process's when envp is NULL */
int sp_system_envp(int argc, const char *const *argv, char **envp);
/* the same with prog as the program and argv[0] as the argv0 it sees
   (system([program, argv0], ...)): no shell, no splitting into words */
int sp_system_prog_envp(const char *prog, int argc, const char *const *argv, char **envp);
/* CRuby's test of whether the shell runs a one-String command line, and
   the words of a line it does not run (one malloc block, NULL-terminated;
   Process.spawn and system share both) */
int sp_cmdline_shell_p(const char *line);
char **sp_cmdline_words(const char *line, int *argc_out);

#endif
