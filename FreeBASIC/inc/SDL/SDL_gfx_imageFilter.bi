''
'' 
'' SDL_imageFilter - bytes-image "filter" routines 
'' (uses inline x86 MMX optimizations if available)
'' 
'' LGPL (c) A. Schiffler
''
''

#ifndef SDL_imageFilter_h
#define SDL_imageFilter_h

#inclib "SDL_gfx"

#include once "SDL/SDL.bi"

'' Comments:                                                                          
''  1.) MMX functions work best if all data blocks are aligned on a 32 bytes boundary.
''  2.) Data that is not within an 8 byte boundary is processed using the C routine.  
''  3.) Convolution routines do not have C routines at this time.                     

'' Detect MMX capability in CPU
    declare function SDL_imageFilterMMXdetect cdecl alias "SDL_imageFilterMMXdetect" () as integer

'' Force use of MMX off (or turn possible use back on)
    declare sub SDL_imageFilterMMXoff cdecl alias "SDL_imageFilterMMXoff" ()
    declare sub SDL_imageFilterMMXon cdecl alias "SDL_imageFilterMMXon" ()

''
'' All routines return:
''   0   OK
''  -1   Error (internal error, parameter error)
''

''  SDL_imageFilterAdd: D = saturation255(S1 + S2)
    declare function SDL_imageFilterAdd cdecl alias "SDL_imageFilterAdd" (byval Src1 as ubyte ptr, byval Src2 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer) as integer

''  SDL_imageFilterMean: D = S1/2 + S2/2
    declare function SDL_imageFilterMean cdecl alias "SDL_imageFilterMean" (byval Src1 as ubyte ptr, byval Src2 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer) as integer

''  SDL_imageFilterSub: D = saturation0(S1 - S2)
    declare function SDL_imageFilterSub cdecl alias "SDL_imageFilterSub" (byval Src1 as ubyte ptr, byval Src2 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer) as integer

''  SDL_imageFilterAbsDiff: D = | S1 - S2 |
    declare function SDL_imageFilterAbsDiff cdecl alias "SDL_imageFilterAbsDiff" (byval Src1 as ubyte ptr, byval Src2 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer) as integer

''  SDL_imageFilterMult: D = saturation(S1 * S2)
    declare function SDL_imageFilterMult cdecl alias "SDL_imageFilterMult" (byval Src1 as ubyte ptr, byval Src2 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer) as integer

''  SDL_imageFilterMultNor: D = S1 * S2   (non-MMX)
    declare function SDL_imageFilterMultNor cdecl alias "SDL_imageFilterMultNor" (byval Src1 as ubyte ptr, byval Src2 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer) as integer

''  SDL_imageFilterMultDivby2: D = saturation255(S1/2 * S2)
    declare function SDL_imageFilterMultDivby2 cdecl alias "SDL_imageFilterMultDivby2" (byval Src1 as ubyte ptr, byval Src2 as ubyte ptr, byval Dest as ubyte ptr, _
					       byval length as integer) as integer

''  SDL_imageFilterMultDivby4: D = saturation255(S1/2 * S2/2)
    declare function SDL_imageFilterMultDivby4 cdecl alias "SDL_imageFilterMultDivby4" (byval Src1 as ubyte ptr, byval Src2 as ubyte ptr, byval Dest as ubyte ptr, _
					       byval length as integer) as integer

''  SDL_imageFilterBitAnd: D = S1 & S2
    declare function SDL_imageFilterBitAnd cdecl alias "SDL_imageFilterBitAnd" (byval Src1 as ubyte ptr, byval Src2 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer) as integer

''  SDL_imageFilterBitOr: D = S1 | S2
    declare function SDL_imageFilterBitOr cdecl alias "SDL_imageFilterBitOr" (byval Src1 as ubyte ptr, byval Src2 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer) as integer

''  SDL_imageFilterDiv: D = S1 / S2   (non-MMX)
    declare function SDL_imageFilterDiv cdecl alias "SDL_imageFilterDiv" (byval Src1 as ubyte ptr, byval Src2 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer) as integer

''  SDL_imageFilterBitNegation: D = !S
    declare function SDL_imageFilterBitNegation cdecl alias "SDL_imageFilterBitNegation" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer) as integer

