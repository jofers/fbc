/* fiber creation and destruction stubs */

#include "fb.h"

FBCALL FBFIBER *fb_FiberCreate( FB_THREADPROC proc, void *param, int stack_size )
{
	return NULL;
}

FBCALL void fb_FiberSwitch( FBFIBER *thread )
{
}

FBCALL void fb_FiberDestroy( FB_THREADPROC *thread )
{
}