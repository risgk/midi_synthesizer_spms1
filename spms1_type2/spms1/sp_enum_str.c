/* lib/sp_enum_str.c -- Enumerators a String handle backs (--share-strings).

   The Enumerator of a blockless each_char, each_line, each_byte or
   each_codepoint over a shared String, the ones built on it (with_index,
   each_slice, each_cons) and their walk copies: an sp_EnumStr, the
   Enumerator with the fields only they use (lib/sp_enum.h). A unit of its
   own, so that the code no other Enumerator runs changes nothing that
   lib/sp_cold.c compiles. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "sp_alloc.h"
#include "sp_array.h"
#include "sp_str.h"
#include "sp_string.h"
#include "sp_enum.h"
extern SP_NORETURN void sp_raise_stop_iteration(sp_RbVal result);
void sp_Enumerator_scan(void *p);
sp_Enumerator *sp_enum_with_src(sp_Enumerator *e, sp_RbVal src, const char *meth);
sp_PolyArray *sp_str_chars_poly(const char *s);

/* --share-strings: the Enumerator of a blockless each_char, each_line,
   each_byte or each_codepoint over a shared String holds the String (its
   handle, str_h), as CRuby's holds the String object, and reads it when it
   is walked, not when it is made: each walk (a #next run, to_a, a block, a
   regrouping) starts by laying the items out again from the String as it
   is then, and reads a copy of the Enumerator holding them (sp_enum_walk),
   as CRuby's each_char takes a frozen copy at its first step; a walk
   nested in it lays them out again for itself. each_byte's walk reads the
   byte at its cursor, to the length the String has then, as CRuby's does,
   and so does each_codepoint's over a String that was ASCII where the walk
   started. */
static sp_PolyArray *sp_str_each_items(const char *s, unsigned char kind) {
  SP_GC_ROOT_STR(s);
  if (kind == SP_ENUM_STR_CHAR) return sp_str_chars_poly(s);
  if (kind == SP_ENUM_STR_LINE) return sp_str_lines_poly(s);
  sp_IntArray *ia = kind == SP_ENUM_STR_BYTE ? sp_str_bytes(s) : sp_str_codepoints(s);
  SP_GC_ROOT(ia);
  return sp_IntArray_to_poly(ia);
}
/* the handle's bytes as they are now, a String of its own */
static const char *sp_str_each_snapshot(sp_String *h) {
  char *s = (char *)sp_str_from_bytes(sp_String_cstr(h), (size_t)sp_String_length(h));
  if (h->binary) sp_str_mark_binary(s);
  return s;
}
static void sp_EnumStr_scan(void *p) {
  sp_EnumStr *t = (sp_EnumStr *)p;
  sp_Enumerator_scan(p);
  if (t->str_h) sp_gc_mark(t->str_h);
  if (t->str_snap) sp_mark_string(t->str_snap);
  if (t->der_src) sp_gc_mark(t->der_src);
  if (t->der_from) sp_gc_mark(t->der_from);
  if (t->ext) sp_gc_mark(t->ext);
  if (t->run_h) sp_gc_mark(t->run_h);
}
/* A live Enumerator over items, its fields past the Enumerator's zero-filled
   (sp_gc_alloc), laid out as sp_Enumerator_new_from_items lays one out */
static sp_Enumerator *sp_enum_str_new(sp_PolyArray *items) {
  SP_GC_ROOT(items);
  sp_EnumStr *t = (sp_EnumStr *)sp_gc_alloc(sizeof(sp_EnumStr), NULL, sp_EnumStr_scan);
  sp_Enumerator *e = &t->e;
  e->items = NULL; e->size = sp_box_nil(); e->feed = sp_box_nil(); e->gen_result = sp_box_nil(); e->source = sp_box_nil(); e->meth = SPL("each");
  e->str_tail = TRUE; e->live = TRUE;
  e->walk_buf = items; e->walk_done = TRUE;
  return e;
}
sp_Enumerator *sp_enum_str_dup(sp_Enumerator *e) {
  SP_GC_ROOT(e);
  sp_EnumStr *d = (sp_EnumStr *)sp_gc_alloc(sizeof(sp_EnumStr), NULL, sp_EnumStr_scan);
  *d = *sp_enum_str(e);
  return &d->e;
}
/* (a String that has not changed since the items were laid out keeps them:
   comparing its bytes costs far less than laying them out again) */
