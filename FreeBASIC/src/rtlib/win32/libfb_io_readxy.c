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
 * io_readxy.c -- SCREEN() function for Windows
 *
 * chng: jan/2005 written [v1ctor]
 *       jul/2005 mod: use convert*console functions [mjs]
 *
 */

#include "fb.h"

/*:::::*/
FBCALL unsigned int fb_ConsoleReadXY( int col, int row, int colorflag )
{
    TCHAR character;
    WORD attribute;
    DWORD res;
    COORD coord;

    fb_hConvertToConsole( &col, &row, NULL, NULL );

    coord.X = (SHORT) col;
    coord.Y = (SHORT) row;

    if( colorflag ) {
        ReadConsoleOutputAttribute( __fb_out_handle, &attribute, 1, coord, &res);
        return ((unsigned int)attribute) & 0xfffful;
    }
    else {
    	ReadConsoleOutputCharacter( __fb_out_handle, &character, 1, coord, &res);
    	return ((unsigned int)character) & (sizeof(TCHAR) == 1? 0xfful : 0xfffful);
    }
}