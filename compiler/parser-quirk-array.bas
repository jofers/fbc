'' quirk array statements (ERASE, SWAP) and functions (LBOUND, UBOUND) parsing
''
'' chng: sep/2004 written [v1ctor]


#include once "fb.bi"
#include once "fbint.bi"
#include once "parser.bi"
#include once "rtl.bi"
#include once "ast.bi"

'' EraseStmt = ERASE ID (',' ID)*
function cEraseStmt() as integer
	lexSkipToken( )

	do
		var expr = cVarOrDeref( FB_VAREXPROPT_NOARRAYCHECK )
		if( expr = NULL ) then
			errReport( FB_ERRMSG_EXPECTEDIDENTIFIER )
			hSkipUntil( CHAR_COMMA )
		else
			'' ugly hack to deal with arrays w/o indexes
			if( astIsNIDXARRAY( expr ) ) then
				var expr2 = astGetLeft( expr )
				astDelNode( expr )
				expr = expr2
			end if

			'' array?
			var s = astGetSymbol( expr )
			if( s <> NULL ) then
				if( symbIsArray( s ) = FALSE ) then
					s = NULL
				end if
			end if

			if( s = NULL ) then
				errReport( FB_ERRMSG_EXPECTEDARRAY )
				hSkipUntil( CHAR_COMMA )
			else
				if( typeIsConst( astGetFullType( expr ) ) ) then
					errReport( FB_ERRMSG_CONSTANTCANTBECHANGED )
				end if

				if( symbGetIsDynamic( s ) ) then
					expr = rtlArrayErase( expr, TRUE )
				else
					expr = rtlArrayClear( expr, TRUE, TRUE )
				end if

				astAdd( expr )
			end if
		end if

	'' ','?
	loop while( hMatch( CHAR_COMMA ) )

	function = TRUE
end function

private function hMakeRef _
	( _
		byval t as ASTNODE ptr, _
		byval pexpr as ASTNODE ptr ptr _
	) as ASTNODE ptr

	'' This is similar to astRemSideFx(), it creates a temp var, assigns the
	'' expression with side-effects to that, and replaces the expression
	'' with an access to that temp var. Effectively this causes the
	'' expression with side-effects to be used only once.
	''
	'' However, here we're taking a reference to the expression instead of
	'' storing its result, otherwise SWAP would overwrite the temp var,
	'' not the actual data. This also means LINK nodes must be used,
	'' because we don't support references across statements...

	var dtype = typeAddrof( astGetFullType( (*pexpr) ) )
	var subtype = astGetSubType( (*pexpr) )

	'' var ref
	var ref = symbAddTempVar( dtype, subtype, FALSE, FALSE )

	'' ref = @expr
	function = astNewLINK( t, astNewASSIGN( astNewVAR( ref, , dtype, subtype ), astNewADDROF( *pexpr ) ) )

	'' Use *ref instead of the original expr
	*pexpr = astNewDEREF( astNewVAR( ref, , dtype, subtype ) )

end function

