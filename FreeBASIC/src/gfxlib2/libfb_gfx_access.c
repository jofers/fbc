/*
 *  libgfx2 - FreeBASIC's alternative gfx library
 *	Copyright (C) 2005 Angelo Mottola (a.mottola@libero.it)
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
 * access.c -- low level screen access routines
 *
 * chng: jan/2005 written [lillo]
 *
 */

#include "fb_gfx.h"


/*:::::*/
FBCALL void fb_GfxLock(void)
{
	if (!fb_mode)
		return;

	if (!(fb_mode->flags & SCREEN_LOCKED)) {
		fb_mode->driver->lock();
		fb_mode->flags |= SCREEN_LOCKED;
	}
}


/*:::::*/
FBCALL void fb_GfxUnlock(int start_line, int end_line)
{
	if (!fb_mode)
		return;
	if (start_line < 0)
		start_line = 0;
	if (end_line < 0)
		end_line = fb_mode->view_h - 1;
	if ((fb_mode->framebuffer == fb_mode->line[0]) && (start_line <= end_line) && (end_line < fb_mode->view_h))
		fb_hMemSet(fb_mode->dirty + start_line, TRUE, end_line - start_line + 1);

	if (fb_mode->flags & SCREEN_LOCKED) {
		fb_mode->driver->unlock();
		fb_mode->flags &= ~(SCREEN_LOCKED | SCREEN_AUTOLOCKED);
	}
}


/*:::::*/
FBCALL void *fb_GfxScreenPtr(void)
{
	if (!fb_mode)
		return NULL;
	fb_hPrepareTarget(NULL, MASK_A_32);
	
	return fb_mode->line[0];
}