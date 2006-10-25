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
 * point.c -- pixel retrieving
 *
 * chng: jan/2005 written [lillo]
 *
 */

#include "fb_gfx.h"


/*:::::*/
FBCALL int fb_GfxPoint(void *target, float fx, float fy)
{
	int x, y;
	unsigned int color;

	if (!fb_mode)
		return -1;

	if( fy == -8388607.0 )
		return fb_GfxCursor(fx);

	fb_hPrepareTarget(target, MASK_A_32);

	fb_hTranslateCoord(fx, fy, &x, &y);

	if ((x < fb_mode->view_x) || (y < fb_mode->view_y) ||
	    (x >= fb_mode->view_x + fb_mode->view_w) || (y >= fb_mode->view_y + fb_mode->view_h))
		return -1;

	DRIVER_LOCK();
	color = fb_hGetPixel(x, y);
	DRIVER_UNLOCK();

	if (fb_mode->depth == 16)
		/* approximate: for each component we also report high bits in lower bits of new value */
		color = (((color & 0x001F) << 3) | ((color >> 2) & 0x7) |
			 ((color & 0x07E0) << 5) | ((color >> 1) & 0x300) |
			 ((color & 0xF800) << 8) | ((color << 3) & 0x70000));

	return (int)color;
}