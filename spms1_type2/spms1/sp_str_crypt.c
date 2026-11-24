/* sp_str_crypt.c -- String#crypt, through libc crypt(3).
 *
 * An object of its own in libspinel_rt.a, so only a program that calls
 * String#crypt pulls it in: in sp_str.o every program referenced crypt(),
 * and the link line's -lcrypt made libcrypt a dependency of hello world
 * (#6674). src/main.c adds -lcrypt only when the generated C calls
 * sp_str_crypt. */
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include "sp_str.h"
#include "sp_exc.h"
const char *sp_str_crypt(const char *s, const char *salt) {SP_GC_ROOT_STR(s);SP_GC_ROOT_STR(salt);
  /* the real libc crypt(3) -- DES with a 2-char salt (or the platform's
     extended schemes), byte-identical to CRuby's String#crypt (#2398).
     Declared by hand: glibc hides it behind crypt.h/_XOPEN_SOURCE while
     macOS ships it in unistd.h. */
  extern char *crypt(const char *key, const char *slt);
  if (!s) sp_nil_recv("crypt");
  if (!salt || !salt[0] || !salt[1])
    sp_raise_cls("ArgumentError", "salt too short (need >=2 bytes)");
  errno = 0;
  char *d = crypt(s, salt);
  /* a salt the platform's crypt(3) refuses: CRuby raises the errno it
     leaves ("Invalid argument - crypt"). OpenBSD's crypt returns NULL (it
     takes only bcrypt); libxcrypt's returns a failure token, "*0" or "*1",
     which no hash starts with */
  if (!d || d[0] == '*') {
    int e = errno ? errno : EINVAL;
    sp_raise_cls(sp_errno_class_name(e), sp_sprintf("%s - crypt", strerror(e)));
  }
  return sp_str_dup_external(d);
}
