/* sp_enum.h -- the Enumerator handle (cursor/generator ops in lib/sp_cold.c).
 *
 * Two flavors: a materialized snapshot (items + cursor, from a collection's
 * blockless #each) or a fiber-backed generator (Enumerator.new { |y| ... },
 * where `y << v` is a Fiber.yield). The fiber is created lazily on first
 * #next and re-created on #rewind. */
#ifndef SP_ENUM_H
#define SP_ENUM_H

#include "sp_alloc.h"
#include "sp_fiber.h"
#include "sp_string.h"

#define SP_PAIR_EACH   1
#define SP_PAIR_PACKED 2

/* The Array a generator step that yields several values packs them in: an
   ordinary poly array, told apart by its scan function so a generator that
   also yields single values (an Array among them) keeps each step's arity. */
void sp_PolyArray_pack_scan(void *p);
sp_PolyArray *sp_PolyArray_new_pack(void);
static inline sp_bool sp_poly_is_pack(sp_RbVal v) {
  return v.tag == SP_TAG_OBJ && v.cls_id == SP_BUILTIN_POLY_ARRAY && v.v.p &&
         ((sp_gc_hdr *)((char *)v.v.p - sizeof(sp_gc_hdr)))->scan == sp_PolyArray_pack_scan;
}

/* A generator step that yields no value (`y.yield`, `y.yield(*[])`): nil to a
   reader of the item, and no values to a `|*r|` block. The mark rides in the
   nil's cls_id, which nothing else reads. */
static inline sp_RbVal sp_box_empty_step(void) {
  sp_RbVal r = sp_box_nil(); r.cls_id = 1; return r;
}
static inline sp_bool sp_poly_is_empty_step(sp_RbVal v) {
  return v.tag == SP_TAG_NIL && v.cls_id == 1;
}

typedef struct {
  sp_PolyArray *items; sp_int cursor;   /* materialized mode (items != NULL) */
  void (*gen)(sp_Fiber *);                /* generator body (fiber mode, gen != NULL) */
  void *gen_cap;                          /* captures, passed via fiber user_data */
  sp_Fiber *fib;                          /* current generator fiber (lazy) */
  sp_bool peeked; sp_RbVal peek_val;     /* #peek lookahead cache */
  sp_RbVal size;                          /* #size for a generator: a value, a
                                             callable (Proc), or nil. Unused by
                                             the materialized path (items->len). */
  sp_RbVal feed; sp_bool has_feed;       /* #feed: value returned by the next Fiber.yield */
  sp_RbVal gen_result;                    /* generator body's return -> StopIteration#result */
  sp_RbVal source;                        /* the iterated receiver -> materialized StopIteration#result */
  sp_bool has_src;                       /* source is set, even to nil: `nil.then`'s receiver IS
                                             nil, and #inspect must not read that as "no source"
                                             and fall back to the items (sp_gc_alloc zero-fills) */
  const char *meth;                       /* creating method name, for #inspect ("each", ...):
                                             an SPL literal or a GC-traced heap label */
  sp_bool gen_label;                     /* #inspect as a Generator wrapper (chunk_while & co.):
                                             the items are an eager snapshot, but CRuby shows
                                             #<Enumerator: #<Enumerator::Generator:0x..>:each> */
  sp_bool frozen;                        /* Object#freeze observed (sp_gc_alloc zero-fills) */
  sp_bool is_chain;                      /* built by Enumerable#chain / Enumerator#+: the items
                                             are the concatenated sources, and #class reports
                                             Enumerator::Chain (sp_gc_alloc zero-fills) */
  sp_bool is_product;                    /* built by Enumerator.product / Enumerator::Product.new:
                                             the items are the tuples, `source` the factors, and
                                             #class reports Enumerator::Product (zero-filled) */
  sp_bool size_nil;                      /* #size is nil, whatever the items: the source is a String
                                             Range (a Range of Strings counts no members without
                                             walking them), and what is built on such an
                                             Enumerator inherits it (sp_gc_alloc zero-fills) */
  sp_bool endless;                       /* an argless #cycle: the items are one round, and
                                             #next / #peek start over at their end, so the
                                             enumerator never stops (sp_gc_alloc zero-fills) */
  sp_bool is_bsearch;                    /* Array#bsearch enum_for: items are candidates,
                                             with the block result steering the search */
  sp_int bsearch_lo, bsearch_hi, bsearch_mid;
  sp_bool bsearch_waiting;
  sp_RbVal bsearch_result;
  unsigned char yields_pair;             /* SP_PAIR_EACH: each item is the two values one step
                                             yields (each_with_index, with_index,
                                             each_with_object, with_object) packed as an Array,
                                             which a block of map and its kin takes spread;
                                             SP_PAIR_PACKED: only the items packed by a
                                             generator step that yielded several values
                                             (sp_PolyArray_new_pack) are (sp_gc_alloc
                                             zero-fills) */
  sp_PolyArray *walk_buf;                /* a walker (sp_enum_walker_boxed): the items pulled
                                             so far by an index walk over a generator or
                                             endless source, one at a time; NULL otherwise */
  sp_int walk_next;                      /* the walk's next index: how far it has read */
  sp_bool walk_done;                     /* the source has no more items */
  /* (the three below sit in the padding after walk_done: an Enumerator no
     String backs is no larger than before them) */
  sp_bool live;                          /* --share-strings: an sp_EnumStr whose items are laid
                                            out at each walk's start (over a String handle, or
                                            built on such an Enumerator), and each walk reads a
                                            copy of its own holding them as `items`
                                            (sp_enum_walk). Its own `items` is its #next run's
                                            (the run's copy's), NULL before the run or for a
                                            bytewise one, so the materialized #next and #peek
                                            read the run's items and fall to the live path
                                            (sp_enum_live_step) at their end or without them.
                                            The items its last walk laid out are its walk_buf,
                                            as a walker's that pulled them all (walk_done), so
                                            an index walk (sp_enum_walk_len) reads them */
  sp_bool str_bytewise;                  /* ...a walk reads the byte at its cursor: each_byte, and
                                            each_codepoint over bytes that were ASCII when laid
                                            out, which CRuby walks as bytes */
  sp_bool str_tail;                      /* allocated as an sp_EnumStr: a live one, or a walk
                                            copy of one */
} sp_Enumerator;

