/* C extension serialization. Waiting for the lock is a blocking native
 * operation: a collector must not wait for a worker sleeping on this mutex. */
#ifdef SP_CEXT
#include "sp_cext.h"
#include "sp_sched.h"
#include <ruby/thread.h>
#include <stdlib.h>
#include <string.h>
#include <poll.h>
#include <errno.h>
#include <time.h>
void rb_fd_init(rb_fdset_t *set) { set->bits=NULL;set->capacity=0; }
void rb_fd_term(rb_fdset_t *set) { free(set->bits);rb_fd_init(set); }
void rb_fd_set(int fd,rb_fdset_t *set) {
    if(fd<0)rb_raise(rb_eArgError,"negative file descriptor");
    size_t needed=(size_t)fd/8+1;
    if(needed>set->capacity) {
        unsigned char *bits=realloc(set->bits,needed);
        if(!bits)rb_raise(rb_eNoMemError,"file descriptor set allocation failed");
        memset(bits+set->capacity,0,needed-set->capacity);
        set->bits=bits;set->capacity=needed;
    }
    set->bits[fd/8]|=(unsigned char)(1u<<(fd%8));
}
int rb_fd_isset(int fd,const rb_fdset_t *set) {
    return fd>=0 && (size_t)fd/8<set->capacity && (set->bits[fd/8]&(1u<<(fd%8)))!=0;
}
typedef struct { struct pollfd *fds; nfds_t count; int canceled,result,error; double deadline; } sp_cext_select;
static double select_now(void) {
    struct timespec now;clock_gettime(CLOCK_MONOTONIC,&now);
    return (double)now.tv_sec+(double)now.tv_nsec/1000000000.0;
}
static void select_unblock(void *pointer) {
    sp_cext_select *args=pointer;
    __atomic_store_n(&args->canceled,1,__ATOMIC_RELEASE);
}
static void *select_native(void *pointer) {
    sp_cext_select *args=pointer;
    for(;;) {
        if(__atomic_load_n(&args->canceled,__ATOMIC_ACQUIRE)) { args->result=-1;args->error=EINTR;break; }
        int timeout=50;
        if(args->deadline>=0) {
            double remaining=(args->deadline-select_now())*1000;
            if(remaining<=0)timeout=0;
            else if(remaining<50)timeout=(int)remaining+1;
        }
        args->result=poll(args->fds,args->count,timeout);
        if(args->result<0) { if(errno==EINTR)continue;args->error=errno;break; }
        if(args->result || (args->deadline>=0 && select_now()>=args->deadline))break;
    }
    return NULL;
}
int rb_thread_fd_select(int max,rb_fdset_t *read,rb_fdset_t *write,rb_fdset_t *except,struct timeval *timeout) {
    if(max<0 || (timeout && (timeout->tv_sec<0 || timeout->tv_usec<0 || timeout->tv_usec>=1000000))) { errno=EINVAL;return -1; }
    VALUE handle;
    struct pollfd *fds=sp_cext_allocv(&handle,sizeof(*fds),(size_t)max);
    sp_cext_select args={.fds=fds,.deadline=timeout ? select_now()+timeout->tv_sec+timeout->tv_usec/1000000.0 : -1};
    for(int fd=0;fd<max;fd++) {
        short events=0;
        if(read && rb_fd_isset(fd,read))events|=POLLIN;
        if(write && rb_fd_isset(fd,write))events|=POLLOUT;
        if(except && rb_fd_isset(fd,except))events|=POLLPRI;
        if(events)fds[args.count++]=(struct pollfd){.fd=fd,.events=events};
    }
    rb_thread_call_without_gvl(select_native,&args,select_unblock,&args);
    if(args.result<0) { errno=args.error;return -1; }
    for(nfds_t i=0;i<args.count;i++)if(fds[i].revents&POLLNVAL) { errno=EBADF;return -1; }
    if(read && read->bits)memset(read->bits,0,read->capacity);
    if(write && write->bits)memset(write->bits,0,write->capacity);
    if(except && except->bits)memset(except->bits,0,except->capacity);
    int result=0;
    for(nfds_t i=0;i<args.count;i++) {
        struct pollfd entry=fds[i];
        if(read && (entry.events&POLLIN) && (entry.revents&(POLLIN|POLLHUP|POLLERR))) { rb_fd_set(entry.fd,read);result++; }
        if(write && (entry.events&POLLOUT) && (entry.revents&(POLLOUT|POLLHUP|POLLERR))) { rb_fd_set(entry.fd,write);result++; }
        if(except && (entry.revents&POLLPRI)) { rb_fd_set(entry.fd,except);result++; }
    }
    if(timeout) { double remaining=args.deadline-select_now();if(remaining<0)remaining=0;timeout->tv_sec=(long)remaining;timeout->tv_usec=(long)((remaining-timeout->tv_sec)*1000000); }
    return result;
}
#ifdef SP_THREADS
#include <pthread.h>
#include <signal.h>
static pthread_once_t io_signal_once=PTHREAD_ONCE_INIT;
static int io_signal_error;
static void io_signal_handler(int signal) { (void)signal; }
static void io_signal_init(void) {
    struct sigaction previous, action;
    memset(&action,0,sizeof(action));
    action.sa_handler=io_signal_handler;sigemptyset(&action.sa_mask);
    if(sigaction(SIGVTALRM,NULL,&previous) ||
       (previous.sa_handler!=SIG_DFL && previous.sa_handler!=SIG_IGN) ||
       sigaction(SIGVTALRM,&action,NULL))io_signal_error=1;
}
static void io_unblock(void *data) { pthread_kill(*(pthread_t *)data,SIGVTALRM); }
static pthread_once_t cxl_once = PTHREAD_ONCE_INIT;
static pthread_mutex_t cxl;
static SP_TLS unsigned cxl_depth;
static void cxl_init(void) {
    pthread_mutexattr_t attr;
    if (pthread_mutexattr_init(&attr) ||
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE) ||
        pthread_mutex_init(&cxl, &attr)) abort();
    pthread_mutexattr_destroy(&attr);
}
void sp_cext_lock(void) {
    pthread_once(&cxl_once, cxl_init);
    if (!cxl_depth) {
        sp_native_enter();
        int error = pthread_mutex_lock(&cxl);
        sp_native_leave();
        if (error) abort();
    }
    cxl_depth++;
}
void sp_cext_unlock(void) {
    if (!cxl_depth) abort();
    if (!--cxl_depth && pthread_mutex_unlock(&cxl)) abort();
}
unsigned sp_cext_lock_depth(void) { return cxl_depth; }
unsigned sp_cext_lock_suspend(void) {
    unsigned depth = cxl_depth;
    if (depth) {
        cxl_depth = 0;
        if (pthread_mutex_unlock(&cxl)) abort();
    }
    return depth;
}
void sp_cext_lock_resume(unsigned depth) {
    if (!depth) return;
    if (cxl_depth) abort();
    sp_cext_lock(); cxl_depth = depth;
}
#else
void sp_cext_lock(void) {}
void sp_cext_unlock(void) {}
unsigned sp_cext_lock_depth(void) { return 0; }
unsigned sp_cext_lock_suspend(void) { return 0; }
void sp_cext_lock_resume(unsigned depth) { (void)depth; }
#endif

