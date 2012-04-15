typedef void (FBCALL *FB_THREADPROC)( void *param );

struct _FBTHREAD;
typedef struct _FBTHREAD FBTHREAD;

struct _FBMUTEX;
typedef struct _FBMUTEX FBMUTEX;

struct _FBCOND;
typedef struct _FBCOND FBCOND;

struct _FBFIBER;
typedef struct _FBFIBER FBFIBER;

FBCALL FBTHREAD         *fb_ThreadCreate( FB_THREADPROC proc, void *param, int stack_size );
FBCALL void              fb_ThreadWait  ( FBTHREAD *thread );

       FBTHREAD         *fb_ThreadCall  ( void *proc, int abi, int stack_size, int num_args, ... );

FBCALL FBMUTEX          *fb_MutexCreate ( void );
FBCALL void              fb_MutexDestroy( FBMUTEX *mutex );
FBCALL void              fb_MutexLock   ( FBMUTEX *mutex );
FBCALL void              fb_MutexUnlock ( FBMUTEX *mutex );

FBCALL FBCOND           *fb_CondCreate   ( void );
FBCALL void              fb_CondDestroy  ( FBCOND *cond );
FBCALL void              fb_CondSignal   ( FBCOND *cond );
FBCALL void              fb_CondBroadcast( FBCOND *cond );
FBCALL void              fb_CondWait     ( FBCOND *cond, FBMUTEX *mutex );

FBCALL FBFIBER          *fb_FiberCreate    ( FB_THREADPROC proc, void *param, int stack_size );
FBCALL void              fb_FiberSwitch    ( FBFIBER *thread );
FBCALL FBFIBER          *fb_FiberCurrent   ( );
FBCALL void              fb_FiberYield     ( void *yield_data );
FBCALL void             *fb_FiberGetYield  ( );
FBCALL void              fb_FiberDestroy   ( FBFIBER *thread );

/**************************************************************************************************
 * per-thread local storage context
 **************************************************************************************************/

enum {
	FB_TLSKEY_ERROR,
	FB_TLSKEY_DIR,
	FB_TLSKEY_INPUT,
	FB_TLSKEY_PRINTUSG,
	FB_TLSKEY_GFX,
    FB_TLSKEY_FIBER,
	FB_TLSKEYS
};

FBCALL void             *fb_TlsGetCtx   ( int index, int len );
FBCALL void              fb_TlsDelCtx   ( int index );
FBCALL void              fb_TlsFreeCtxTb( void );
#ifdef ENABLE_MT
       void              fb_TlsInit     ( void );
       void              fb_TlsExit     ( void );
#endif

#define FB_TLSGETCTX(id) (FB_##id##CTX *)fb_TlsGetCtx( FB_TLSKEY_##id, sizeof( FB_##id##CTX ) );
