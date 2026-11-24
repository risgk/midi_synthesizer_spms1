/* Opted-in compiler bridge. The retained recorder objects are linked again;
 * deterministic Init registrations bind the same zero-based function slots. */
#ifdef SP_CEXT
#include "sp_cext.h"
#include "sp_string.h"
#include <ruby/encoding.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <math.h>
#include "sp_setjmp.h"
void sp_exc_arm(jmp_buf);
void sp_exc_disarm(void);
const char *sp_exc_cur_cls(void);
const char *sp_exc_cur_msg(void);
void *sp_exc_cur_obj(void);
void sp_fiber_reraise(const char *, const char *, void *);
extern void (*sp_user_init_copy_hook_lib)(sp_RbVal, sp_RbVal);
VALUE rb_cObject, rb_cBasicObject, rb_cClass, rb_cModule;
VALUE rb_cString, rb_cArray, rb_cHash, rb_cInteger, rb_cFloat, rb_cIO;
sp_RbVal (*sp_cext_class_lookup_fn)(const char *);
void *(*sp_cext_object_alloc_fn)(int);
void *(*sp_cext_class_alloc_fn)(int);
static sp_cext_extension *binding;
static size_t next_function, next_constant;
/* Volatile journal fields survive longjmp; each nested Init owns only its
 * newly registered constant addresses, not the process-wide root registry. */
typedef struct { VALUE **addresses; size_t count; } InitRoots;
static volatile InitRoots *init_roots;
#define current_block ((sp_Proc *)sp_cext_current_block)

/* Ruby may yield or raise while the extension lock is suspended. Restore the
 * complete recursive depth before propagating either kind of nonlocal exit. */
static sp_RbVal call_ruby_unlocked(int kind, const char *key, sp_RbVal receiver,
                                 int argc, const sp_RbVal *args, sp_Proc *block,
                                 sp_int *raw) {
    unsigned depth = sp_cext_lock_suspend();
    const int roots = sp_gc_nroots;
    jmp_buf frame;
    if (setjmp(frame) != 0) {
        int unwind = sp_cext_unwinding();
        const char *cls = sp_exc_cur_cls(), *msg = sp_exc_cur_msg();
        void *obj = sp_exc_cur_obj();
        sp_exc_disarm(); sp_gc_nroots = roots;
        sp_cext_lock_resume(depth);
        if (unwind) sp_cext_resume_unwind();
        else sp_fiber_reraise(cls, msg, obj);
        abort();
    }
    sp_exc_arm(frame);
    sp_RbVal result;
    if (raw) {
        _sp_proc_poly_ret = sp_box_nil();
        sp_proc_call(block, argc, raw);
        result = _sp_proc_poly_ret;
    } else {
        result = sp_cext_dispatch_fn(kind, key, receiver, argc, args, block);
    }
    SP_GC_ROOT_RBVAL(result);
    sp_exc_disarm(); sp_cext_lock_resume(depth);
    return result;
}

