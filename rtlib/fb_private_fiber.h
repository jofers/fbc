#include "fb.h"
#if defined HOST_UNIX
    #include <ucontext.h>
    #include <unistd.h>
    #define FBFIBER_STACK_SIZE 1024*64
#elif defined HOST_WIN32
	#include <windows.h>
#endif

typedef enum _FB_FIBERCLASS {
    FB_FIBERCLASS_ITER,
    FB_FIBERCLASS_FIBER    
} FB_FIBERCLASS;

struct _FBFIBER {
#if defined HOST_DOS
	int id;
#elif defined HOST_XBOX
	int id;
#elif defined HOST_UNIX
	ucontext_t  id;
#elif defined HOST_WIN32
	void *id;
#else
#error Unexpected target
#endif
    FBFIBER       *caller;
	FB_THREADPROC  proc;
	void          *param;
	void          *yield_data;
    FB_FIBERCLASS  fiber_class;
};

typedef struct _FB_FIBERCTX {
    FBFIBER *current_fiber;
    FBFIBER *current_iter;
    FBFIBER root_fiber;
} FB_FIBERCTX;

FBCALL FBFIBER          *fb_FiberIterCreate( FB_THREADPROC proc, void *param );
FBCALL FBFIBER          *fb_FiberCreateCore( FB_THREADPROC proc, void *param, int stack_size, FB_FIBERCLASS fiber_class );
