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
 * dev_file_size - file device size calc
 *
 * chng: jul/2005 written [v1ctor]
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include "fb.h"
#include "fb_rterr.h"

/*:::::*/
int fb_hDevFileSeekStart
	(
		FILE *fp,
		int mode,
		FB_FILE_ENCOD encod,
		int seek_zero
	)
{
	/* skip the BOM if in UTF-mode */
    int ofs;

    switch( encod )
    {
    case FB_FILE_ENCOD_UTF8:
    	ofs = 3;
        break;

	case FB_FILE_ENCOD_UTF16:
    	ofs = sizeof( UTF_16 );
        break;

	case FB_FILE_ENCOD_UTF32:
    	ofs = sizeof( UTF_32 );
        break;

	default:
    	if( seek_zero == FALSE )
    		return 0;

    	ofs = 0;
	}

	return fseek( fp, ofs, SEEK_SET );
}

/*:::::*/
long fb_DevFileGetSize
	(
		FILE *fp,
		int mode,
		FB_FILE_ENCOD encod,
		int seek_back
	)
{
	long size = 0;

	switch( mode )
    {
    case FB_FILE_MODE_BINARY:
	case FB_FILE_MODE_RANDOM:
    case FB_FILE_MODE_INPUT:

		if( fseek( fp, 0, SEEK_END ) != 0 )
			return -1;

		size = ftell( fp );

		if( seek_back )
			fb_hDevFileSeekStart( fp, mode, encod, TRUE );

    	break;

	case FB_FILE_MODE_APPEND:
    	size = ftell( fp );
	}

	return size;
}