''  SDL_imageFilterAddByte: D = saturation255(S + C)
    declare function SDL_imageFilterAddByte cdecl alias "SDL_imageFilterAddByte" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, byval C as ubyte) as integer

''  SDL_imageFilterAddUint: D = saturation255(S + (uint)C)
    declare function SDL_imageFilterAddUint cdecl alias "SDL_imageFilterAddUint" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, byval C as uinteger) as integer

''  SDL_imageFilterAddByteToHalf: D = saturation255(S/2 + C)
    declare function SDL_imageFilterAddByteToHalf cdecl alias "SDL_imageFilterAddByteToHalf" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, _
						  byval C as ubyte) as integer

''  SDL_imageFilterSubByte: D = saturation0(S - C)
    declare function SDL_imageFilterSubByte cdecl alias "SDL_imageFilterSubByte" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, byval C as ubyte) as integer

''  SDL_imageFilterSubUint: D = saturation0(S - (uint)C)
    declare function SDL_imageFilterSubUint cdecl alias "SDL_imageFilterSubUint" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, byval C as uinteger) as integer

''  SDL_imageFilterShiftRight: D = saturation0(S >> N)
    declare function SDL_imageFilterShiftRight cdecl alias "SDL_imageFilterShiftRight" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, byval N as ubyte) as integer

''  SDL_imageFilterShiftRightUint: D = saturation0((uint)S >> N)
    declare function SDL_imageFilterShiftRightUint cdecl alias "SDL_imageFilterShiftRightUint" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, byval N as ubyte) as integer

''  SDL_imageFilterMultByByte: D = saturation255(S * C)
    declare function SDL_imageFilterMultByByte cdecl alias "SDL_imageFilterMultByByte" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, byval C as ubyte) as integer

''  SDL_imageFilterShiftRightAndMultByByte: D = saturation255((S >> N) * C)
    declare function SDL_imageFilterShiftRightAndMultByByte cdecl alias "SDL_imageFilterShiftRightAndMultByByte" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, _
							    byval N as ubyte, byval C as ubyte) as integer

''  SDL_imageFilterShiftLeftByte: D = (S << N)
    declare function SDL_imageFilterShiftLeftByte cdecl alias "SDL_imageFilterShiftLeftByte" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, _
						  byval N as ubyte) as integer

''  SDL_imageFilterShiftLeftUint: D = ((uint)S << N)
    declare function SDL_imageFilterShiftLeftUint cdecl alias "SDL_imageFilterShiftLeftUint" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, _
						  byval N as ubyte) as integer

''  SDL_imageFilterShiftLeft: D = saturation255(S << N)
    declare function SDL_imageFilterShiftLeft cdecl alias "SDL_imageFilterShiftLeft" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, byval N as ubyte) as integer

''  SDL_imageFilterBinarizeUsingThreshold: D = S >= T ? 255:0
    declare function SDL_imageFilterBinarizeUsingThreshold cdecl alias "SDL_imageFilterBinarizeUsingThreshold" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, _
							   byval T as ubyte) as integer

''  SDL_imageFilterClipToRange: D = (S >= Tmin) & (S <= Tmax) 255:0
    declare function SDL_imageFilterClipToRange cdecl alias "SDL_imageFilterClipToRange" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, _
						byval Tmin as ubyte, byval Tmax as ubyte) as integer

''  SDL_imageFilterNormalizeLinear: D = saturation255((Nmax - Nmin)/(Cmax - Cmin)*(S - Cmin) + Nmin)
    declare function SDL_imageFilterNormalizeLinear cdecl alias "SDL_imageFilterNormalizeLinear" (byval Src1 as ubyte ptr, byval Dest as ubyte ptr, byval length as integer, byval Cmin as integer, _
	 byval Cmax as integer, byval Nmin as integer, byval Nmax as integer) as integer

'' !!! NO C-ROUTINE FOR THESE FUNCTIONS YET !!!

''  SDL_imageFilterConvolveKernel3x3Divide: Dij = saturation0and255( ... )
    declare function SDL_imageFilterConvolveKernel3x3Divide cdecl alias "SDL_imageFilterConvolveKernel3x3Divide" (byval Src as ubyte ptr, byval Dest as ubyte ptr, byval rows as integer, _
	 byval columns as integer, byval Kernel as short ptr, byval Divisor as ubyte) as integer

