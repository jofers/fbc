''
''
'' gsl_sf_lambert -- header translated with help of SWIG FB wrapper
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
''
''
#ifndef __gsl_sf_lambert_bi__
#define __gsl_sf_lambert_bi__

#include once "gsl/gsl_sf_result.bi"
#include once "gsl/gsl_types.bi"

declare function gsl_sf_lambert_W0_e cdecl alias "gsl_sf_lambert_W0_e" (byval x as double, byval result as gsl_sf_result ptr) as integer
declare function gsl_sf_lambert_W0 cdecl alias "gsl_sf_lambert_W0" (byval x as double) as double
declare function gsl_sf_lambert_Wm1_e cdecl alias "gsl_sf_lambert_Wm1_e" (byval x as double, byval result as gsl_sf_result ptr) as integer
declare function gsl_sf_lambert_Wm1 cdecl alias "gsl_sf_lambert_Wm1" (byval x as double) as double

#endif