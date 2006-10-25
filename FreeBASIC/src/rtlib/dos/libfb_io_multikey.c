/*
 *  libfb - FreeBASIC's runtime library
 *	Copyright (C) 2004-2006 Andre V. T. Vicentini (av1ctor@yahoo.com.br) and
 *  the FreeBASIC development team.
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
 * io_multikey.c -- multikey function for DOS console mode apps
 *
 * chng: jun/2005 written [DrV]
 *
 */

#include "fb.h"
#include "fb_scancodes.h"

#include <stdlib.h>
#include <dpmi.h>
#include <go32.h>
#include <pc.h>

#define lock_var(var)        fb_dos_lock_data( (void *)&(var), sizeof(var) )
#define lock_array(array)    fb_dos_lock_data( (void *)(array), sizeof(array) )
#define lock_proc(proc)      fb_dos_lock_code( proc, (unsigned) end_##proc - (unsigned) proc )

#define unlock_var(var)        fb_dos_unlock_data( (void *)&(var), sizeof(var) )
#define unlock_array(array)    fb_dos_unlock_data( (void *)(array), sizeof(array) )
#define unlock_proc(proc)      fb_dos_unlock_code( proc, (unsigned) end_##proc - (unsigned) proc )

#define END_OF_FUNCTION(proc)               void end_##proc (void) { }
#define END_OF_STATIC_FUNCTION(proc) static void end_##proc (void) { }

static void end_fb_ConsoleMultikey(void);

static int inited = FALSE;
static volatile char key[128];
static volatile int  got_extended_key = FALSE;

static __inline__
int fb_hWriteControlCommand( unsigned char uchValue )
{
	unsigned char uchStatus;
	size_t count = 65535;
	do {
		uchStatus = inportb(0x64);         /* read keyboard status */
	} while( ((uchStatus & 0x02)!=0) && --count );
	outportb( 0x64, uchValue );
	return (uchStatus & 0x02)==0;
}

/*:::::*/
static int fb_MultikeyHandler(unsigned irq_number)
{
#if 0
    __dpmi_regs regs;
#endif
	unsigned char scancode_raw;

	fb_hWriteControlCommand( 0xAD );    /* Lock keyboard */

	/* read the raw scancode from the keyboard */
	scancode_raw = inportb(0x60);       /* read scancode */

#if 0
	printf(":%02x", scancode_raw);
#endif

#if 0
	/* Translate scancode */
	regs.h.ah = 0x4F;
	regs.h.al = scancode_raw;
	__dpmi_int(0x15, &regs);
	if( regs.x.flags & 1 )
#endif
	{
#if 0
		size_t code = regs.h.al;
#else
		size_t code = scancode_raw;
#endif
		if( code==0xE0 ) {
			got_extended_key = TRUE;
		} else {
			int release_code = (code & 0x80)!=0;
			code &= 0x7F;
			if( got_extended_key ) {
				got_extended_key = FALSE;
				switch( code ) {
				case 0x2A:
					code = 0;
					break;
				}
			}
			if( code!=0 ) {
				/* Remeber scancode status */
				__fb_force_input_buffer_changed = key[code] = !release_code;
			}
		}
	}

	fb_hWriteControlCommand( 0xAE );    /* Unlock keyboard */

	return FALSE;
}
END_OF_STATIC_FUNCTION(fb_MultikeyHandler);

/*:::::*/
static void fb_ConsoleMultikeyExit(void)
{
	fb_isr_reset( 1 );
	unlock_proc(fb_ConsoleMultikey);
	unlock_proc(fb_MultikeyHandler);
	unlock_array(key);
	unlock_var(got_extended_key);
	unlock_var(__fb_force_input_buffer_changed);
}

void fb_ConsoleMultikeyInit( void )
{
	if (inited)
		return;

	inited = TRUE;
	memset((void*)key, FALSE, sizeof(key));

	/* We have to lock the memory BEFORE we redirect the ISR! */
	lock_array(key);
	lock_var(got_extended_key);
	lock_var(__fb_force_input_buffer_changed);
	lock_proc(fb_MultikeyHandler);
	lock_proc(fb_ConsoleMultikey);
	fb_isr_set( 1,
	            fb_MultikeyHandler,
	            0,
	            16384 );

	atexit( fb_ConsoleMultikeyExit );
}

/*:::::*/
int fb_ConsoleMultikey( int scancode )
{
	if( scancode >= sizeof( key ) )
		return FB_FALSE;

	fb_ConsoleMultikeyInit( );

	return (key[scancode]? FB_TRUE: FB_FALSE);
}
END_OF_FUNCTION(fb_ConsoleMultikey);