static const char *class_name(VALUE v) {
    sp_RbVal r = sp_cext_rbval(v);
    if (r.tag != SP_TAG_CLASS) sp_raise_cls("TypeError", "class or module expected");
    if (r.cls_id == SP_CLASS_BY_NAME) return r.v.s;
    if (sp_obj_cls_name_fn) return sp_obj_cls_name_fn((int)r.v.i);
    sp_raise_cls("TypeError", "unknown C extension class");
}
VALUE rb_obj_class(VALUE object) {
    return sp_cext_value(sp_cext_object_class(sp_cext_rbval(object)));
}
const char *rb_class2name(VALUE klass) {
    sp_RbVal value=sp_cext_rbval(klass);
    /* CRuby skips singleton classes. A modeled class/module singleton's
     * real ancestor is Class/Module, not the attached object's class name. */
    if(value.tag==SP_TAG_CLASS && sp_sclass_id_p(value.cls_id)) {
        sp_Class attached={sp_sclass_base_id(value.cls_id),NULL};
        return sp_class_is_module_fn && sp_class_is_module_fn(attached) ? "Module" : "Class";
    }
    return class_name(klass);
}
static VALUE lookup(const char *name) {
    if (!sp_cext_class_lookup_fn) sp_raise_cls("RuntimeError", "C extension class hook is missing");
    return sp_cext_value(sp_cext_class_lookup_fn(name));
}
static VALUE define_under(VALUE outer, const char *name) {
    const char *parent = class_name(outer);
    if (!strcmp(parent, "Object")) return lookup(name);
    size_t len = strlen(parent) + strlen(name) + 3;
    char *full = malloc(len); if (!full) rb_raise(rb_eNoMemError, "class name allocation failed");
    snprintf(full, len, "%s::%s", parent, name);
    VALUE v = lookup(full); free(full); return v;
}
VALUE rb_define_class(const char *name, VALUE superclass) { (void)superclass; return lookup(name); }
VALUE rb_define_class_under(VALUE outer, const char *name, VALUE superclass) { (void)superclass; return define_under(outer,name); }
VALUE rb_define_module(const char *name) { return lookup(name); }
VALUE rb_define_module_under(VALUE outer, const char *name) { return define_under(outer,name); }
static void bind_function(VALUE (*fn)(ANYARGS)) {
    if (!binding || next_function >= binding->count)
        sp_raise_cls("RuntimeError", "C extension definitions outside Init are unsupported");
    binding->functions[next_function++] = fn;
}
void rb_define_method(VALUE owner,const char *name,VALUE (*fn)(ANYARGS),int arity) { (void)owner;(void)name;(void)arity;bind_function(fn); }
void rb_define_private_method(VALUE o,const char *n,VALUE (*f)(ANYARGS),int a) { rb_define_method(o,n,f,a); }
void rb_define_singleton_method(VALUE o,const char *n,VALUE (*f)(ANYARGS),int a) { rb_define_method(o,n,f,a); }
void rb_define_module_function(VALUE o,const char *n,VALUE (*f)(ANYARGS),int a) { rb_define_method(o,n,f,a);rb_define_method(o,n,f,a); }
void rb_define_alloc_func(VALUE o,VALUE (*fn)(VALUE)) { (void)o;bind_function((VALUE (*)(ANYARGS))fn); }
void rb_define_alias(VALUE o,const char *n,const char *old) { (void)o;(void)n;(void)old; }
void rb_define_attr(VALUE o,const char *n,int r,int w) { (void)o;(void)n;(void)r;(void)w; }
void rb_include_module(VALUE o,VALUE m) { (void)o;(void)m; }
void rb_extend_object(VALUE o,VALUE m) { (void)o;(void)m; }
void rb_define_const(VALUE o,const char *n,VALUE v) {
    (void)o;(void)n;
    if(!binding || next_constant>=binding->constant_count)sp_raise_cls("RuntimeError","C constant definitions outside Init are unsupported");
    binding->constants[next_constant]=v;
    VALUE *address=&binding->constants[next_constant++];
    if(sp_cext_register_address(address))init_roots->addresses[init_roots->count++]=address;
}
static void sp_cext_init_locked(sp_cext_extension *extension) {
    if (extension->initialized) return;
    sp_cext_exceptions_init();
#define BUILTIN(var,name) do { var=lookup(name);rb_gc_register_address(&var); } while(0)
    BUILTIN(rb_cBasicObject,"BasicObject");BUILTIN(rb_cObject,"Object");
    BUILTIN(rb_cClass,"Class");BUILTIN(rb_cModule,"Module");
    BUILTIN(rb_cString,"String");BUILTIN(rb_cArray,"Array");
    BUILTIN(rb_cHash,"Hash");BUILTIN(rb_cInteger,"Integer");
    BUILTIN(rb_cFloat,"Float");BUILTIN(rb_cIO,"IO");
#undef BUILTIN
    VALUE **addresses=extension->constant_count?malloc(extension->constant_count*sizeof(*addresses)):NULL;
    if(extension->constant_count && !addresses)rb_raise(rb_eNoMemError,"C extension Init root allocation failed");
    volatile InitRoots journal={addresses,0};
    volatile InitRoots *previous_roots=init_roots;
    sp_cext_arena_mark mark=sp_cext_arena_enter();
    sp_cext_extension *previous=binding;
    size_t previous_function=next_function, previous_constant=next_constant;
    int roots=sp_gc_nroots;
    jmp_buf frame;
    if(setjmp(frame)!=0) {
        int unwind=sp_cext_unwinding();
        const char *cls=sp_exc_cur_cls(), *msg=sp_exc_cur_msg();void *obj=sp_exc_cur_obj();
        sp_exc_disarm();
        for(size_t i=0;i<journal.count;i++) {
            rb_gc_unregister_address(addresses[i]);*addresses[i]=Qnil;
        }
        init_roots=previous_roots;free(addresses);binding=previous;
        next_function=previous_function;next_constant=previous_constant;
        sp_cext_arena_restore(mark);sp_gc_nroots=roots;
        if(unwind)sp_cext_resume_unwind();
        else sp_fiber_reraise(cls,msg,obj);
        abort();
    }
    sp_exc_arm(frame);
    init_roots=&journal;binding=extension;next_function=0;next_constant=0;extension->init();
    sp_exc_disarm();init_roots=previous_roots;free(addresses);binding=previous;
    next_function=previous_function;next_constant=previous_constant;
    extension->initialized=1;
    sp_cext_arena_restore(mark);
}
static sp_cext_data *data_object(VALUE object) {
    sp_RbVal r=sp_cext_rbval(object);
    if(r.tag!=SP_TAG_OBJ || r.cls_id<0 || !r.v.p || !sp_cext_data_class_fn || !sp_cext_data_class_fn(r.cls_id))
        rb_raise(rb_eTypeError,"expected TypedData object");
    return r.v.p;
}
VALUE rb_obj_alloc(VALUE klass) {
    if(!strcmp(class_name(klass),"Object"))return sp_cext_value(sp_cext_plain_object_new());
    sp_RbVal value=sp_cext_rbval(klass);
    if(value.tag==SP_TAG_CLASS && value.cls_id>=0 && sp_cext_data_class_fn && sp_cext_data_class_fn(value.cls_id))
        return sp_cext_value(sp_box_obj(sp_cext_class_alloc_fn(value.cls_id),value.cls_id));
    rb_raise(rb_eTypeError,"class has no C extension allocation hook");
}
VALUE rb_data_typed_object_wrap(VALUE klass,void *data,const rb_data_type_t *type) {
    sp_RbVal k=sp_cext_rbval(klass);
    if(k.tag!=SP_TAG_CLASS || k.cls_id==SP_CLASS_BY_NAME || !sp_cext_object_alloc_fn ||
       !sp_cext_data_class_fn || !sp_cext_data_class_fn((int)k.v.i)) rb_raise(rb_eTypeError,"class has no TypedData layout");
    void *ptr=sp_cext_object_alloc_fn((int)k.v.i);
    sp_cext_data *o=ptr; o->cext_data=data; o->cext_type=type;
    if(!(type->flags&RUBY_TYPED_WB_PROTECTED))sp_gc_pin_remembered(ptr);
    return sp_cext_value(sp_box_obj(ptr,(int)k.v.i));
}
void *rb_data_typed_object_zalloc(VALUE klass,size_t size,const rb_data_type_t *type,VALUE *value) {
    VALUE object=rb_data_typed_object_wrap(klass,NULL,type);
    void *data=calloc(1,size); if(!data)rb_raise(rb_eNoMemError,"TypedData allocation failed");
    data_object(object)->cext_data=data;
    *value=object;return data;
}
void *rb_check_typeddata(VALUE value,const rb_data_type_t *type) {
    sp_cext_data *o=data_object(value);
    if(!sp_cext_data_is_kind_of(o,type))rb_raise(rb_eTypeError,"wrong TypedData type");
    return o->cext_data;
}
void *sp_cext_data_ptr(VALUE value) { return data_object(value)->cext_data; }
const rb_data_type_t *sp_cext_data_type(VALUE value) { return data_object(value)->cext_type; }
static void *sp_cext_allocate_locked(sp_cext_extension *ext,int slot,int cls) {
    sp_cext_init(ext);sp_cext_arena_mark mark=sp_cext_arena_enter();
    sp_RbVal k={SP_TAG_CLASS,cls,{.i=cls}};
    VALUE obj=((VALUE (*)(VALUE))ext->functions[slot])(sp_cext_value(k));
    sp_RbVal r=sp_cext_rbval(obj);
    if(r.tag!=SP_TAG_OBJ || !r.v.p || r.cls_id!=cls)rb_raise(rb_eTypeError,"allocator returned the wrong class");
    void *ptr=r.v.p;sp_cext_arena_restore(mark);return ptr;
}
sp_RbVal sp_cext_duplicate(sp_RbVal value,int keep_frozen) {
    if(value.tag!=SP_TAG_OBJ || !value.v.p || value.cls_id<0 || !sp_cext_data_class_fn || !sp_cext_data_class_fn(value.cls_id))return value;
    value.cls_id=(int)((sp_cext_data *)value.v.p)->cls_id;
    SP_GC_ROOT_RBVAL(value);
    void *src=value.v.p;
    sp_gc_hdr *hdr=(sp_gc_hdr *)src-1;
    size_t size=hdr->size-sizeof(*hdr);
    void *ptr=sp_cext_class_alloc_fn(value.cls_id);SP_GC_ROOT(ptr);
    sp_cext_data *fresh=ptr;
    void *data=fresh->cext_data;const rb_data_type_t *type=fresh->cext_type;
    memcpy(ptr,src,size);fresh->cext_data=data;fresh->cext_type=type;
    sp_RbVal copy=value;copy.v.p=ptr;
    if(sp_user_init_copy_hook_lib)sp_user_init_copy_hook_lib(copy,value);
    if(keep_frozen && hdr->frozen)((sp_gc_hdr *)ptr-1)->frozen=1;
    return copy;
}
int rb_num2int(VALUE value) {
    sp_RbVal number=sp_cext_rbval(value);
    if(number.tag==SP_TAG_INT) {
        if(number.v.i<INT_MIN || number.v.i>INT_MAX)rb_raise(rb_eRangeError,"integer out of range of int");
        return (int)number.v.i;
    }
    if(number.tag==SP_TAG_FLT || number.tag==SP_TAG_BIGINT) {
        double converted=number.tag==SP_TAG_FLT ? number.v.f : sp_bigint_to_double(number.v.p);
        double integer=trunc(converted);
        if(!isfinite(integer) || integer<INT_MIN || integer>INT_MAX)rb_raise(rb_eRangeError,"number out of range of int");
        return (int)integer;
    }
    rb_raise(rb_eTypeError,"expected a numeric value");
}
void rb_check_type(VALUE value,int type) {
    sp_RbVal object=sp_cext_rbval(value);
    if(type==T_STRING && (object.tag==SP_TAG_STR || (object.tag==SP_TAG_OBJ && object.cls_id==SP_BUILTIN_STRBUF)))return;
    if(type==T_ARRAY && object.tag==SP_TAG_OBJ && object.cls_id==SP_BUILTIN_POLY_ARRAY)return;
    rb_raise(rb_eTypeError,"unexpected C extension argument type");
}
VALUE rb_ll2inum(long long number) { return sp_cext_value(sp_box_int(number)); }
VALUE rb_float_new(double number) { return sp_cext_value(sp_box_float(number)); }
VALUE rb_str_new(const char *s,long len) {
    if(len<0)rb_raise(rb_eArgError,"negative string size");
    if(len>INT64_MAX/2-64)rb_raise(rb_eArgError,"string size too large");
    sp_String *str=sp_String_new_len(s?s:"",s?len:0);SP_GC_ROOT(str);
    if(!s) {
        if(!sp_fd_grow(str,len))rb_raise(rb_eNoMemError,"string allocation failed");
        memset(str->data,0,(size_t)len);str->len=len;str->data[len]=0;
    }
    str->binary=1;sp_fd_publish(str);
    return sp_cext_value(sp_box_obj(str,SP_BUILTIN_STRBUF));
}
VALUE rb_str_new_cstr(const char *s) { return rb_str_new(s,(long)strlen(s)); }
void ruby_xfree(void *pointer) { free(pointer); }
void *sp_cext_allocv(VALUE *handle,size_t size,size_t count) {
    size_t alignment=_Alignof(max_align_t);
    if(size && count>((size_t)LONG_MAX-alignment)/size)rb_raise(rb_eArgError,"temporary allocation too large");
    /* The handle is pinned by the invocation arena even when C unwinds
     * through a Ruby exception before an explicit cleanup operation. */
    *handle=rb_str_new(NULL,(long)(size*count+alignment));
    uintptr_t pointer=(uintptr_t)RSTRING_PTR(*handle);
    return (void *)((pointer+alignment-1)/alignment*alignment);
}
struct sp_cext_encoding { int binary; };
static struct sp_cext_encoding ascii8bit={1};
rb_encoding *rb_ascii8bit_encoding(void) { return &ascii8bit; }
static sp_String *string(VALUE value) {
    sp_RbVal r=sp_cext_rbval(value);
    if(r.tag==SP_TAG_OBJ && r.cls_id==SP_BUILTIN_STRBUF)return r.v.p;
    if(r.tag==SP_TAG_STR && sp_str_is_frozen_val(r.v.s))sp_raise_frozen_str(r.v.s);
    rb_raise(rb_eTypeError,"expected a shared String");
}
VALUE rb_str_freeze(VALUE v) {
    sp_RbVal r=sp_cext_rbval(v);
    if(r.tag==SP_TAG_STR && sp_str_is_frozen_val(r.v.s))return v;
    sp_String_freeze(string(v));return v;
}
VALUE rb_utf8_str_new(const char *bytes,long length) {
    VALUE value=rb_str_new(bytes,length);
    sp_String_force_encoding(string(value),0);
    return value;
}
VALUE rb_enc_associate(VALUE value,rb_encoding *encoding) {
    if(encoding!=&ascii8bit)rb_raise(rb_eArgError,"unsupported C extension encoding");
    sp_String_force_encoding(string(value),1);
    return value;
}
extern sp_bool sp_str_valid_encoding(const char *);
int rb_enc_str_coderange(VALUE value) {
    const char *bytes=RSTRING_PTR(value);
    if(sp_str_ascii_only(bytes))return ENC_CODERANGE_7BIT;
    return sp_str_valid_encoding(bytes) ? ENC_CODERANGE_VALID : ENC_CODERANGE_BROKEN;
}
char *sp_cext_string_cstr(VALUE value) {
    char *bytes=RSTRING_PTR(value);
    if(memchr(bytes,0,(size_t)RSTRING_LEN(value)))rb_raise(rb_eArgError,"string contains null byte");
    return bytes;
}
char *sp_cext_string_ptr(VALUE v) {
    sp_RbVal r=sp_cext_rbval(v);if(r.tag==SP_TAG_STR)return (char *)r.v.s;
    return string(v)->data;
}
long sp_cext_string_len(VALUE v) {
    sp_RbVal r=sp_cext_rbval(v);if(r.tag==SP_TAG_STR)return (long)sp_str_byte_len(r.v.s);
    return (long)string(v)->len;
}
VALUE rb_str_cat(VALUE v,const char *s,long len) { if(len<0)rb_raise(rb_eArgError,"negative string size");sp_String_append_n(string(v),s,(size_t)len);return v; }
VALUE rb_str_cat_cstr(VALUE v,const char *s) { return rb_str_cat(v,s,(long)strlen(s)); }
static sp_PolyArray *array(VALUE value) {
    sp_RbVal r=sp_cext_rbval(value);
    if(r.tag==SP_TAG_OBJ && r.cls_id==SP_BUILTIN_POLY_ARRAY)return r.v.p;
    rb_raise(rb_eTypeError,"expected a widened Array");
}
sp_PolyArray *sp_cext_share_new_array(sp_PolyArray *array) {
    SP_GC_ROOT(array);
    if(!array)return array;
    for(sp_int i=0;i<array->len;i++) {
        sp_RbVal value=array->data[i];
        if(value.tag==SP_TAG_STR && value.v.s && !sp_str_is_frozen_val(value.v.s)) {
            sp_RbVal shared=value;
            if(((const unsigned char *)value.v.s)[-1]==0xfd) {
                sp_String *owner=(sp_String *)(void *)((sp_str_hdr *)sp_fd_base(value.v.s))->next;
                if(owner && owner->data==value.v.s)shared=sp_box_obj(owner,SP_BUILTIN_STRBUF);
            }
            if(shared.tag==SP_TAG_STR)shared=sp_box_obj(sp_String_new_shared(value.v.s),SP_BUILTIN_STRBUF);
            sp_gc_wb(array);array->data[i]=shared;
        }
    }
    return array;
}
VALUE rb_ary_new(void) { return sp_cext_value(sp_box_poly_array(sp_PolyArray_new())); }
VALUE rb_hash_new(void) { return sp_cext_value(sp_cext_hash_new()); }
VALUE rb_hash_new_capa(long capacity) {
    if(capacity<0)rb_raise(rb_eArgError,"negative hash size");
    return rb_hash_new();
}
VALUE rb_hash_aset(VALUE hash,VALUE key,VALUE value) {
    sp_cext_hash_set(sp_cext_rbval(hash),sp_cext_rbval(key),sp_cext_rbval(value));
    return value;
}
VALUE rb_ary_new_capa(long capacity) {
    if(capacity<0)rb_raise(rb_eArgError,"negative array size");
    /* Capacity is a reservation hint; the array remains empty. */
    return rb_ary_new();
}
VALUE rb_ary_push(VALUE v,VALUE item) { sp_PolyArray_push(array(v),sp_cext_rbval(item));return v; }
VALUE rb_ary_pop(VALUE v) {
    sp_PolyArray *a=array(v);
    if(a->frozen)sp_raise_frozen_array_at(a,SP_BUILTIN_POLY_ARRAY);
    return a->len ? sp_cext_value(a->data[--a->len]) : Qnil;
}
void rb_ary_store(VALUE v,long index,VALUE item) {
    sp_PolyArray *a=array(v);
    if(a->frozen)sp_raise_frozen_array_at(a,SP_BUILTIN_POLY_ARRAY);
    if(index<0)index+=a->len;
    if(index<0)sp_raise_cls("IndexError","array index too small");
    sp_RbVal value=sp_cext_rbval(item);
    while(a->len<index)sp_PolyArray_push(a,sp_box_nil());
    if(index==a->len)sp_PolyArray_push(a,value);
    else { sp_gc_wb(a);a->data[index]=value; }
}
VALUE rb_ary_entry(VALUE v,long i) { sp_PolyArray *a=array(v);if(i<0)i+=a->len;return i<0||i>=a->len?Qnil:sp_cext_value(a->data[i]); }
long sp_cext_array_len(VALUE v) { return (long)array(v)->len; }
ID rb_intern(const char *name) {
    if(!sp_json_sym_intern_fn)sp_raise_cls("RuntimeError","C extension symbol hook is missing");
    return (ID)sp_json_sym_intern_fn(name);
}
const char *rb_id2name(ID id) { return sp_sym_name_fn?sp_sym_name_fn((sp_sym)id):NULL; }
void rb_gc_start(void) { sp_gc_collect(); }
int rb_block_given_p(void) { return current_block!=NULL; }
VALUE rb_block_proc(void) {
    if(!current_block)rb_raise(rb_eArgError,"tried to create Proc object without a block");
    return sp_cext_value(sp_box_obj(current_block,SP_BUILTIN_PROC));
}
VALUE rb_yield_values2(int argc,const VALUE *argv) {
    if(!current_block)sp_raise_cls("LocalJumpError","no block given");
    if(argc<0 || argc>SP_PROC_ARG_SLOTS)rb_raise(rb_eArgError,"too many block arguments");
    sp_int raw[SP_PROC_ARG_SLOTS];
    for(int i=0;i<argc;i++) {
        sp_RbVal v=sp_cext_rbval(argv[i]);_sp_proc_poly_args[i]=v;
        raw[i]=v.v.i;
    }
    return sp_cext_value(call_ruby_unlocked(0,NULL,sp_box_nil(),argc,NULL,current_block,raw));
}
VALUE rb_yield(VALUE v) { return rb_yield_values2(1,&v); }
VALUE rb_yield_values(int argc,...) {
    if(argc<0 || argc>SP_PROC_ARG_SLOTS)rb_raise(rb_eArgError,"too many block arguments");
    VALUE values[SP_PROC_ARG_SLOTS];va_list args;va_start(args,argc);
    for(int i=0;i<argc;i++)values[i]=va_arg(args,VALUE);va_end(args);
    return rb_yield_values2(argc,values);
}
static sp_RbVal sp_cext_invoke_locked(sp_cext_extension *ext,int slot,int arity,sp_RbVal self,sp_PolyArray *args,sp_Proc *block) {
    sp_cext_init(ext);
    SP_GC_ROOT_RBVAL(self);SP_GC_ROOT(args);SP_GC_ROOT(block);
    sp_cext_arena_mark mark=sp_cext_arena_enter();
    int argc=args?(int)args->len:0;
    VALUE *argv=argc?sp_gc_alloc((size_t)argc*sizeof(VALUE),NULL,NULL):NULL;
    SP_GC_ROOT(argv);
    if(argc&&!argv)rb_raise(rb_eNoMemError,"C argument allocation failed");
    for(int i=0;i<argc;i++)argv[i]=sp_cext_value(args->data[i]);
    VALUE recv=sp_cext_value(self), result=Qnil;
    VALUE (*fn)(ANYARGS)=ext->functions[slot];
    sp_Proc *saved=current_block;sp_cext_current_block=block;
    const int roots=sp_gc_nroots;
    jmp_buf frame;
    if(setjmp(frame)!=0) {
        if(sp_cext_unwinding()) {
            sp_exc_disarm();sp_cext_arena_restore(mark);sp_gc_nroots=roots;
            sp_cext_current_block=saved;sp_cext_resume_unwind();abort();
        }
        const char *cls=sp_exc_cur_cls(), *msg=sp_exc_cur_msg();void *obj=sp_exc_cur_obj();
        sp_exc_disarm();sp_cext_arena_restore(mark);sp_gc_nroots=roots;
        sp_cext_current_block=saved;sp_fiber_reraise(cls,msg,obj);abort();
    }
    sp_exc_arm(frame);
    if(arity>=0 && argc!=arity) { rb_raise(rb_eArgError,"wrong number of arguments (given %d, expected %d)",argc,arity); }
    if(arity==-1)result=((VALUE (*)(int,VALUE *,VALUE))fn)(argc,argv,recv);
    else if(arity==-2)result=((VALUE (*)(VALUE,VALUE))fn)(recv,sp_cext_value(sp_box_poly_array(args)));
    else switch(arity) {
    case 0: result=((VALUE (*)(VALUE))fn)(recv);break;
    case 1: result=((VALUE (*)(VALUE, VALUE))fn)(recv, argv[0]);break;
    case 2: result=((VALUE (*)(VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1]);break;
    case 3: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2]);break;
    case 4: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3]);break;
    case 5: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3], argv[4]);break;
    case 6: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);break;
    case 7: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);break;
    case 8: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);break;
    case 9: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8]);break;
    case 10: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9]);break;
    case 11: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10]);break;
    case 12: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11]);break;
    case 13: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11], argv[12]);break;
    case 14: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11], argv[12], argv[13]);break;
    case 15: result=((VALUE (*)(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE))fn)(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11], argv[12], argv[13], argv[14]);break;
    default: rb_raise(rb_eArgError,"unsupported C method arity");
    }
    sp_exc_disarm();sp_cext_current_block=saved;
    sp_RbVal value=sp_cext_rbval(result);
    sp_cext_arena_restore(mark);return value;
}
#endif

