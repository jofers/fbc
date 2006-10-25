''
''
'' lualib -- header translated with help of SWIG FB wrapper
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
''
''
#ifndef __lua_lualib_bi__
#define __lua_lualib_bi__

#include once "Lua/lua.bi"

#define LUA_FILEHANDLE "FILE*"
#define LUA_COLIBNAME "coroutine"

declare function luaopen_base cdecl alias "luaopen_base" (byval L as lua_State ptr) as integer

#define LUA_TABLIBNAME "table"

declare function luaopen_table cdecl alias "luaopen_table" (byval L as lua_State ptr) as integer

#define LUA_IOLIBNAME "io"

declare function luaopen_io cdecl alias "luaopen_io" (byval L as lua_State ptr) as integer

#define LUA_OSLIBNAME "os"

declare function luaopen_os cdecl alias "luaopen_os" (byval L as lua_State ptr) as integer

#define LUA_STRLIBNAME "string"

declare function luaopen_string cdecl alias "luaopen_string" (byval L as lua_State ptr) as integer

#define LUA_MATHLIBNAME "math"

declare function luaopen_math cdecl alias "luaopen_math" (byval L as lua_State ptr) as integer

#define LUA_DBLIBNAME "debug"

declare function luaopen_debug cdecl alias "luaopen_debug" (byval L as lua_State ptr) as integer

#define LUA_LOADLIBNAME "package"

declare function luaopen_package cdecl alias "luaopen_package" (byval L as lua_State ptr) as integer
declare sub luaL_openlibs cdecl alias "luaL_openlibs" (byval L as lua_State ptr)

#ifndef lua_assert
#define lua_assert(x)
#endif

#endif