/*
 *  libfb - FreeBASIC's runtime library
 *	Copyright (C) 2004-2008 The FreeBASIC development team.
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
 *
 *  As a special exception, the copyright holders of this library give
 *  you permission to link this library with independent modules to
 *  produce an executable, regardless of the license terms of these
 *  independent modules, and to copy and distribute the resulting
 *  executable under terms of your choice, provided that you also meet,
 *  for each linked independent module, the terms and conditions of the
 *  license of that module. An independent module is a module which is
 *  not derived from or based on this library. If you modify this library,
 *  you may extend this exception to your version of the library, but
 *  you are not obligated to do so. If you do not wish to do so, delete
 *  this exception statement from your version.
 */

/*
 * ctor.c -- rtlib initialization and cleanup
 *
 * chng: oct/2004 written [v1ctor]
 *
 */

#include "fb.h"

void fb_hRtInit ( void );
void fb_hRtExit ( void );

/* note: they must be static, or shared libraries in Linux would reuse the 
		 same function */

/*:::::*/
static void fb_hDoInit( void ) /* __attribute__((constructor)) */;
static void fb_hDoInit( void )
{
	/* the last to be defined, the first that will be called */
	fb_hRtInit( );
}

/*:::::*/
static void fb_hDoExit( void ) /* __attribute__((destructor)) */;
static void fb_hDoExit( void )
{
	/* the last to be defined, the last that will be called */

	fb_hRtExit( );
}

/* This puts the init/exit global ctor/dtor for the rtlib in the sorted ctors/dtors
   section.  A named section of .?tors.65435 = Priority(100) */

static void * priorityhDoInit __attribute__((section(".ctors.65435"), used)) = fb_hDoInit;
static void * priorityhDoExit __attribute__((section(".dtors.65435"), used)) = fb_hDoExit;