#ifdef SP_CEXT
sp_RbVal (*sp_cext_dispatch_fn)(int, const char *, sp_RbVal, int, const sp_RbVal *, sp_Proc *);
static VALUE dispatch(int kind, const char *key, VALUE receiver, int argc, const VALUE *args, sp_Proc *block) {
    if (!key) rb_raise(rb_eArgError, "unknown C extension dispatch name");
    if (!sp_cext_dispatch_fn) rb_raise(rb_eRuntimeError, "C extension dispatch hook is missing");
    if (argc < 0) rb_raise(rb_eArgError, "negative C extension call arity");
    if (argc && !args) rb_raise(rb_eArgError, "missing C extension arguments");
    sp_PolyArray *boxed = sp_PolyArray_new(); SP_GC_ROOT(boxed); SP_GC_ROOT(block);
    for (int i = 0; i < argc; i++) sp_PolyArray_push(boxed, sp_cext_rbval(args[i]));
    return sp_cext_value(call_ruby_unlocked(kind, key, sp_cext_rbval(receiver), argc, boxed->data, block, NULL));
}
VALUE rb_funcallv(VALUE receiver, ID id, int argc, const VALUE *args) {
    const char *name = rb_id2name(id);
    if (!name) rb_raise(rb_eArgError, "unknown method ID");
    return dispatch(0, name, receiver, argc, args, NULL);
}
VALUE rb_funcall(VALUE receiver, ID id, int argc, ...) {
    if (argc < 0) rb_raise(rb_eArgError, "negative C extension call arity");
    VALUE *args = argc ? sp_gc_alloc((size_t)argc * sizeof(VALUE), NULL, NULL) : NULL;
    SP_GC_ROOT(args); va_list ap; va_start(ap, argc);
    for (int i = 0; i < argc; i++) args[i] = va_arg(ap, VALUE);
    va_end(ap); return rb_funcallv(receiver, id, argc, args);
}
VALUE rb_iv_get(VALUE receiver, const char *name) { return dispatch(1, name, receiver, 0, NULL, NULL); }
VALUE rb_iv_set(VALUE receiver, const char *name, VALUE value) { return dispatch(2, name, receiver, 1, &value, NULL); }
VALUE rb_ivar_get(VALUE receiver, ID id) { return rb_iv_get(receiver, rb_id2name(id)); }
VALUE rb_ivar_set(VALUE receiver, ID id, VALUE value) { return rb_iv_set(receiver, rb_id2name(id), value); }
VALUE rb_const_get(VALUE receiver, ID id) { (void)class_name(receiver); return dispatch(3, rb_id2name(id), receiver, 0, NULL, NULL); }
VALUE rb_eval_string(const char *code) { return dispatch(4, code, Qnil, 0, NULL, NULL); }
ID rb_intern2(const char *s, long len) {
    if (len < 0) rb_raise(rb_eArgError, "negative symbol length");
    char *name = malloc((size_t)len + 1);
    if (!name) rb_raise(rb_eNoMemError, "symbol allocation failed");
    memcpy(name, s, (size_t)len); name[len] = 0;
    ID id = rb_intern(name); free(name); return id;
}
#endif