static void sp_enum_der_refill(sp_Enumerator *e);
void sp_enum_str_refill(sp_Enumerator *e) {
  SP_GC_ROOT(e);
  sp_EnumStr *t = sp_enum_str(e);
  if (t->der_src) { sp_enum_der_refill(e); return; }
  sp_String *h = (sp_String *)t->str_h;
  const char *old = t->str_snap;
  if (old && sp_str_byte_len(old) == sp_String_length(h) && !h->binary == !sp_str_is_binary(old) &&
      memcmp(old, sp_String_cstr(h), (size_t)sp_String_length(h)) == 0)
    return;
  const char *s = sp_str_each_snapshot(h);
  SP_GC_ROOT_STR(s);
  sp_PolyArray *items = sp_str_each_items(s, t->str_kind);
  sp_gc_wb((void *)e);
  e->walk_buf = items;
  t->str_snap = s;
  e->str_bytewise = t->str_kind == SP_ENUM_STR_BYTE || (t->str_kind == SP_ENUM_STR_CODEPOINT && sp_str_ascii_only(s));
}
sp_Enumerator *sp_enum_str_each_h(sp_String *h, const char *meth) {
  SP_GC_ROOT(h);
  if (!h) sp_nil_recv(meth);
  unsigned char kind = strcmp(meth, "each_char") == 0 ? SP_ENUM_STR_CHAR
                     : strcmp(meth, "each_line") == 0 ? SP_ENUM_STR_LINE
                     : strcmp(meth, "each_byte") == 0 ? SP_ENUM_STR_BYTE : SP_ENUM_STR_CODEPOINT;
  const char *s = sp_str_each_snapshot(h);
  SP_GC_ROOT_STR(s);
  sp_Enumerator *e = sp_enum_str_new(sp_str_each_items(s, kind));
  SP_GC_ROOT(e);
  sp_EnumStr *t = sp_enum_str(e);
  t->str_h = h; t->str_kind = kind; t->str_snap = s;
  e->str_bytewise = kind == SP_ENUM_STR_BYTE || (kind == SP_ENUM_STR_CODEPOINT && sp_str_ascii_only(s));
  return sp_enum_with_src(e, sp_box_obj(h, SP_BUILTIN_STRBUF), meth);
}
/* The items of an Enumerator built on one whose items are laid out at each
   walk (sp_enum_derive), from those items: [item, index] pairs counted
   from the offset, or the groups of each_slice / each_cons. */
static sp_PolyArray *sp_enum_der_items(sp_PolyArray *src, unsigned char kind, sp_int arg) {
  SP_GC_ROOT(src);
  sp_PolyArray *out = sp_PolyArray_new(); SP_GC_ROOT(out);
  sp_int len = src ? src->len : 0;
  if (kind == SP_ENUM_DER_PAIRS) {
    for (sp_int i = 0; i < len; i++) {
      sp_PolyArray *pair = sp_PolyArray_new(); SP_GC_ROOT(pair);
      sp_PolyArray_push(pair, src->data[i]);
      sp_PolyArray_push(pair, sp_box_int(arg + i));
      sp_PolyArray_push(out, sp_box_poly_array(pair));
    }
    return out;
  }
  /* (`len - i` keeps every sum in range for a large group size) */
  for (sp_int i = 0; i < len; i++) {
    if (kind == SP_ENUM_DER_CONS && len - i < arg) break;
    sp_int lim = len - i < arg ? len : i + arg;
    sp_PolyArray *g = sp_PolyArray_new(); SP_GC_ROOT(g);
    for (sp_int j = i; j < lim; j++) sp_PolyArray_push(g, src->data[j]);
    sp_PolyArray_push(out, sp_box_poly_array(g));
    if (kind == SP_ENUM_DER_SLICES) { if (len - i <= arg) break; i += arg - 1; }
  }
  return out;
}
static void sp_enum_der_refill(sp_Enumerator *e) {
  sp_EnumStr *t = sp_enum_str(e);
  sp_Enumerator *src = (sp_Enumerator *)t->der_src;
  sp_enum_str_refill(src);
  sp_PolyArray *from = src->walk_buf;
  if (from == t->der_from) return;
  sp_PolyArray *items = sp_enum_der_items(from, t->der_kind, t->der_arg);
  sp_gc_wb((void *)e);
  e->walk_buf = items;
  t->der_from = from;
}
sp_Enumerator *sp_enum_derive(sp_Enumerator *e, unsigned char kind, sp_int arg) {
  SP_GC_ROOT(e);
  if (kind != SP_ENUM_DER_PAIRS && arg < 1)
    sp_raise_cls("ArgumentError", kind == SP_ENUM_DER_CONS ? "invalid size" : "invalid slice size");
  sp_enum_str_refill(e);
  sp_PolyArray *from = e->walk_buf;
  sp_Enumerator *r = sp_enum_str_new(sp_enum_der_items(from, kind, arg));
  SP_GC_ROOT(r);
  sp_EnumStr *t = sp_enum_str(r);
  t->der_src = e; t->der_from = from; t->der_kind = kind; t->der_arg = arg;
  /* (inspected as built on e, as CRuby nests it) */
  r->source = sp_box_obj(e, SP_BUILTIN_ENUMERATOR); r->has_src = TRUE;
  r->yields_pair = kind == SP_ENUM_DER_PAIRS;
  const char *m = kind == SP_ENUM_DER_PAIRS ? SPL("with_index")
                : sp_sprintf(kind == SP_ENUM_DER_CONS ? "each_cons(%lld)" : "each_slice(%lld)", (long long)arg);
  /* (the name is a String of its own, young where r aged while it was made) */
  sp_gc_wb((void *)r);
  r->meth = m;
  return sp_enum_inherit_size(r, e);
}
/* See sp_enum.h. The copy is no live Enumerator: nothing lays its items out
   again, and it has no #next run of its own. */
