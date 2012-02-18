/* read stmt for byte's */

#include "fb.h"

/*:::::*/
FBCALL void fb_DataReadByte( char *dst )
{
	short len;

	FB_LOCK();

	len = fb_DataGetLen();

	if( len == 0 )
		*dst = 0;
	else if( len == FB_DATATYPE_OFS )
		*dst = (char)(unsigned long)__fb_data_ptr->ofs;
	/* wstring? */
	else if( len & FB_DATATYPE_WSTR )
        *dst = (char)fb_WstrToInt( __fb_data_ptr->wstr, len & 0x7FFF );
	else
        *dst = (char)fb_hStr2Int( __fb_data_ptr->zstr, len );

	if( __fb_data_ptr != NULL )
		++__fb_data_ptr;

	FB_UNLOCK();
}