/* An Enumerator a String handle backs, or one built on it, or a walk copy of
   either: the Enumerator, then the fields only they use, which no other
   Enumerator allocates, zeroes or marks (sp_EnumStr_scan) */
typedef struct {
  sp_Enumerator e;
  void *str_h;                           /* the String handle (sp_String *) the items are laid
                                            out from at each walk's start; NULL for one built on
                                            another */
  unsigned char str_kind;                /* ...which iterator: SP_ENUM_STR_* */
  const char *str_snap;                  /* ...the bytes the items were laid out from */
  void *der_src;                         /* one built on another (with_index, each_slice,
                                            each_cons) by sp_enum_derive: that source
                                            (sp_Enumerator *), whose items its own are laid out
                                            from again at each walk's start; NULL otherwise */
  sp_PolyArray *der_from;                /* ...the source items they were laid out from */
  sp_int der_arg;                        /* ...the offset or the group size */
  unsigned char der_kind;                /* ...SP_ENUM_DER_* */
  void *ext;                             /* the walk copy of its #next run (sp_Enumerator *),
                                            from the first step to #rewind; NULL before it */
  sp_bool ext_done;                      /* ...that walk raised StopIteration */
  void *run_h;                           /* the String handle (sp_String *) a bytewise run's next
                                            #next reads its byte from: set while the run steps,
                                            NULL before it, after a #peek it has not taken and at
                                            its end */
} sp_EnumStr;
/* e's fields past the Enumerator's: e->str_tail is set */
static inline sp_EnumStr *sp_enum_str(sp_Enumerator *e) {
  return (sp_EnumStr *)e;
}

enum { SP_ENUM_STR_CHAR, SP_ENUM_STR_LINE, SP_ENUM_STR_BYTE, SP_ENUM_STR_CODEPOINT };
enum { SP_ENUM_DER_PAIRS, SP_ENUM_DER_SLICES, SP_ENUM_DER_CONS };
/* The items of an Enumerator over a String handle, or of one built on such
   an Enumerator, laid out again from the String as it is now
   (lib/sp_cold.c) */
void sp_enum_str_refill(sp_Enumerator *e);
/* Is e an Enumerator whose items are laid out at each walk's start? */
static inline sp_bool sp_enum_live(const sp_Enumerator *e) {
  return e && e->live;
}
/* The Enumerator a walk of e reads, from where it starts: e itself, or for
   a live one a copy holding the items laid out from the String as it is
   now, which a walk nested in this one (a #size, a #to_a, another walk)
   laying them out again leaves as they are (lib/sp_cold.c). */
sp_Enumerator *sp_enum_walk_copy(sp_Enumerator *e);
static inline sp_Enumerator *sp_enum_walk(sp_Enumerator *e) {
  return SP_UNLIKELY(sp_enum_live(e)) ? sp_enum_walk_copy(e) : e;
}
/* ...the byte at index i of a bytewise walk's String as it is now */
static inline sp_bool sp_enum_str_byte_at(sp_Enumerator *w, sp_int i, sp_RbVal *out) {
  sp_String *h = (sp_String *)sp_enum_str(w)->str_h;
  if (!h || i >= sp_String_length(h)) return FALSE;
  *out = sp_box_int((unsigned char)sp_String_cstr(h)[i]);
  return TRUE;
}
/* A copy of e (e->str_tail), its fields past the Enumerator's included
   (lib/sp_enum_str.c) */
sp_Enumerator *sp_enum_str_dup(sp_Enumerator *e);
/* #next (peek: #peek) of a live Enumerator from the materialized paths, at
   the end of its run's items or without them; #next with a bytewise run's
   step first; its #rewind; its #size (lib/sp_enum_str.c) */
sp_RbVal sp_enum_live_step(sp_Enumerator *e, sp_bool peek);
sp_RbVal sp_enum_live_next(sp_Enumerator *e);
void sp_enum_live_rewind(sp_Enumerator *e);
sp_RbVal sp_enum_live_size(sp_Enumerator *e);
/* An Enumerator built on e (live: sp_enum_live) by with_index(arg)
   (SP_ENUM_DER_PAIRS), each_slice(arg) or each_cons(arg) (lib/sp_cold.c) */
sp_Enumerator *sp_enum_derive(sp_Enumerator *e, unsigned char kind, sp_int arg);

/* A blockless call on a String Range's member Array stands for the Range's own
   (desugar_str_range_methods); the Enumerator it answers has no size. */
static inline sp_Enumerator *sp_enum_size_nil(sp_Enumerator *e) {
  if (e) e->size_nil = TRUE;
  return e;
}

/* An Enumerator built on `e` (with_index, each_slice, cycle, ...) has the size
   its source has: unknown, when the source's is. */
static inline sp_Enumerator *sp_enum_inherit_size(sp_Enumerator *r, const sp_Enumerator *e) {
  if (e && e->size_nil) r->size_nil = TRUE;
  return r;
}

#endif
