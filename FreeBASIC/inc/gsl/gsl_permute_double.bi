''
''
'' gsl_permute_double -- header translated with help of SWIG FB wrapper
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
''
''
#ifndef __gsl_permute_double_bi__
#define __gsl_permute_double_bi__

#include once "gsl/gsl_errno.bi"
#include once "gsl/gsl_permutation.bi"
#include once "gsl/gsl_types.bi"

declare function gsl_permute cdecl alias "gsl_permute" (byval p as integer ptr, byval data as double ptr, byval stride as integer, byval n as integer) as integer
declare function gsl_permute_inverse cdecl alias "gsl_permute_inverse" (byval p as integer ptr, byval data as double ptr, byval stride as integer, byval n as integer) as integer

#endif