sp_Enumerator *sp_enum_walk_copy(sp_Enumerator *e) {
  SP_GC_ROOT(e);
  sp_enum_str_refill(e);
  sp_Enumerator *w = sp_enum_str_dup(e);
  sp_EnumStr *t = sp_enum_str(w);
  w->items = e->walk_buf; w->walk_buf = NULL; w->walk_done = FALSE; w->walk_next = 0;
  w->live = FALSE; t->der_src = NULL; t->der_from = NULL;
  t->ext = NULL; t->ext_done = FALSE; w->cursor = 0; w->peeked = FALSE; w->peek_val = sp_box_nil(); t->run_h = NULL;
  return w;
}
/* #next and #peek of a live Enumerator, from the materialized paths
   (which read its run's items while there are any): a run of its own, from
   a walk copy made at the first step (ext). A run over items reads them
   through `items` from then on; a bytewise one reads the String's byte at
   the cursor, its #peek's item being the next #next's. A run that ended
   stays ended until #rewind. */
sp_RbVal sp_enum_live_step(sp_Enumerator *e, sp_bool peek) {
  sp_EnumStr *t = sp_enum_str(e);
  if (e->peeked) {
    /* (a bytewise #peek's item, whose step a #next takes) */
    if (!peek) { e->peeked = FALSE; e->cursor++; t->run_h = sp_enum_str((sp_Enumerator *)t->ext)->str_h; }
    return e->peek_val;
  }
  if (t->ext_done) { t->run_h = NULL; sp_raise_stop_iteration(e->source); }
  if (!t->ext) {
    SP_GC_ROOT(e);
    sp_Enumerator *w = sp_enum_walk_copy(e);
    sp_gc_wb((void *)e);
    t->ext = w;
    if (!w->str_bytewise) e->items = w->items;
    else t->run_h = sp_enum_str(w)->str_h;
  }
  sp_Enumerator *w = (sp_Enumerator *)t->ext;
  sp_RbVal v;
  if (!w->str_bytewise) {
    if (!e->items || e->cursor >= e->items->len) { t->ext_done = TRUE; sp_raise_stop_iteration(e->source); }
    v = e->items->data[e->cursor];
    if (!peek) e->cursor++;
    return v;
  }
  if (!sp_enum_str_byte_at(w, e->cursor, &v)) { t->ext_done = TRUE; t->run_h = NULL; sp_raise_stop_iteration(e->source); }
  if (peek) { sp_gc_wb((void *)e); e->peek_val = v; e->peeked = TRUE; t->run_h = NULL; }
  else e->cursor++;
  return v;
}
/* #next of a live Enumerator: a bytewise run's step is the byte at the
   cursor, read here, at the cost of a call from sp_Enumerator_next */
sp_RbVal sp_enum_live_next(sp_Enumerator *e) {
  sp_String *h = (sp_String *)sp_enum_str(e)->run_h;
  if (h && e->cursor < sp_String_length(h)) return sp_box_int((unsigned char)sp_String_cstr(h)[e->cursor++]);
  return sp_enum_live_step(e, FALSE);
}
/* #rewind of a live Enumerator: its run ends */
void sp_enum_live_rewind(sp_Enumerator *e) {
  sp_EnumStr *t = sp_enum_str(e);
  t->ext = NULL; t->ext_done = FALSE; e->peeked = FALSE; e->items = NULL; t->run_h = NULL;
}
/* #size of a live Enumerator: the String's count now, nil for each_line
   (sp_Enumerator_size returns earlier for it), as CRuby counts no lines
   without walking them */
sp_RbVal sp_enum_live_size(sp_Enumerator *e) {
  SP_GC_ROOT(e);
  sp_EnumStr *t = sp_enum_str(e);
  if (t->str_kind == SP_ENUM_STR_BYTE && t->str_h) return sp_box_int(sp_String_length((sp_String *)t->str_h));
  sp_enum_str_refill(e);
  return sp_box_int(e->walk_buf ? e->walk_buf->len : 0);
}
