#ifndef SP_IO_H
#define SP_IO_H

typedef struct { void *fp; const char *path; const char *mode; mrb_int lineno; } sp_File;

typedef struct { void *dp; const char *path; } sp_Dir;

#endif
