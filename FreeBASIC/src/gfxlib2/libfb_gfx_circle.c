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
 * circle.c -- CIRCLE statement
 *
 * chng: jan/2005 written [lillo]
 *
 */

#include "fb_gfx.h"


/*:::::*/
static void draw_scanline(int y, int x1, int x2, unsigned int color, int fill, char *filled)
{
	if ((y >= fb_mode->view_y) && (y < fb_mode->view_y + fb_mode->view_h)) {
		if (fill) {
			if ((x2 < fb_mode->view_x) || (x1 >= fb_mode->view_x + fb_mode->view_w) || (filled[y - fb_mode->view_y]))
				return;
			filled[y - fb_mode->view_y] = TRUE;
			x1 = MAX(x1, fb_mode->view_x);
			x2 = MIN(x2, fb_mode->view_x + fb_mode->view_w - 1);
			fb_hPixelSet(fb_mode->line[y] + (x1 * fb_mode->bpp), color, x2 - x1 + 1);
		}
		else {
			if ((x1 >= fb_mode->view_x) && (x1 < fb_mode->view_x + fb_mode->view_w))
				fb_hPutPixel(x1, y, color);
			if ((x2 >= fb_mode->view_x) && (x2 < fb_mode->view_x + fb_mode->view_w))
				fb_hPutPixel(x2, y, color);
		}
	}
}


/*:::::*/
static void draw_ellipse(int x, int y, float a, float b, unsigned int color, int fill)
{
	int d, x1, y1, x2, y2;
	long long dx, dy, aq, bq, r, rx, ry;
	char filled[fb_mode->view_h];

	x1 = x - a;
	x2 = x + a;
	y1 = y2 = y;
	fb_hMemSet(filled, 0, fb_mode->view_h);
	
	if (!b) {
		draw_scanline(y, x1, x2, color, TRUE, filled);
		return;
	}
	else
		draw_scanline(y, x1, x2, color, fill, filled);
	
	aq = a * a;
	bq = b * b;
	dx = aq << 1;
	dy = bq << 1;
	r = a * bq;
	rx = r << 1;
	ry = 0;
	d = a;
	
	while (d > 0) {
		if (r > 0) {
			y1++;
			y2--;
			ry += dx;
			r -= ry;
		}
		if (r <= 0) {
			d--;
			x1++;
			x2--;
			rx -= dy;
			r += rx;
		}
		draw_scanline(y1, x1, x2, color, fill, filled);
		draw_scanline(y2, x1, x2, color, fill, filled);
	}
}


/*:::::*/
static void get_arc_point(float angle, float a, float b, int *x, int *y)
{
	float c, s;
	
	c = cos(angle) * a;
	s = sin(angle) * b;
	if (c >= 0)
		*x = (int)(c + 0.5);
	else
		*x = (int)(c - 0.5);
	if (s >= 0)
		*y = (int)(s + 0.5);
	else
		*y = (int)(s - 0.5);
}


/*:::::*/
FBCALL void fb_GfxEllipse(void *target, float fx, float fy, float radius, unsigned int color, float aspect, float start, float end, int fill, int coord_type)
{
	int x, y, x1, y1, top, bottom;
	unsigned int orig_color;
	float a, b, increment;
	
	if (!fb_mode)
		return;
	
	orig_color = color;
	if (color == DEFAULT_COLOR)
		color = fb_mode->fg_color;
	else
		color = fb_hFixColor(color);
	
	fb_hPrepareTarget(target, color);
	
	fb_hFixRelative(coord_type, &fx, &fy, NULL, NULL);
	
	fb_hTranslateCoord(fx, fy, &x, &y);
	
	if (aspect == 0.0)
		aspect = (4.0 / 3.0) * ((float)fb_mode->h / (float)fb_mode->w);

	if (aspect > 1.0) {
		a = (radius / aspect);
		b = radius;
	}
	else {
		a = radius;
		b = (radius * aspect);
	}
	if (fb_mode->flags & WINDOW_ACTIVE) {
		a *= (fb_mode->view_w / (fb_mode->win_w - 1));
		b *= (fb_mode->view_h / (fb_mode->win_h - 1));
	}
	
	if ((start != 0.0) || (end != 3.141593f * 2.0)) {
		
		if (start < 0) {
			start = -start;
			get_arc_point(start, a, b, &x1, &y1);
			x1 = x + x1;
			y1 = y - y1;
			fb_GfxLine(target, x, y, x1, y1, orig_color, LINE_TYPE_LINE, 0xFFFF, COORD_TYPE_AA);
		}
		if (end < 0) {
			end = -end;
			get_arc_point(end, a, b, &x1, &y1);
			x1 = x + x1;
			y1 = y - y1;
			fb_GfxLine(target, x, y, x1, y1, orig_color, LINE_TYPE_LINE, 0xFFFF, COORD_TYPE_AA);
		}
		
		while (end < start)
			end += 2 * PI;
		while (end - start > 2 * PI)
			start += 2 * PI;
		
		increment = 1 / (sqrt(a) * sqrt(b) * 1.5);
		
		DRIVER_LOCK();
		
		top = bottom = y;
		for (; start < end + (increment / 2); start += increment) {
			get_arc_point(start, a, b, &x1, &y1);
			x1 = x + x1;
			y1 = y - y1;
			if ((x1 < fb_mode->view_x) || (x1 >= fb_mode->view_x + fb_mode->view_w) ||
			    (y1 < fb_mode->view_y) || (y1 >= fb_mode->view_y + fb_mode->view_h))
				continue;
			fb_hPutPixel(x1, y1, color);
			if (y1 > bottom)
				bottom = y1;
			if (y1 < top)
				top = y1;
		}
	}
	else {
		DRIVER_LOCK();
		
		draw_ellipse(x, y, a, b, color, fill);
		top = y - b;
		bottom = y + b;
	}
	
	top = MID(0, top, fb_mode->view_h - 1);
	bottom = MID(0, bottom, fb_mode->view_h - 1);
	if( top > bottom )
		SWAP( top, bottom );
	SET_DIRTY(top, bottom - top + 1);
	
	DRIVER_UNLOCK();
	
	fb_mode->last_x = fx;
	fb_mode->last_y = fy;
}