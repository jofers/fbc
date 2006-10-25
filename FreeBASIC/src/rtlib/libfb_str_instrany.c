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
 * str_instr.c -- instr function
 *
 * chng: oct/2004 written [v1ctor]
 * chng: aug/2005 added boyer-moore and quirck search algorithms [mjs]
 *                added special search case with pattern length = 1 [mjs]
 *
 */

#include <malloc.h>
#include <string.h>
#include "fb.h"

FBCALL int fb_StrInstrAny ( int start, FBSTRING *src, FBSTRING *patt )
{
    int r;

    if( (src == NULL) || (src->data == NULL) || (patt == NULL) || (patt->data == NULL) ) {
        r = 0;
    } else {
        size_t size_src = FB_STRSIZE(src);
        size_t size_patt = FB_STRSIZE(patt);
        if( ((start < 1) || (start > size_src)) ) {
            r = 0;
        } else if( size_patt==0 && size_src!=0 ) {
            r = start;
        } else {
            size_t i, found, search_len = size_src - start + 1;
            const char *pachText = src->data + start - 1;
            r = search_len;
            for( i=0; i!=size_patt; ++i ) {
                const char *pszEnd = FB_MEMCHR( pachText, patt->data[i], r );
                if( pszEnd!=NULL ) {
                    found = pszEnd - pachText;
                    if( found < r )
                        r = found;
                }
            }
            if( r==search_len ) {
                r = 0;
            } else {
                r += start;
            }
        }
    }

    FB_STRLOCK();

	/* del if temp */
	fb_hStrDelTemp_NoLock( src );
	fb_hStrDelTemp_NoLock( patt );

    FB_STRUNLOCK();

    return r;
}