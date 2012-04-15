/* fiber creation and destruction on Unix */

#include "fb.h"

void fb_fiberprocworker( void *param )
{
    FBFIBER *fiber = (FBFIBER *)param;
    if( fiber == NULL )
        return;
    fiber->proc( param );
}

FBCALL FBFIBER *fb_FiberCurrent( )
{
    FB_FIBERCTX *context = FB_TLSGETCTX(FIBER);
    return context->current_fiber;
}

FBCALL FBFIBER *fb_FiberCreate( FB_THREADPROC proc, void *param, int stack_size )
{
    FIBER *fiber = NULL;
    FB_FIBERCTX *context = FB_TLSGETCTX(FIBER);
    int fiber_stack_size;
    void *fiber_stack = NULL;
    int fault = FALSE;
    
    fiber = (FBFIBER *)malloc( sizeof(FBFIBER) );
    if( fiber == NULL )
        fiber = context->current_fiber->caller;
    if( fiber == NULL )
        return;

    if( context->current_fiber == NULL )
        context->current_fiber = context->root_fiber;
    fiber->caller = &context->current_fiber;
    fiber->id.uc_link = context->current_fiber->id;
    
    /* linux has a diy stack */
    if( stack_size == NULL )
        fiber_stack_size = FBFIBER_STACK_SIZE;
    else
        fiber_stack_size = stack_size;
    fiber->id.uc_stack.ss_size = fiber_stack_size;
    fiber_stack = (void *)malloc( stack_size );
    if( fiber_stack == NULL )
    {
        free( fiber );
        return NULL;
    }
    fiber->id.uc_stack.ss_sp = fiber_stack
    
    makecontext( &fiber->id, 
                 (void (*)(void)) fb_fiberproc_worker, 
                 1, 
                 fiber );
    getcontext( &context->current_fiber->id );
    
    return fiber;
}

FBCALL void fb_FiberSwitch( FBFIBER *fiber )
{
    FB_FIBERCTX *context = FB_TLSGETCTX(FIBER);
    if( fiber == NULL )
        return;
    if( context->current_fiber == NULL )
        return;
    fiber->caller = context->current_fiber;
    context->current_fiber = fiber;
    swapcontext( &context->current_fiber->id, &fiber->id );
}

FBCALL void fb_FiberDestroy( FBFIBER *fiber )
{
    if( fiber == NULL )
        return NULL;
    free( fiber->id.ss_sp );
    free( fiber );
}