#ifdef SP_CEXT
typedef struct {
    rb_block_call_func_t callback;
    sp_RbVal data;
    sp_Proc *outer;
} CextCallback;
static void callback_scan(void *p) {
    sp_gc_mark(p);
    CextCallback *cap = p;
    sp_mark_rbval(cap->data);
    sp_gc_mark(cap->outer);
}
static sp_int callback_trampoline_locked(void *p, sp_int argc, sp_int *raw) {
    (void)raw;
    CextCallback *cap = p;
    SP_GC_ROOT(cap);
    if (argc < 0 || argc > SP_PROC_ARG_SLOTS) rb_raise(rb_eArgError, "too many callback arguments");
    sp_cext_arena_mark mark = sp_cext_arena_enter();
    sp_Proc *saved = current_block;
    sp_cext_current_block = cap->outer;
    const int roots = sp_gc_nroots;
    jmp_buf frame;
    if (setjmp(frame) != 0) {
        int unwind = sp_cext_unwinding();
        const char *cls = sp_exc_cur_cls(), *msg = sp_exc_cur_msg();
        void *obj = sp_exc_cur_obj();
        sp_exc_disarm(); sp_cext_arena_restore(mark); sp_gc_nroots = roots;
        sp_cext_current_block = saved;
        if (unwind) { sp_cext_resume_unwind(); abort(); }
        sp_fiber_reraise(cls, msg, obj); abort();
    }
    sp_exc_arm(frame);
    VALUE argv[SP_PROC_ARG_SLOTS];
    for (int i = 0; i < argc; i++) argv[i] = sp_cext_value(_sp_proc_poly_args[i]);
    VALUE yielded = argc ? argv[0] : Qnil;
    VALUE result = cap->callback(yielded, sp_cext_value(cap->data), (int)argc, argv, Qnil);
    sp_RbVal boxed = sp_cext_rbval(result);
    sp_exc_disarm(); sp_cext_arena_restore(mark); sp_cext_current_block = saved;
    _sp_proc_poly_ret = boxed;
    return boxed.v.i;
}
static sp_int callback_trampoline(void *p, sp_int argc, sp_int *raw) {
    SP_GC_ROOT(p);
    sp_cext_lock();
    const int roots = sp_gc_nroots;
    jmp_buf frame;
    if (setjmp(frame) != 0) {
        int unwind = sp_cext_unwinding();
        const char *cls = sp_exc_cur_cls(), *msg = sp_exc_cur_msg();
        void *obj = sp_exc_cur_obj();
        sp_exc_disarm(); sp_gc_nroots = roots; sp_cext_unlock();
        if (unwind) sp_cext_resume_unwind();
        else sp_fiber_reraise(cls, msg, obj);
        abort();
    }
    sp_exc_arm(frame);
    sp_int result = callback_trampoline_locked(p, argc, raw);
    sp_exc_disarm(); sp_cext_unlock();
    return result;
}
VALUE rb_block_call(VALUE receiver, ID id, int argc, const VALUE *argv, rb_block_call_func_t fn, VALUE data) {
    if (!fn) return rb_funcallv(receiver, id, argc, argv);
    CextCallback *cap = sp_gc_alloc(sizeof(*cap), NULL, callback_scan);
    SP_GC_ROOT(cap);
    cap->callback = fn; cap->data = sp_cext_rbval(data); cap->outer = current_block;
    sp_Proc *block = sp_proc_new_meta((void *)callback_trampoline, cap, callback_scan, -1, FALSE, 0, NULL, NULL);
    SP_GC_ROOT(block);
    return dispatch(0, rb_id2name(id), receiver, argc, argv, block);
}
#endif