'' SwapStmt = SWAP VarOrDeref ',' VarOrDeref
function cSwapStmt() as integer
	lexSkipToken( )

	var l = cVarOrDeref( FB_VAREXPROPT_ISASSIGN )
	if( l = NULL ) then
		errReport( FB_ERRMSG_EXPECTEDIDENTIFIER )
		hSkipStmt( )
		return TRUE
	end if

	if( astIsConstant( l ) ) then
		errReport( FB_ERRMSG_CONSTANTCANTBECHANGED, TRUE )
	end if

	hMatchCOMMA( )

	var r = cVarOrDeref( FB_VAREXPROPT_ISASSIGN )
	if( r = NULL ) then
		errReport( FB_ERRMSG_EXPECTEDIDENTIFIER )
		astDelTree( l )
		hSkipStmt( )
		return TRUE
	end if

	if( astIsConstant( r ) ) then
		errReport( FB_ERRMSG_CONSTANTCANTBECHANGED, TRUE )
	end if

	dim as integer ldtype = astGetDataType( l )
	dim as integer rdtype = astGetDataType( r )

	select case ldtype
	case FB_DATATYPE_STRING, FB_DATATYPE_FIXSTR, FB_DATATYPE_CHAR
		select case rdtype
		case FB_DATATYPE_STRING, FB_DATATYPE_FIXSTR, FB_DATATYPE_CHAR
			function = rtlStrSwap( l, r )
		case else
			errReport( FB_ERRMSG_TYPEMISMATCH )
		end select
		exit function
	end select

	if( ldtype = FB_DATATYPE_WCHAR ) then
		if( rdtype = FB_DATATYPE_WCHAR ) then
			function = rtlWstrSwap( l, r )
		else
			errReport( FB_ERRMSG_TYPEMISMATCH )
		end if
		exit function
	end if

	'' Check for invalid types by checking whether a raw assignment
	'' would work (raw because astCheckASSIGN() doesn't check
	'' operator overloads)
	dim as ASTNODE ptr fakelhs = astNewVAR( NULL, 0, astGetFullType( l ), astGetSubtype( l ) )
	dim as integer ok = astCheckASSIGN( fakelhs, r )
	astDelTree( fakelhs )
	if( ok = FALSE ) then
		errReport( FB_ERRMSG_TYPEMISMATCH )
		exit function
	end if

	if( (ldtype = FB_DATATYPE_STRUCT) or (rdtype = FB_DATATYPE_STRUCT) ) then
		assert( ldtype = FB_DATATYPE_STRUCT )
		assert( rdtype = FB_DATATYPE_STRUCT )
		assert( astGetSubtype( l ) = astGetSubtype( r ) )
		return rtlMemSwap( l, r )
	end if

	''
	'' For the ASM backend SWAP can be done with PUSH/POP, if...
	''
	'' - it's on integers or floats (structs handled above)
	''
	'' - neither side is a bitfield (for those we always have to use a
	''   temp var, to get the bitfield accesses built properly)
	''
	'' - both side's types have the same size, otherwise we may push 4
	''   bytes and pop 8, or similar.
	''
	'' - it's either both integer or both float, so we don't swap between
	''   integer and float this way. The ASSIGN converts differently than
	''   the POP, so you'd get different results depending on whether it's
	''   <SWAP i, f> or <SWAP f, i>.
	''
	dim as integer use_pushpop = TRUE
	use_pushpop and= (irGetOption( IR_OPT_HIGHLEVEL ) = FALSE)
	use_pushpop and= (typeGetSize( ldtype ) = typeGetSize( rdtype ))
	use_pushpop and= (typeGetClass( ldtype ) = typeGetClass( rdtype ))
	use_pushpop and= (astIsBITFIELD( l ) = FALSE)
	use_pushpop and= (astIsBITFIELD( r ) = FALSE)

	'' A scope to enclose the temp vars
	dim as ASTNODE ptr scopenode = astScopeBegin( )
	dim as ASTNODE ptr t = NULL

	'' Side effects? Then use references to be able to read/write...
	if( astIsClassOnTree( AST_NODECLASS_CALL, l ) <> NULL ) then
		t = hMakeRef( t, @l )
	end if

	if( astIsClassOnTree( AST_NODECLASS_CALL, r ) <> NULL ) then
		t = hMakeRef( t, @r )
	end if

	if( use_pushpop ) then
		'' push clone( l )
		t = astNewLINK( t, astNewSTACK( AST_OP_PUSH, astCloneTree( l ) ) )

		'' l = clone( r )
		t = astNewLINK( t, astNewASSIGN( l, astCloneTree( r ) ) )

		'' pop r
		t = astNewLINK( t, astNewSTACK( AST_OP_POP, r ) )
	else
		var lfulldtype = astGetFullType( l )
		var lsubtype = astGetSubType( l )

		'' var temp = clone( l )
		var temp = symbAddTempVar( lfulldtype, lsubtype, FALSE, FALSE )
		t = astNewLINK( t, astNewASSIGN( astNewVAR( temp, , lfulldtype, lsubtype ), astCloneTree( l ) ) )

		'' l = clone( r )
		t = astNewLINK( t, astNewASSIGN( l, astCloneTree( r ) ) )

		'' r = temp
		t = astNewLINK( t, astNewASSIGN( r, astNewVAR( temp, , lfulldtype, lsubtype ) ) )
	end if

	astAdd( t )
	astScopeEnd( scopenode )
	function = TRUE
end function

'':::::
''cArrayFunct =   (LBOUND|UBOUND) '(' ID (',' Expression)? ')' .
''
function cArrayFunct(byval tk as FB_TOKEN) as ASTNODE ptr
	dim as ASTNODE ptr arrayexpr = any, dimexpr = any
	dim as integer is_lbound = any
	dim as FBSYMBOL ptr s = any

	function = NULL

	select case tk

	'' (LBOUND|UBOUND) '(' ID (',' Expression)? ')'
	case FB_TK_LBOUND, FB_TK_UBOUND
		is_lbound = (tk = FB_TK_LBOUND)
		lexSkipToken( )

		'' '('
		hMatchLPRNT( )

		'' ID
		arrayexpr = cVarOrDeref( FB_VAREXPROPT_NOARRAYCHECK )
		if( arrayexpr = NULL ) then
			errReport( FB_ERRMSG_EXPECTEDIDENTIFIER )
			'' error recovery: skip until next ')' and fake an expr
			hSkipUntil( CHAR_RPRNT, TRUE )
			return astNewCONSTi( 0, FB_DATATYPE_INTEGER )
		end if

		'' ugly hack to deal with arrays w/o indexes
		if( astIsNIDXARRAY( arrayexpr ) ) then
			dim as ASTNODE ptr expr = astGetLeft( arrayexpr )
			astDelNode( arrayexpr )
			arrayexpr = expr
		end if

		'' array?
		s = astGetSymbol( arrayexpr )
		if( s <> NULL ) then
			if( symbIsArray( s ) = FALSE ) then
				s = NULL
			end if
		end if

		if( s = NULL ) then
			errReport( FB_ERRMSG_EXPECTEDARRAY, TRUE )
			'' error recovery: skip until next ')' and fake an expr
			hSkipUntil( CHAR_RPRNT, TRUE )
			return astNewCONSTi( 0, FB_DATATYPE_INTEGER )
		end if

		'' (',' Expression)?
		if( hMatch( CHAR_COMMA ) ) then
			hMatchExpressionEx( dimexpr, FB_DATATYPE_INTEGER )
		else
			dimexpr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
		end if

		'' ')'
		hMatchRPRNT( )

		function = rtlArrayBound( arrayexpr, dimexpr, is_lbound )
	end select
end function
