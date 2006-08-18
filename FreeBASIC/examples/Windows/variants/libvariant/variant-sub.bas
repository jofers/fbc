

#define VARIANT_NOASSIGNMENT
#include once "variant.bi"
#include once "intern.bi"

VAR_GEN_BOP( -, VarSub, integer, I4 )
VAR_GEN_BOP( -, VarSub, uinteger, UI4 )
VAR_GEN_BOP( -, VarSub, longint, I8 )
VAR_GEN_BOP( -, VarSub, ulongint, UI8 )
VAR_GEN_BOP( -, VarSub, single, R4 )
VAR_GEN_BOP( -, VarSub, double, R8 )

'':::::
operator - _
	( _
		byref lhs as VARIANT, _
		byref rhs as VARIANT _
	) as VARIANT
	
	dim as VARIANT res = any
	
	VarSub( @lhs, @rhs, @res )
	
	operator = res
	
end operator
