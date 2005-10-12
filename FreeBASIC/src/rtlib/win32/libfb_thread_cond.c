/*
 *  libfb - FreeBASIC's runtime library
 *	Copyright (C) 2004-2005 Andre V. T. Vicentini (av1ctor@yahoo.com.br) and others.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/*
 * thread_cond.c -- Windows condition variables handling routines, based on
 *		    paper by Douglas C. Schmidt and Irfan Pyarali
 *
 * chng: feb/2005 written [lillo]
 *
 */

#include "fb.h"

#define SIGNAL		0
#define BROADCAST	1

typedef struct _FBCOND
{
	int waiters;
	CRITICAL_SECTION lock;
	HANDLE event[2];
} FBCOND;


/*:::::*/
FBCALL FBCOND *fb_CondCreate( void )
{
	FBCOND *cond;

	cond = (FBCOND *)malloc( sizeof( FBCOND ) );
	if( !cond )
		return NULL;

	cond->waiters = 0;
	InitializeCriticalSection( &cond->lock );
	cond->event[SIGNAL]    = CreateEvent( NULL, FALSE, FALSE, NULL );
	cond->event[BROADCAST] = CreateEvent( NULL, TRUE, FALSE, NULL );

	return cond;
}

/*:::::*/
FBCALL void fb_CondDestroy( FBCOND *cond )
{
	/* dumb address checking */
	if( cond == NULL )
		return;

	DeleteCriticalSection( &cond->lock );
	CloseHandle( cond->event[SIGNAL] );
	CloseHandle( cond->event[BROADCAST] );

	free( (void *)cond );
}

/*:::::*/
FBCALL void fb_CondSignal( FBCOND *cond )
{
	int has_waiters;

	if( cond == NULL )
		return;

	EnterCriticalSection( &cond->lock );
	has_waiters = cond->waiters > 0;
	LeaveCriticalSection( &cond->lock );
	if( has_waiters )
		SetEvent( cond->event[SIGNAL] );
}

/*:::::*/
FBCALL void fb_CondBroadcast( FBCOND *cond )
{
	int has_waiters;

	if( cond == NULL )
		return;

	EnterCriticalSection( &cond->lock );
	has_waiters = cond->waiters > 0;
	LeaveCriticalSection( &cond->lock );
	if( has_waiters )
		SetEvent( cond->event[BROADCAST] );
}

/*:::::*/
FBCALL void fb_CondWait( FBCOND *cond )
{
	int result, last_waiter;

	if( cond == NULL )
		return;

	EnterCriticalSection( &cond->lock );
	cond->waiters++;
	LeaveCriticalSection( &cond->lock );

	result = WaitForMultipleObjects( 2, cond->event, FALSE, INFINITE );

	EnterCriticalSection( &cond->lock );
	cond->waiters--;
	last_waiter = (result == WAIT_OBJECT_0 + BROADCAST) && (cond->waiters == 0);
	LeaveCriticalSection( &cond->lock );

	if( last_waiter )
		ResetEvent( cond->event[BROADCAST] );
}