#ifdef SP_CEXT
VALUE rb_str_intern(VALUE v) { return ID2SYM(rb_intern2(RSTRING_PTR(v), RSTRING_LEN(v))); }
#endif

#ifdef SP_CEXT
void sp_cext_init(sp_cext_extension *extension) {
    sp_cext_lock();
    const int roots = sp_gc_nroots;
    jmp_buf frame;
    if (setjmp(frame) != 0) {
        int unwind = sp_cext_unwinding();
        const char *cls = sp_exc_cur_cls(), *msg = sp_exc_cur_msg();
        void *obj = sp_exc_cur_obj();
        sp_exc_disarm(); sp_gc_nroots = roots; sp_cext_unlock();
        if (unwind) sp_cext_resume_unwind();
        else sp_fiber_reraise(cls, msg, obj);
        abort();
    }
    sp_exc_arm(frame);
    sp_cext_init_locked(extension);
    sp_exc_disarm(); sp_cext_unlock();
    return;
}
#endif

#ifdef SP_CEXT
void *sp_cext_allocate(sp_cext_extension *ext,int slot,int cls) {
    sp_cext_lock();
    const int roots = sp_gc_nroots;
    jmp_buf frame;
    if (setjmp(frame) != 0) {
        int unwind = sp_cext_unwinding();
        const char *cls = sp_exc_cur_cls(), *msg = sp_exc_cur_msg();
        void *obj = sp_exc_cur_obj();
        sp_exc_disarm(); sp_gc_nroots = roots; sp_cext_unlock();
        if (unwind) sp_cext_resume_unwind();
        else sp_fiber_reraise(cls, msg, obj);
        abort();
    }
    sp_exc_arm(frame);
    void * result = sp_cext_allocate_locked(ext,slot,cls);
    sp_exc_disarm(); sp_cext_unlock();
    return result;
}
#endif

#ifdef SP_CEXT
sp_RbVal sp_cext_invoke(sp_cext_extension *ext,int slot,int arity,sp_RbVal self,sp_PolyArray *args,sp_Proc *block) {
    SP_GC_ROOT_RBVAL(self); SP_GC_ROOT(args); SP_GC_ROOT(block);
    sp_cext_lock();
    const int roots = sp_gc_nroots;
    jmp_buf frame;
    if (setjmp(frame) != 0) {
        int unwind = sp_cext_unwinding();
        const char *cls = sp_exc_cur_cls(), *msg = sp_exc_cur_msg();
        void *obj = sp_exc_cur_obj();
        sp_exc_disarm(); sp_gc_nroots = roots; sp_cext_unlock();
        if (unwind) sp_cext_resume_unwind();
        else sp_fiber_reraise(cls, msg, obj);
        abort();
    }
    sp_exc_arm(frame);
    sp_RbVal result = sp_cext_invoke_locked(ext,slot,arity,self,args,block);
    sp_exc_disarm(); sp_cext_unlock();
    return result;
}
#endif
