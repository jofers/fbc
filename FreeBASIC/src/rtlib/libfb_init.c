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
 * init.c -- libfb initialization
 *
 * chng: oct/2004 written [v1ctor]
 *
 */

#include <stdlib.h>
#include "fb.h"

/* globals */
int fb_argc;
char **fb_argv;

FB_HOOKSTB fb_hooks = { NULL };
FB_FILE fb_fileTB[FB_MAX_FILES];
int __fb_file_handles_cleared = FALSE;

FBSTRING fb_strNullDesc = { NULL, 0 };

FnDevOpenHook fb_pfnDevOpenHook = NULL;

/*:::::*/
FBCALL void fb_Init ( int argc, char **argv )
{
#ifdef MULTITHREADED
	int i;
#endif

    /* save argc and argv */
	fb_argc = argc;
	fb_argv = argv;

	/* initialize files table */
    memset( fb_fileTB, 0, sizeof( fb_fileTB ) );
    __fb_file_handles_cleared = TRUE;

	/* os-dep initialization */
    fb_hInit( argc, argv );

#ifdef MULTITHREADED
	/* allocate thread local storage keys */
	for( i = 0; i < FB_TLSKEYS; i++ )
		FB_TLSALLOC( fb_tls_ctxtb[i] );
#endif
}


