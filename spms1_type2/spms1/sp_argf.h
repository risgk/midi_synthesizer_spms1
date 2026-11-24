#ifndef SP_ARGF_H
#define SP_ARGF_H
/* sp_argf.h -- ARGV/ARGF state + cold accessors.
 *
 * sp_argv is populated by the generated main() (codegen emits
 * `sp_argv.len = argc - 1; sp_argv.data = ...` directly), so its storage
 * stays defined in the generated TU -- just non-static now, resolved at
 * the final link the same way lib/sp_core.c reaches sp_sprintf. sp_argf_obj
 * (ARGF's single-instance read cursor) follows the same pattern.
 */
#include "sp_types.h"   /* sp_int */
#include <stdio.h>      /* FILE */

typedef struct{const char**data;sp_int len;}sp_Argv;
extern sp_Argv sp_argv;               /* defined in the generated TU */

typedef struct { FILE *cur; int started; const char *fname; } sp_Argf;
extern sp_Argf sp_argf_obj;            /* defined in the generated TU */

/* the ARGV-as-poly-array materialization cache: allocated lazily by
   sp_get_ARGV (lib/sp_cold.c), read by sp_re_mark_globals's GC root scan
   (spinel_rt.h) -- extern so both sides see the same object. */
extern sp_StrArray *sp_argv_array_cache;

sp_StrArray *sp_get_ARGV(void);

/* $LOADED_FEATURES (`$"`): an Array of Strings the program reads and pushes
   onto. It starts empty: the files the program requires were compiled into
   it rather than loaded as it runs, so none is listed. Allocated lazily by
   sp_get_loaded_features (lib/sp_cold.c) and marked with the runtime
   globals, as ARGV's array is. */
extern sp_StrArray *sp_loaded_features_cache;
sp_StrArray *sp_get_loaded_features(void);
/* `require path` with a path known only at run time: a feature the program
   was compiled with (the table the compiler emits) is already loaded, and
   anything else raises CRuby's LoadError. A path matches a feature as
   written or as the end of a longer path (`File.join(__dir__, "x")`), with
   or without its ".rb". */
void sp_require_computed(const char *path, const char *const *features, int n);

/* $LOAD_PATH (`$:`, `$-I`): an Array of Strings the program reads and
   changes. It starts empty: requires are resolved when the program is
   compiled, so there is no directory to look in as it runs, and a change
   the program makes to it looks nothing up. Allocated and marked as
   $LOADED_FEATURES' array is. */
extern sp_StrArray *sp_load_path_cache;
sp_StrArray *sp_get_load_path(void);
int sp_argf_ensure(void);
const char *sp_argf_gets(void);
const char *sp_argf_read(void);
sp_StrArray *sp_argf_readlines(void);
const char *sp_argf_filename(void);
sp_bool sp_argf_eof(void);

#endif