''  SDL_imageFilterConvolveKernel5x5Divide: Dij = saturation0and255( ... )
    declare function SDL_imageFilterConvolveKernel5x5Divide cdecl alias "SDL_imageFilterConvolveKernel5x5Divide" (byval Src as ubyte ptr, byval Dest as ubyte ptr, byval rows as integer, _
	 byval columns as integer, byval Kernel as short ptr, byval Divisor as ubyte) as integer

''  SDL_imageFilterConvolveKernel7x7Divide: Dij = saturation0and255( ... )
    declare function SDL_imageFilterConvolveKernel7x7Divide cdecl alias "SDL_imageFilterConvolveKernel7x7Divide" (byval Src as ubyte ptr, byval Dest as ubyte ptr, byval rows as integer, _
	 byval columns as integer, byval Kernel as short ptr, byval Divisor as ubyte) as integer

''  SDL_imageFilterConvolveKernel9x9Divide: Dij = saturation0and255( ... )
    declare function SDL_imageFilterConvolveKernel9x9Divide cdecl alias "SDL_imageFilterConvolveKernel9x9Divide" (byval Src as ubyte ptr, byval Dest as ubyte ptr, byval rows as integer, _
	 byval columns as integer, byval Kernel as short ptr, byval Divisor as ubyte) as integer

''  SDL_imageFilterConvolveKernel3x3ShiftRight: Dij = saturation0and255( ... )
    declare function SDL_imageFilterConvolveKernel3x3ShiftRight cdecl alias "SDL_imageFilterConvolveKernel3x3ShiftRight" (byval Src as ubyte ptr, byval Dest as ubyte ptr, byval rows as integer, _
	 byval columns as integer, byval Kernel as short ptr, _
								byval NRightShift as ubyte) as integer

''  SDL_imageFilterConvolveKernel5x5ShiftRight: Dij = saturation0and255( ... )
    declare function SDL_imageFilterConvolveKernel5x5ShiftRight cdecl alias "SDL_imageFilterConvolveKernel5x5ShiftRight" (byval Src as ubyte ptr, byval Dest as ubyte ptr, byval rows as integer, _
	 byval columns as integer, byval Kernel as short ptr, _
								byval NRightShift as ubyte) as integer

''  SDL_imageFilterConvolveKernel7x7ShiftRight: Dij = saturation0and255( ... )
    declare function SDL_imageFilterConvolveKernel7x7ShiftRight cdecl alias "SDL_imageFilterConvolveKernel7x7ShiftRight" (byval Src as ubyte ptr, byval Dest as ubyte ptr, byval rows as integer, _
	 byval columns as integer, byval Kernel as short ptr, _
								byval NRightShift as ubyte) as integer

''  SDL_imageFilterConvolveKernel9x9ShiftRight: Dij = saturation0and255( ... )
    declare function SDL_imageFilterConvolveKernel9x9ShiftRight cdecl alias "SDL_imageFilterConvolveKernel9x9ShiftRight" (byval Src as ubyte ptr, byval Dest as ubyte ptr, byval rows as integer, _
	 byval columns as integer, byval Kernel as short ptr, _
								byval NRightShift as ubyte) as integer

''  SDL_imageFilterSobelX: Dij = saturation255( ... )
    declare function SDL_imageFilterSobelX cdecl alias "SDL_imageFilterSobelX" (byval Src as ubyte ptr, byval Dest as ubyte ptr, byval rows as integer, byval columns as integer) as integer

''  SDL_imageFilterSobelXShiftRight: Dij = saturation255( ... )
    declare function SDL_imageFilterSobelXShiftRight cdecl alias "SDL_imageFilterSobelXShiftRight" (byval Src as ubyte ptr, byval Dest as ubyte ptr, byval rows as integer, byval columns as integer, _
						     byval NRightShift as ubyte) as integer

'' Align/restore stack to 32 byte boundary -- Functionality untested! --
    declare sub SDL_imageFilterAlignStack cdecl alias "SDL_imageFilterAlignStack" ()
    declare sub SDL_imageFilterRestoreStack cdecl alias "SDL_imageFilterRestoreStack" ()


#endif				'' _SDL_imageFilter_h