void *rb_thread_call_without_gvl(void *(*function)(void *), void *data,
                                  rb_unblock_function_t *unblock, void *unblock_data) {
    void *result = NULL;
#ifdef SP_THREADS
    int repeat=unblock==RUBY_UBF_IO;
    pthread_t native_thread=pthread_self();
    sigset_t previous_mask;
    if(repeat) {
        pthread_once(&io_signal_once,io_signal_init);
        if(io_signal_error)rb_raise(rb_eRuntimeError,"C extension I/O interrupt signal is unavailable");
        sigset_t signals;sigemptyset(&signals);sigaddset(&signals,SIGVTALRM);
        pthread_sigmask(SIG_UNBLOCK,&signals,&previous_mask);
        unblock=io_unblock;unblock_data=&native_thread;
    }
#endif
    unsigned depth = sp_cext_lock_suspend();
#ifdef SP_THREADS
    int run = sp_cext_native_register(unblock, unblock_data,repeat);
#else
    int run = 1;
    (void)unblock; (void)unblock_data;
#endif
    if (run) {
        sp_native_enter();
        result = function(data);
        sp_native_leave();
#ifdef SP_THREADS
        sp_cext_native_unregister();
#endif
    }
#ifdef SP_THREADS
    if(repeat)pthread_sigmask(SIG_SETMASK,&previous_mask,NULL);
#endif
    sp_cext_lock_resume(depth);
    sp_fiber_fire_inject_if_pending();
    return result;
}
#endif
