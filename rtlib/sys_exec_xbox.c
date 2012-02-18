/* exec function for xbox */

#include "fb.h"

FBCALL int fb_ExecEx( FBSTRING *program, FBSTRING *args, int do_fork )
{
	XLaunchXBE(program->data);
	return fb_ErrorSetNum(FB_RTERROR_FILENOTFOUND);
}

FBCALL int fb_Exec ( FBSTRING *program, FBSTRING *args )
{
	return fb_ExecEx( program, args, FALSE );
}
