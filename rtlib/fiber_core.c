/* fiber creation and destruction stubs */

#include "fb.h"
#include "fb_private_fiber.h"

FBCALL void fb_FiberYield( void *data )
{
    FB_FIBERCTX *context = FB_TLSGETCTX(FIBER);
    if ( context == NULL )
        return;
    if ( context->current_fiber == NULL )
        return;
    context->current_fiber->yield_data = data;
    fb_FiberSwitch( context->current_fiber->caller );
}

FBCALL void *fb_FiberGetYield( FBFIBER *fiber )
{
    if( fiber == NULL )
        return NULL;
    return fiber->yield_data;
}

FBCALL FBFIBER *fb_FiberCreate( FB_THREADPROC proc, void *param, int stack_size )
{
    return fb_FiberCreateCore( proc, param, stack_size, FB_FIBERCLASS_FIBER );
}

FBCALL FBFIBER *fb_FiberIterCreate( FB_THREADPROC proc, void *param )
{
    return fb_FiberCreateCore( proc, param, 0, FB_FIBERCLASS_ITER );
}
