/*
** re_spinel.h - spinel's surface of the regexp engine (re_spinel.c)
**
** The engine's own header, re_internal.h, is mruby-regexp's; the calls spinel
** makes into the engine are these. lib/sp_re.h and the strscan package name
** them again for the runtime, which does not include the engine's headers.
*/
#ifndef SP_RE_SPINEL_H
#define SP_RE_SPINEL_H
#include "re_internal.h"

mrb_regexp_pattern *re_compile(const char *pattern, mrb_int len, uint32_t flags);
void re_free(mrb_regexp_pattern *pat);
int spinel_re_exec(const mrb_regexp_pattern *pat, const char *str, mrb_int len, mrb_int start,
            int *captures, int captures_size, int binary);
int re_exec_attempt(const mrb_regexp_pattern *pat, const char *str, mrb_int len, mrb_int start,
                    int *captures, int captures_size, int binary, int *attempt);
void sp_re_set_error_handler(void (*fn)(const char *msg));
int re_utf8_charlen(const char *s, const char *end);
int re_num_named(const mrb_regexp_pattern *pat);
const char *re_named_name(const mrb_regexp_pattern *pat, int i, int *group_out);
const char *re_group_name(const mrb_regexp_pattern *pat, int group);
int re_named_group(const mrb_regexp_pattern *pat, const char *name);
#endif
