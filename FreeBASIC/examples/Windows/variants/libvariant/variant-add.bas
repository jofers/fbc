

#define VARIANT_NOASSIGNMENT
#include once "variant.bi"
#include once "intern.bi"

VAR_GEN_BOP( +, VarAdd, integer, I4 )
VAR_GEN_BOP( +, VarAdd, uinteger, UI4 )
VAR_GEN_BOP( +, VarAdd, longint, I8 )
VAR_GEN_BOP( +, VarAdd, ulongint, UI8 )
VAR_GEN_BOP( +, VarAdd, single, R4 )
VAR_GEN_BOP( +, VarAdd, double, R8 )

'':::::
operator + _
	( _
		byref lhs as CVariant, _
		byref rhs as CVariant _
	) as CVariant
	
	dim as VARIANT res = any
	
	VarAdd( @lhs.var, @rhs.var, @res )
	
	return CVariant( res, FALSE )
	
end operator

'':::::
operator + _
	( _
		byref lhs as CVariant, _
		byref rhs as VARIANT _
	) as CVariant
	
	dim as VARIANT res = any
	
	VarAdd( @lhs.var, @rhs, @res )
	
	return CVariant( res, FALSE )
	
end operator

'':::::
operator + _
	( _
		byref lhs as CVariant, _
		byval rhs as zstring ptr _
	) as CVariant
	
	dim as VARIANT tmp = any, res = any
	
	VariantInit( @tmp )
	V_VT(@tmp) = VT_BSTR
	V_BSTR(@tmp) = SysAllocStringByteLen( rhs, len( *rhs ) )
	
	VarAdd( @lhs.var, @tmp, @res )
	
	VariantClear( @tmp )
	
	return CVariant( res, FALSE )
	
end operator

'':::::
operator + _
	( _
		byref lhs as CVariant, _
		byval rhs as wstring ptr _
	) as CVariant
	
	dim as VARIANT tmp = any, res = any
	
	VariantInit( @tmp )
	V_VT(@tmp) = VT_BSTR
	V_BSTR(@tmp) = SysAllocStringLen( rhs, len( *rhs ) )
	
	VarAdd( @lhs.var, @tmp, @res )
	
	VariantClear( @tmp )
	
	return CVariant( res, FALSE )
	
end operator
