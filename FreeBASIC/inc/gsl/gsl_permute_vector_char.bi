''
''
'' gsl_permute_vector_char -- header translated with help of SWIG FB wrapper
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
''
''
#ifndef __gsl_permute_vector_char_bi__
#define __gsl_permute_vector_char_bi__

#include once "gsl/gsl_errno.bi"
#include once "gsl/gsl_permutation.bi"
#include once "gsl/gsl_vector_char.bi"
#include once "gsl/gsl_types.bi"

declare function gsl_permute_vector_char cdecl alias "gsl_permute_vector_char" (byval p as gsl_permutation ptr, byval v as gsl_vector_char ptr) as integer
declare function gsl_permute_vector_char_inverse cdecl alias "gsl_permute_vector_char_inverse" (byval p as gsl_permutation ptr, byval v as gsl_vector_char ptr) as integer

#endif