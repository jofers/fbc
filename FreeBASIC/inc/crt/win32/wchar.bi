''
''
'' wchar -- header translated with help of SWIG FB wrapper
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
''
''
#ifndef __crt_win32_wchar_bi__
#define __crt_win32_wchar_bi__

#include once "crt/win32/ctype.bi"

#define WCHAR_MIN 0
#define WCHAR_MAX &hffff

#ifndef WEOF
#define	WEOF cast(wchar_t,&hFFFF)
#endif

type mbstate_t as integer
type _Wint_t as wchar_t

#ifndef _fsize_t
type _fsize_t as uinteger
#endif

type _wfinddata_t
	attrib as uinteger
	time_create as time_t
	time_access as time_t
	time_write as time_t
	size as _fsize_t
	name(0 to (260)-1) as wchar_t
end type

type _wfinddatai64_t
	attrib as uinteger
	time_create as time_t
	time_access as time_t
	time_write as time_t
	size as longint
	name(0 to (260)-1) as wchar_t
end type

declare function _waccess cdecl alias "_waccess" (byval as wchar_t ptr, byval as integer) as integer
declare function _wchmod cdecl alias "_wchmod" (byval as wchar_t ptr, byval as integer) as integer
declare function _wcreat cdecl alias "_wcreat" (byval as wchar_t ptr, byval as integer) as integer
declare function _wfindfirst cdecl alias "_wfindfirst" (byval as wchar_t ptr, byval as _wfinddata_t ptr) as integer
declare function _wfindnext cdecl alias "_wfindnext" (byval as integer, byval as _wfinddata_t ptr) as integer
declare function _wunlink cdecl alias "_wunlink" (byval as wchar_t ptr) as integer
declare function _wopen cdecl alias "_wopen" (byval as wchar_t ptr, byval as integer, ...) as integer
declare function _wsopen cdecl alias "_wsopen" (byval as wchar_t ptr, byval as integer, byval as integer, ...) as integer
declare function _wmktemp cdecl alias "_wmktemp" (byval as wchar_t ptr) as wchar_t ptr
declare function _wfindfirsti64 cdecl alias "_wfindfirsti64" (byval as wchar_t ptr, byval as _wfinddatai64_t ptr) as integer
declare function _wfindnexti64 cdecl alias "_wfindnexti64" (byval as integer, byval as _wfinddatai64_t ptr) as integer
declare function _wchdir cdecl alias "_wchdir" (byval as wchar_t ptr) as integer
declare function _wgetcwd cdecl alias "_wgetcwd" (byval as wchar_t ptr, byval as integer) as wchar_t ptr
declare function _wgetdcwd cdecl alias "_wgetdcwd" (byval as integer, byval as wchar_t ptr, byval as integer) as wchar_t ptr
declare function _wmkdir cdecl alias "_wmkdir" (byval as wchar_t ptr) as integer
declare function _wrmdir cdecl alias "_wrmdir" (byval as wchar_t ptr) as integer

#ifndef stat
type _stat
	st_dev as _dev_t
	st_ino as _ino_t
	st_mode as _mode_t
	st_nlink as short
	st_uid as short
	st_gid as short
	st_rdev as _dev_t
	st_size as _off_t
	st_atime as time_t
	st_mtime as time_t
	st_ctime as time_t
end type

type stat as _stat

type _stati64
	st_dev as _dev_t
	st_ino as _ino_t
	st_mode as ushort
	st_nlink as short
	st_uid as short
	st_gid as short
	st_rdev as _dev_t
	st_size as longint
	st_atime as time_t
	st_mtime as time_t
	st_ctime as time_t
end type
#endif

declare function _wstat cdecl alias "_wstat" (byval as wchar_t ptr, byval as _stat ptr) as integer
declare function _wstati64 cdecl alias "_wstati64" (byval as wchar_t ptr, byval as _stati64 ptr) as integer
declare function _wasctime cdecl alias "_wasctime" (byval as tm ptr) as wchar_t ptr
declare function _wctime cdecl alias "_wctime" (byval as time_t ptr) as wchar_t ptr
declare function _wstrdate cdecl alias "_wstrdate" (byval as wchar_t ptr) as wchar_t ptr
declare function _wstrtime cdecl alias "_wstrtime" (byval as wchar_t ptr) as wchar_t ptr
declare function _wsetlocale cdecl alias "_wsetlocale" (byval as integer, byval as wchar_t ptr) as wchar_t ptr

#endif