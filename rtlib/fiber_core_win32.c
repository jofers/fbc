/* Windows fiber creation and destruction */

#include "fb.h"
#include "fb_private_fiber.h"
#include <process.h>

/* thread proxy to user's thread proc */
void WINAPI fb_fiberprocworker( PVOID param )
{
	FBFIBER *fiber = (FBFIBER *)param;

	/* call the user thread */
	fiber->proc( fiber->param );
    fiber->yield_data = 0;
    
    /* exit fiber */
    fb_FiberSwitch( NULL );
}

/*:::::*/
FBCALL FBFIBER *fb_FiberCreateCore( FB_THREADPROC proc, void *param, int stack_size, FB_FIBERCLASS fiber_class )
{
	FBFIBER *fiber;
    FB_FIBERCTX *context = FB_TLSGETCTX(FIBER);
    
    fiber = (FBFIBER *)malloc( sizeof(FBFIBER) );
	if( fiber == NULL )
		return NULL;
    fiber->proc	= proc;
    fiber->param = param;
    
    /* fibers may only be called from other fibers */
    if( context->current_fiber == NULL )
    {
        context->current_fiber = &context->root_fiber;
        context->root_fiber.id = ConvertThreadToFiber( NULL );
    }
    fiber->caller = context->current_fiber;
    fiber->fiber_class = fiber_class;
    
    /* actually create the fiber */
    if( fiber->caller != NULL )
        fiber->id = CreateFiber( stack_size,
                                 fb_fiberprocworker,
                                 (void *)fiber );

    if( fiber->id == NULL )
    {
    	free( fiber );
    	return NULL;
    }

	return fiber;
}

FBCALL FBFIBER *fb_FiberCurrent( )
{
    FB_FIBERCTX *context = FB_TLSGETCTX(FIBER);
    return context->current_fiber;
}

FBCALL void fb_FiberSwitch( FBFIBER *fiber )
{
    FB_FIBERCTX *context = FB_TLSGETCTX(FIBER);
    if( context->current_fiber == NULL )
        return;
    if( fiber == NULL )
        fiber = context->current_fiber->caller;
    if( fiber == NULL )
        return;

    if( fiber->fiber_class == FB_FIBERCLASS_FIBER )
        fiber->caller = context->current_fiber;
    context->current_fiber = fiber;
    SwitchToFiber( fiber->id );
}

/*:::::*/
FBCALL void fb_FiberDestroy( FBFIBER *fiber )
{
	if( fiber == NULL )
		return;

    DeleteFiber( fiber->id );
    free( fiber );
}
