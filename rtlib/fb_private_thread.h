#include "fb.h"
#if defined HOST_UNIX
	#include <pthread.h>
#elif defined HOST_WIN32
	#include <windows.h>
#endif

struct _FBTHREAD {
#if defined HOST_DOS
	int id;
#elif defined HOST_UNIX
	pthread_t id;
#elif defined HOST_WIN32
	HANDLE id;
#elif defined HOST_XBOX
	HANDLE id;
#else
#error Unexpected target
#endif
	FB_THREADPROC proc;
	void         *param;
	void         *opaque;
};

struct _FBMUTEX {
#if defined HOST_UNIX
	pthread_mutex_t id;
#elif defined HOST_WIN32
	HANDLE id;
#endif
};
