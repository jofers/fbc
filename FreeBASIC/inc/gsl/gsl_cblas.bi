''
''
'' gsl_cblas -- header translated with help of SWIG FB wrapper
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
''
''
#ifndef __gsl_cblas_bi__
#define __gsl_cblas_bi__

#ifdef __FB_LINUX__
# inclib "gslcblas"
#endif

#include once "gsl/gsl_types.bi"

enum CBLAS_ORDER
	CblasRowMajor = 101
	CblasColMajor = 102
end enum

enum CBLAS_TRANSPOSE
	CblasNoTrans = 111
	CblasTrans = 112
	CblasConjTrans = 113
end enum

enum CBLAS_UPLO
	CblasUpper = 121
	CblasLower = 122
end enum

enum CBLAS_DIAG
	CblasNonUnit = 131
	CblasUnit = 132
end enum

enum CBLAS_SIDE
	CblasLeft = 141
	CblasRight = 142
end enum

declare function cblas_sdsdot cdecl alias "cblas_sdsdot" (byval N as integer, byval alpha as single, byval X as single ptr, byval incX as integer, byval Y as single ptr, byval incY as integer) as single
declare function cblas_dsdot cdecl alias "cblas_dsdot" (byval N as integer, byval X as single ptr, byval incX as integer, byval Y as single ptr, byval incY as integer) as double
declare function cblas_sdot cdecl alias "cblas_sdot" (byval N as integer, byval X as single ptr, byval incX as integer, byval Y as single ptr, byval incY as integer) as single
declare function cblas_ddot cdecl alias "cblas_ddot" (byval N as integer, byval X as double ptr, byval incX as integer, byval Y as double ptr, byval incY as integer) as double
declare sub cblas_cdotu_sub cdecl alias "cblas_cdotu_sub" (byval N as integer, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval dotu as any ptr)
declare sub cblas_cdotc_sub cdecl alias "cblas_cdotc_sub" (byval N as integer, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval dotc as any ptr)
declare sub cblas_zdotu_sub cdecl alias "cblas_zdotu_sub" (byval N as integer, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval dotu as any ptr)
declare sub cblas_zdotc_sub cdecl alias "cblas_zdotc_sub" (byval N as integer, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval dotc as any ptr)
declare function cblas_snrm2 cdecl alias "cblas_snrm2" (byval N as integer, byval X as single ptr, byval incX as integer) as single
declare function cblas_sasum cdecl alias "cblas_sasum" (byval N as integer, byval X as single ptr, byval incX as integer) as single
declare function cblas_dnrm2 cdecl alias "cblas_dnrm2" (byval N as integer, byval X as double ptr, byval incX as integer) as double
declare function cblas_dasum cdecl alias "cblas_dasum" (byval N as integer, byval X as double ptr, byval incX as integer) as double
declare function cblas_scnrm2 cdecl alias "cblas_scnrm2" (byval N as integer, byval X as any ptr, byval incX as integer) as single
declare function cblas_scasum cdecl alias "cblas_scasum" (byval N as integer, byval X as any ptr, byval incX as integer) as single
declare function cblas_dznrm2 cdecl alias "cblas_dznrm2" (byval N as integer, byval X as any ptr, byval incX as integer) as double
declare function cblas_dzasum cdecl alias "cblas_dzasum" (byval N as integer, byval X as any ptr, byval incX as integer) as double
declare function cblas_isamax cdecl alias "cblas_isamax" (byval N as integer, byval X as single ptr, byval incX as integer) as integer
declare function cblas_idamax cdecl alias "cblas_idamax" (byval N as integer, byval X as double ptr, byval incX as integer) as integer
declare function cblas_icamax cdecl alias "cblas_icamax" (byval N as integer, byval X as any ptr, byval incX as integer) as integer
declare function cblas_izamax cdecl alias "cblas_izamax" (byval N as integer, byval X as any ptr, byval incX as integer) as integer
declare sub cblas_sswap cdecl alias "cblas_sswap" (byval N as integer, byval X as single ptr, byval incX as integer, byval Y as single ptr, byval incY as integer)
declare sub cblas_scopy cdecl alias "cblas_scopy" (byval N as integer, byval X as single ptr, byval incX as integer, byval Y as single ptr, byval incY as integer)
declare sub cblas_saxpy cdecl alias "cblas_saxpy" (byval N as integer, byval alpha as single, byval X as single ptr, byval incX as integer, byval Y as single ptr, byval incY as integer)
declare sub cblas_dswap cdecl alias "cblas_dswap" (byval N as integer, byval X as double ptr, byval incX as integer, byval Y as double ptr, byval incY as integer)
declare sub cblas_dcopy cdecl alias "cblas_dcopy" (byval N as integer, byval X as double ptr, byval incX as integer, byval Y as double ptr, byval incY as integer)
declare sub cblas_daxpy cdecl alias "cblas_daxpy" (byval N as integer, byval alpha as double, byval X as double ptr, byval incX as integer, byval Y as double ptr, byval incY as integer)
declare sub cblas_cswap cdecl alias "cblas_cswap" (byval N as integer, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer)
declare sub cblas_ccopy cdecl alias "cblas_ccopy" (byval N as integer, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer)
declare sub cblas_caxpy cdecl alias "cblas_caxpy" (byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer)
declare sub cblas_zswap cdecl alias "cblas_zswap" (byval N as integer, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer)
declare sub cblas_zcopy cdecl alias "cblas_zcopy" (byval N as integer, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer)
declare sub cblas_zaxpy cdecl alias "cblas_zaxpy" (byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer)
declare sub cblas_srotg cdecl alias "cblas_srotg" (byval a as single ptr, byval b as single ptr, byval c as single ptr, byval s as single ptr)
declare sub cblas_srotmg cdecl alias "cblas_srotmg" (byval d1 as single ptr, byval d2 as single ptr, byval b1 as single ptr, byval b2 as single, byval P as single ptr)
declare sub cblas_srot cdecl alias "cblas_srot" (byval N as integer, byval X as single ptr, byval incX as integer, byval Y as single ptr, byval incY as integer, byval c as single, byval s as single)
declare sub cblas_srotm cdecl alias "cblas_srotm" (byval N as integer, byval X as single ptr, byval incX as integer, byval Y as single ptr, byval incY as integer, byval P as single ptr)
declare sub cblas_drotg cdecl alias "cblas_drotg" (byval a as double ptr, byval b as double ptr, byval c as double ptr, byval s as double ptr)
declare sub cblas_drotmg cdecl alias "cblas_drotmg" (byval d1 as double ptr, byval d2 as double ptr, byval b1 as double ptr, byval b2 as double, byval P as double ptr)
declare sub cblas_drot cdecl alias "cblas_drot" (byval N as integer, byval X as double ptr, byval incX as integer, byval Y as double ptr, byval incY as integer, byval c as double, byval s as double)
declare sub cblas_drotm cdecl alias "cblas_drotm" (byval N as integer, byval X as double ptr, byval incX as integer, byval Y as double ptr, byval incY as integer, byval P as double ptr)
declare sub cblas_sscal cdecl alias "cblas_sscal" (byval N as integer, byval alpha as single, byval X as single ptr, byval incX as integer)
declare sub cblas_dscal cdecl alias "cblas_dscal" (byval N as integer, byval alpha as double, byval X as double ptr, byval incX as integer)
declare sub cblas_cscal cdecl alias "cblas_cscal" (byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer)
declare sub cblas_zscal cdecl alias "cblas_zscal" (byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer)
declare sub cblas_csscal cdecl alias "cblas_csscal" (byval N as integer, byval alpha as single, byval X as any ptr, byval incX as integer)
declare sub cblas_zdscal cdecl alias "cblas_zdscal" (byval N as integer, byval alpha as double, byval X as any ptr, byval incX as integer)
declare sub cblas_sgemv cdecl alias "cblas_sgemv" (byval order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval alpha as single, byval A as single ptr, byval lda as integer, byval X as single ptr, byval incX as integer, byval beta as single, byval Y as single ptr, byval incY as integer)
declare sub cblas_sgbmv cdecl alias "cblas_sgbmv" (byval order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval KL as integer, byval KU as integer, byval alpha as single, byval A as single ptr, byval lda as integer, byval X as single ptr, byval incX as integer, byval beta as single, byval Y as single ptr, byval incY as integer)
declare sub cblas_strmv cdecl alias "cblas_strmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval A as single ptr, byval lda as integer, byval X as single ptr, byval incX as integer)
declare sub cblas_stbmv cdecl alias "cblas_stbmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval K as integer, byval A as single ptr, byval lda as integer, byval X as single ptr, byval incX as integer)
declare sub cblas_stpmv cdecl alias "cblas_stpmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval Ap as single ptr, byval X as single ptr, byval incX as integer)
declare sub cblas_strsv cdecl alias "cblas_strsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval A as single ptr, byval lda as integer, byval X as single ptr, byval incX as integer)
declare sub cblas_stbsv cdecl alias "cblas_stbsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval K as integer, byval A as single ptr, byval lda as integer, byval X as single ptr, byval incX as integer)
declare sub cblas_stpsv cdecl alias "cblas_stpsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval Ap as single ptr, byval X as single ptr, byval incX as integer)
declare sub cblas_dgemv cdecl alias "cblas_dgemv" (byval order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval alpha as double, byval A as double ptr, byval lda as integer, byval X as double ptr, byval incX as integer, byval beta as double, byval Y as double ptr, byval incY as integer)
declare sub cblas_dgbmv cdecl alias "cblas_dgbmv" (byval order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval KL as integer, byval KU as integer, byval alpha as double, byval A as double ptr, byval lda as integer, byval X as double ptr, byval incX as integer, byval beta as double, byval Y as double ptr, byval incY as integer)
declare sub cblas_dtrmv cdecl alias "cblas_dtrmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval A as double ptr, byval lda as integer, byval X as double ptr, byval incX as integer)
declare sub cblas_dtbmv cdecl alias "cblas_dtbmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval K as integer, byval A as double ptr, byval lda as integer, byval X as double ptr, byval incX as integer)
declare sub cblas_dtpmv cdecl alias "cblas_dtpmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval Ap as double ptr, byval X as double ptr, byval incX as integer)
declare sub cblas_dtrsv cdecl alias "cblas_dtrsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval A as double ptr, byval lda as integer, byval X as double ptr, byval incX as integer)
declare sub cblas_dtbsv cdecl alias "cblas_dtbsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval K as integer, byval A as double ptr, byval lda as integer, byval X as double ptr, byval incX as integer)
declare sub cblas_dtpsv cdecl alias "cblas_dtpsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval Ap as double ptr, byval X as double ptr, byval incX as integer)
declare sub cblas_cgemv cdecl alias "cblas_cgemv" (byval order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer, byval beta as any ptr, byval Y as any ptr, byval incY as integer)
declare sub cblas_cgbmv cdecl alias "cblas_cgbmv" (byval order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval KL as integer, byval KU as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer, byval beta as any ptr, byval Y as any ptr, byval incY as integer)
declare sub cblas_ctrmv cdecl alias "cblas_ctrmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer)
declare sub cblas_ctbmv cdecl alias "cblas_ctbmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval K as integer, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer)
declare sub cblas_ctpmv cdecl alias "cblas_ctpmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval Ap as any ptr, byval X as any ptr, byval incX as integer)
declare sub cblas_ctrsv cdecl alias "cblas_ctrsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer)
declare sub cblas_ctbsv cdecl alias "cblas_ctbsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval K as integer, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer)
declare sub cblas_ctpsv cdecl alias "cblas_ctpsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval Ap as any ptr, byval X as any ptr, byval incX as integer)
declare sub cblas_zgemv cdecl alias "cblas_zgemv" (byval order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer, byval beta as any ptr, byval Y as any ptr, byval incY as integer)
declare sub cblas_zgbmv cdecl alias "cblas_zgbmv" (byval order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval KL as integer, byval KU as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer, byval beta as any ptr, byval Y as any ptr, byval incY as integer)
declare sub cblas_ztrmv cdecl alias "cblas_ztrmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer)
declare sub cblas_ztbmv cdecl alias "cblas_ztbmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval K as integer, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer)
declare sub cblas_ztpmv cdecl alias "cblas_ztpmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval Ap as any ptr, byval X as any ptr, byval incX as integer)
declare sub cblas_ztrsv cdecl alias "cblas_ztrsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer)
declare sub cblas_ztbsv cdecl alias "cblas_ztbsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval K as integer, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer)
declare sub cblas_ztpsv cdecl alias "cblas_ztpsv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval N as integer, byval Ap as any ptr, byval X as any ptr, byval incX as integer)
declare sub cblas_ssymv cdecl alias "cblas_ssymv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as single, byval A as single ptr, byval lda as integer, byval X as single ptr, byval incX as integer, byval beta as single, byval Y as single ptr, byval incY as integer)
declare sub cblas_ssbmv cdecl alias "cblas_ssbmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval K as integer, byval alpha as single, byval A as single ptr, byval lda as integer, byval X as single ptr, byval incX as integer, byval beta as single, byval Y as single ptr, byval incY as integer)
declare sub cblas_sspmv cdecl alias "cblas_sspmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as single, byval Ap as single ptr, byval X as single ptr, byval incX as integer, byval beta as single, byval Y as single ptr, byval incY as integer)
declare sub cblas_sger cdecl alias "cblas_sger" (byval order as CBLAS_ORDER, byval M as integer, byval N as integer, byval alpha as single, byval X as single ptr, byval incX as integer, byval Y as single ptr, byval incY as integer, byval A as single ptr, byval lda as integer)
declare sub cblas_ssyr cdecl alias "cblas_ssyr" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as single, byval X as single ptr, byval incX as integer, byval A as single ptr, byval lda as integer)
declare sub cblas_sspr cdecl alias "cblas_sspr" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as single, byval X as single ptr, byval incX as integer, byval Ap as single ptr)
declare sub cblas_ssyr2 cdecl alias "cblas_ssyr2" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as single, byval X as single ptr, byval incX as integer, byval Y as single ptr, byval incY as integer, byval A as single ptr, byval lda as integer)
declare sub cblas_sspr2 cdecl alias "cblas_sspr2" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as single, byval X as single ptr, byval incX as integer, byval Y as single ptr, byval incY as integer, byval A as single ptr)
declare sub cblas_dsymv cdecl alias "cblas_dsymv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as double, byval A as double ptr, byval lda as integer, byval X as double ptr, byval incX as integer, byval beta as double, byval Y as double ptr, byval incY as integer)
declare sub cblas_dsbmv cdecl alias "cblas_dsbmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval K as integer, byval alpha as double, byval A as double ptr, byval lda as integer, byval X as double ptr, byval incX as integer, byval beta as double, byval Y as double ptr, byval incY as integer)
declare sub cblas_dspmv cdecl alias "cblas_dspmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as double, byval Ap as double ptr, byval X as double ptr, byval incX as integer, byval beta as double, byval Y as double ptr, byval incY as integer)
declare sub cblas_dger cdecl alias "cblas_dger" (byval order as CBLAS_ORDER, byval M as integer, byval N as integer, byval alpha as double, byval X as double ptr, byval incX as integer, byval Y as double ptr, byval incY as integer, byval A as double ptr, byval lda as integer)
declare sub cblas_dsyr cdecl alias "cblas_dsyr" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as double, byval X as double ptr, byval incX as integer, byval A as double ptr, byval lda as integer)
declare sub cblas_dspr cdecl alias "cblas_dspr" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as double, byval X as double ptr, byval incX as integer, byval Ap as double ptr)
declare sub cblas_dsyr2 cdecl alias "cblas_dsyr2" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as double, byval X as double ptr, byval incX as integer, byval Y as double ptr, byval incY as integer, byval A as double ptr, byval lda as integer)
declare sub cblas_dspr2 cdecl alias "cblas_dspr2" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as double, byval X as double ptr, byval incX as integer, byval Y as double ptr, byval incY as integer, byval A as double ptr)
declare sub cblas_chemv cdecl alias "cblas_chemv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer, byval beta as any ptr, byval Y as any ptr, byval incY as integer)
declare sub cblas_chbmv cdecl alias "cblas_chbmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval K as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer, byval beta as any ptr, byval Y as any ptr, byval incY as integer)
declare sub cblas_chpmv cdecl alias "cblas_chpmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as any ptr, byval Ap as any ptr, byval X as any ptr, byval incX as integer, byval beta as any ptr, byval Y as any ptr, byval incY as integer)
declare sub cblas_cgeru cdecl alias "cblas_cgeru" (byval order as CBLAS_ORDER, byval M as integer, byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval A as any ptr, byval lda as integer)
declare sub cblas_cgerc cdecl alias "cblas_cgerc" (byval order as CBLAS_ORDER, byval M as integer, byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval A as any ptr, byval lda as integer)
declare sub cblas_cher cdecl alias "cblas_cher" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as single, byval X as any ptr, byval incX as integer, byval A as any ptr, byval lda as integer)
declare sub cblas_chpr cdecl alias "cblas_chpr" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as single, byval X as any ptr, byval incX as integer, byval A as any ptr)
declare sub cblas_cher2 cdecl alias "cblas_cher2" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval A as any ptr, byval lda as integer)
declare sub cblas_chpr2 cdecl alias "cblas_chpr2" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval Ap as any ptr)
declare sub cblas_zhemv cdecl alias "cblas_zhemv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer, byval beta as any ptr, byval Y as any ptr, byval incY as integer)
declare sub cblas_zhbmv cdecl alias "cblas_zhbmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval K as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval X as any ptr, byval incX as integer, byval beta as any ptr, byval Y as any ptr, byval incY as integer)
declare sub cblas_zhpmv cdecl alias "cblas_zhpmv" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as any ptr, byval Ap as any ptr, byval X as any ptr, byval incX as integer, byval beta as any ptr, byval Y as any ptr, byval incY as integer)
declare sub cblas_zgeru cdecl alias "cblas_zgeru" (byval order as CBLAS_ORDER, byval M as integer, byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval A as any ptr, byval lda as integer)
declare sub cblas_zgerc cdecl alias "cblas_zgerc" (byval order as CBLAS_ORDER, byval M as integer, byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval A as any ptr, byval lda as integer)
declare sub cblas_zher cdecl alias "cblas_zher" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as double, byval X as any ptr, byval incX as integer, byval A as any ptr, byval lda as integer)
declare sub cblas_zhpr cdecl alias "cblas_zhpr" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as double, byval X as any ptr, byval incX as integer, byval A as any ptr)
declare sub cblas_zher2 cdecl alias "cblas_zher2" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval A as any ptr, byval lda as integer)
declare sub cblas_zhpr2 cdecl alias "cblas_zhpr2" (byval order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval N as integer, byval alpha as any ptr, byval X as any ptr, byval incX as integer, byval Y as any ptr, byval incY as integer, byval Ap as any ptr)
declare sub cblas_sgemm cdecl alias "cblas_sgemm" (byval Order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval TransB as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval K as integer, byval alpha as single, byval A as single ptr, byval lda as integer, byval B as single ptr, byval ldb as integer, byval beta as single, byval C as single ptr, byval ldc as integer)
declare sub cblas_ssymm cdecl alias "cblas_ssymm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval M as integer, byval N as integer, byval alpha as single, byval A as single ptr, byval lda as integer, byval B as single ptr, byval ldb as integer, byval beta as single, byval C as single ptr, byval ldc as integer)
declare sub cblas_ssyrk cdecl alias "cblas_ssyrk" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as single, byval A as single ptr, byval lda as integer, byval beta as single, byval C as single ptr, byval ldc as integer)
declare sub cblas_ssyr2k cdecl alias "cblas_ssyr2k" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as single, byval A as single ptr, byval lda as integer, byval B as single ptr, byval ldb as integer, byval beta as single, byval C as single ptr, byval ldc as integer)
declare sub cblas_strmm cdecl alias "cblas_strmm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval M as integer, byval N as integer, byval alpha as single, byval A as single ptr, byval lda as integer, byval B as single ptr, byval ldb as integer)
declare sub cblas_strsm cdecl alias "cblas_strsm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval M as integer, byval N as integer, byval alpha as single, byval A as single ptr, byval lda as integer, byval B as single ptr, byval ldb as integer)
declare sub cblas_dgemm cdecl alias "cblas_dgemm" (byval Order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval TransB as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval K as integer, byval alpha as double, byval A as double ptr, byval lda as integer, byval B as double ptr, byval ldb as integer, byval beta as double, byval C as double ptr, byval ldc as integer)
declare sub cblas_dsymm cdecl alias "cblas_dsymm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval M as integer, byval N as integer, byval alpha as double, byval A as double ptr, byval lda as integer, byval B as double ptr, byval ldb as integer, byval beta as double, byval C as double ptr, byval ldc as integer)
declare sub cblas_dsyrk cdecl alias "cblas_dsyrk" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as double, byval A as double ptr, byval lda as integer, byval beta as double, byval C as double ptr, byval ldc as integer)
declare sub cblas_dsyr2k cdecl alias "cblas_dsyr2k" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as double, byval A as double ptr, byval lda as integer, byval B as double ptr, byval ldb as integer, byval beta as double, byval C as double ptr, byval ldc as integer)
declare sub cblas_dtrmm cdecl alias "cblas_dtrmm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval M as integer, byval N as integer, byval alpha as double, byval A as double ptr, byval lda as integer, byval B as double ptr, byval ldb as integer)
declare sub cblas_dtrsm cdecl alias "cblas_dtrsm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval M as integer, byval N as integer, byval alpha as double, byval A as double ptr, byval lda as integer, byval B as double ptr, byval ldb as integer)
declare sub cblas_cgemm cdecl alias "cblas_cgemm" (byval Order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval TransB as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval K as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer, byval beta as any ptr, byval C as any ptr, byval ldc as integer)
declare sub cblas_csymm cdecl alias "cblas_csymm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval M as integer, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer, byval beta as any ptr, byval C as any ptr, byval ldc as integer)
declare sub cblas_csyrk cdecl alias "cblas_csyrk" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval beta as any ptr, byval C as any ptr, byval ldc as integer)
declare sub cblas_csyr2k cdecl alias "cblas_csyr2k" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer, byval beta as any ptr, byval C as any ptr, byval ldc as integer)
declare sub cblas_ctrmm cdecl alias "cblas_ctrmm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval M as integer, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer)
declare sub cblas_ctrsm cdecl alias "cblas_ctrsm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval M as integer, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer)
declare sub cblas_zgemm cdecl alias "cblas_zgemm" (byval Order as CBLAS_ORDER, byval TransA as CBLAS_TRANSPOSE, byval TransB as CBLAS_TRANSPOSE, byval M as integer, byval N as integer, byval K as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer, byval beta as any ptr, byval C as any ptr, byval ldc as integer)
declare sub cblas_zsymm cdecl alias "cblas_zsymm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval M as integer, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer, byval beta as any ptr, byval C as any ptr, byval ldc as integer)
declare sub cblas_zsyrk cdecl alias "cblas_zsyrk" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval beta as any ptr, byval C as any ptr, byval ldc as integer)
declare sub cblas_zsyr2k cdecl alias "cblas_zsyr2k" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer, byval beta as any ptr, byval C as any ptr, byval ldc as integer)
declare sub cblas_ztrmm cdecl alias "cblas_ztrmm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval M as integer, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer)
declare sub cblas_ztrsm cdecl alias "cblas_ztrsm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval TransA as CBLAS_TRANSPOSE, byval Diag as CBLAS_DIAG, byval M as integer, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer)
declare sub cblas_chemm cdecl alias "cblas_chemm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval M as integer, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer, byval beta as any ptr, byval C as any ptr, byval ldc as integer)
declare sub cblas_cherk cdecl alias "cblas_cherk" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as single, byval A as any ptr, byval lda as integer, byval beta as single, byval C as any ptr, byval ldc as integer)
declare sub cblas_cher2k cdecl alias "cblas_cher2k" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer, byval beta as single, byval C as any ptr, byval ldc as integer)
declare sub cblas_zhemm cdecl alias "cblas_zhemm" (byval Order as CBLAS_ORDER, byval Side as CBLAS_SIDE, byval Uplo as CBLAS_UPLO, byval M as integer, byval N as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer, byval beta as any ptr, byval C as any ptr, byval ldc as integer)
declare sub cblas_zherk cdecl alias "cblas_zherk" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as double, byval A as any ptr, byval lda as integer, byval beta as double, byval C as any ptr, byval ldc as integer)
declare sub cblas_zher2k cdecl alias "cblas_zher2k" (byval Order as CBLAS_ORDER, byval Uplo as CBLAS_UPLO, byval Trans as CBLAS_TRANSPOSE, byval N as integer, byval K as integer, byval alpha as any ptr, byval A as any ptr, byval lda as integer, byval B as any ptr, byval ldb as integer, byval beta as double, byval C as any ptr, byval ldc as integer)
declare sub cblas_xerbla cdecl alias "cblas_xerbla" (byval p as integer, byval rout as zstring ptr, byval form as zstring ptr, ...)

#endif