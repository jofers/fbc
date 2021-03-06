'' quirk string statements (MID, LSET) and functions (MID, INSTR) parsing
''
'' chng: sep/2004 written [v1ctor]


#include once "fb.bi"
#include once "fbint.bi"
#include once "parser.bi"
#include once "rtl.bi"
#include once "ast.bi"

'':::::
''MidStmt   	  =   MID '(' Expression{str}, Expression{int} (',' Expression{int}) ')' '=' Expression{str} .
''
function cMidStmt _
	( _
		_
	) as integer

	dim as ASTNODE ptr expr1 = any, expr2 = any, expr3 = any, expr4 = any

	function = FALSE

	'' MID
	lexSkipToken( )

	hMatchLPRNT()

	hMatchExpressionEx( expr1, FB_DATATYPE_STRING )

	dim as FBSYMBOL ptr sym = astGetSymbol( expr1 )
	if( sym = NULL ) then
		'' deref... 
		select case as const astGetClass( expr1 )
		case AST_NODECLASS_DEREF
			sym = iif( astGetLeft( expr1 ), astGetSymbol( astGetLeft( expr1 ) ), NULL )
		end select
	end if

	if( sym = NULL ) then
		errReport( FB_ERRMSG_EXPECTEDIDENTIFIER, TRUE )
	else
		if( symbIsConstant( sym ) or typeIsConst( astGetFullType( expr1 ) ) ) then
			errReport( FB_ERRMSG_CONSTANTCANTBECHANGED, TRUE )
	 	end if
	end if

	hMatchCOMMA( )

	hMatchExpressionEx( expr2, FB_DATATYPE_INTEGER )

	if( hMatch( CHAR_COMMA ) ) then
		hMatchExpressionEx( expr3, FB_DATATYPE_INTEGER )
	else
		expr3 = astNewCONSTi( -1, FB_DATATYPE_INTEGER )
	end if

	hMatchRPRNT( )

	if( hMatch( FB_TK_ASSIGN ) = FALSE ) then
		errReport( FB_ERRMSG_EXPECTEDEQ )
	end if

	hMatchExpressionEx( expr4, FB_DATATYPE_STRING )

	function = rtlStrAssignMid( expr1, expr2, expr3, expr4 ) <> NULL

end function

#define CREATEFAKEID() _
	astNewVAR( symbAddTempVar( FB_DATATYPE_STRING ), 0, FB_DATATYPE_STRING )

'':::::
'' LRsetStmt		=	LSET|RSET String|UDT (','|'=') Expression|UDT
function cLRSetStmt(byval tk as FB_TOKEN) as integer
    dim as ASTNODE ptr dstexpr = any, srcexpr = any
    dim as integer dtype1 = any, dtype2 = any
    dim as FBSYMBOL ptr dst = any, src = any
    dim as integer is_rset = any

    function = FALSE

	'' (LSET|RSET)
	is_rset = (tk = FB_TK_RSET)
	lexSkipToken( )

	'' Expression
	dstexpr = cVarOrDeref( )
	if( dstexpr = NULL ) then
		errReport( FB_ERRMSG_EXPECTEDIDENTIFIER )
		'' error recovery: fake a var
		dstexpr = CREATEFAKEID( )
	end if

	dtype1 = astGetDataType( dstexpr )
	select case as const dtype1
	case FB_DATATYPE_STRING, FB_DATATYPE_FIXSTR, _
		 FB_DATATYPE_CHAR, FB_DATATYPE_WCHAR, _
		 FB_DATATYPE_STRUCT

		if( is_rset and (dtype1 = FB_DATATYPE_STRUCT) ) then
			errReport( FB_ERRMSG_INVALIDDATATYPES )
			'' error recovery: do lset instead
			is_rset = FALSE
		end if

		dim as FBSYMBOL ptr sym = astGetSymbol( dstexpr )

		if( sym = NULL ) then
			'' deref... 
			if (astGetClass( dstexpr ) = AST_NODECLASS_DEREF) then
				sym = iif( astGetLeft( dstexpr ), astGetSymbol( astGetLeft( dstexpr ) ), NULL )
			end if
		end if

		if( sym = NULL ) then
			errReport( FB_ERRMSG_EXPECTEDIDENTIFIER, TRUE )
		else
			if( symbIsConstant( sym ) or typeIsConst( astGetFullType( dstexpr ) ) ) then
				errReport( FB_ERRMSG_CONSTANTCANTBECHANGED, TRUE )
			end if
		end if

	case else
		errReport( FB_ERRMSG_INVALIDDATATYPES )
		'' error recovery: fake a var
		astDelTree( dstexpr )
		dstexpr = CREATEFAKEID( )
	end select

	'' ',' or '='
	if( hMatch( CHAR_COMMA ) = FALSE ) then
		if( hMatch( FB_TK_ASSIGN ) = FALSE ) then
			errReport( FB_ERRMSG_EXPECTEDCOMMA )
		end if
	end if

	'' Expression
	hMatchExpressionEx( srcexpr, dtype1 )

	dtype2 = astGetDataType( srcexpr )
	select case as const dtype2
	case FB_DATATYPE_STRING, FB_DATATYPE_FIXSTR, _
		 FB_DATATYPE_CHAR, FB_DATATYPE_WCHAR, _
		 FB_DATATYPE_STRUCT

	case else
		errReport( FB_ERRMSG_INVALIDDATATYPES )
		'' error recovery: fake a var
		astDelTree( srcexpr )
		srcexpr = CREATEFAKEID( )
	end select

	if( (dtype1 = FB_DATATYPE_STRUCT) or _
		(dtype2 = FB_DATATYPE_STRUCT) ) then

		if( dtype1 <> dtype2 ) then
			errReport( FB_ERRMSG_INVALIDDATATYPES )
			'' no error recovery: stmt already parsed
			astDelTree( srcexpr )
			astDelTree( dstexpr )
			return TRUE
		end if

		dst = astGetSymbol( dstexpr )
		src = astGetSymbol( srcexpr )
		if( (dst = NULL) or (src = NULL) ) then
			errReport( FB_ERRMSG_EXPECTEDIDENTIFIER )
			'' no error recovery: stmt already parsed
			astDelTree( srcexpr )
			astDelTree( dstexpr )
			return TRUE
		end if

		function = rtlMemCopyClear( dstexpr, symbGetUDTUnpadLen( dst->subtype ), _
									srcexpr, symbGetUDTUnpadLen( src->subtype ) )
	else
		function = rtlStrLRSet( dstexpr, srcexpr, is_rset )
	end if

end function

private function cStrCHR(byval is_wstr as integer) as ASTNODE ptr
	static as zstring * 32*6+1 zs
	static as wstring * 32*6+1 ws
	static as zstring * 8+1 o
	dim as integer v = any, i = any, cnt = any, isconst = any
	dim as ASTNODE ptr exprtb(0 to 31) = any, expr = any

	hMatchLPRNT( )

	cnt = 0
	do
		hMatchExpressionEx( exprtb(cnt), FB_DATATYPE_INTEGER )
		cnt += 1
		if( cnt >= 32 ) then
			exit do
		end if
	loop while( hMatch( CHAR_COMMA ) )

	hMatchRPRNT( )

	'' if wstring, check if compile-time conversion can be done
	if( is_wstr and (env.target.wchar.doconv = FALSE) ) then
		isconst = FALSE
	else
		'' constant? evaluate at compile-time
		isconst = TRUE
		for i = 0 to cnt-1
			if( astIsCONST( exprtb(i) ) = FALSE ) then
				isconst = FALSE
				exit for
			end if

        	'' when the constant value is 0, we must not handle
            '' this as a constant string
  			v = astGetValueAsInt( exprtb(i) )
			if( v = 0 ) then
				isconst = FALSE
				exit for
			end if
		next
	end if

	if( isconst ) then
		if( is_wstr = FALSE ) then
			zs = ""
		else
			ws = ""
		end if

		for i = 0 to cnt-1
  			expr = exprtb(i)
  			v = astGetValueAsInt( expr )
  			astDelNode( expr )

			if( is_wstr = FALSE ) then
				if( cuint( v ) > 255 ) then
					v = 255
				end if
				if( (v < CHAR_SPACE) or (v > 127) ) then
					zs += ESCCHAR
					o = oct( v )
					zs += chr( len( o ) )
					zs += o
				else
					zs += chr( v )
				end if

			else
				if( (v < CHAR_SPACE) or (v > 127) ) then
					ws += ESCCHAR
					o = oct( v )
					ws += wchr( len( o ) )
					ws += o
				else
					ws += wchr( v )
				end if
			end if
		next

		if( is_wstr = FALSE ) then
			function = astNewVAR( symbAllocStrConst( zs, cnt ), 0, FB_DATATYPE_CHAR )
		else
			function = astNewVAR( symbAllocWstrConst( ws, cnt ), 0, FB_DATATYPE_WCHAR )
		end if
	else
		function = rtlStrChr( cnt, exprtb(), is_wstr )
	end if
end function

private function cStrASC() as ASTNODE ptr
	dim as ASTNODE ptr expr1 = any, posexpr = any
	dim as integer p = any

	hMatchLPRNT( )
	hMatchExpressionEx( expr1, FB_DATATYPE_STRING )

	'' (',' Expression)?
	if( hMatch( CHAR_COMMA ) ) then
		hMatchExpressionEx( posexpr, FB_DATATYPE_INTEGER )
	else
		posexpr = NULL
	end if

	hMatchRPRNT( )

	'' constant? evaluate at compile-time
	dim as FBSYMBOL ptr litsym = NULL
	select case astGetDataType( expr1 )
	case FB_DATATYPE_CHAR, FB_DATATYPE_WCHAR
		litsym = astGetStrLitSymbol( expr1 )
	end select

	if( litsym <> NULL ) then
		'' if wstring, check if compile-time conversion can be done
        if( (astGetDataType( expr1 ) = FB_DATATYPE_WCHAR) and _
			(env.target.wchar.doconv  = FALSE) ) then
			p = -1
		else
			'' pos is an constant too?
			if( posexpr <> NULL ) then
				if( astIsCONST( posexpr ) ) then
					p = astGetValueAsInt( posexpr )
					astDelNode( posexpr )

					if( p < 0 ) then
						p = 0
					end if
				else
					p = -1
				end if
			else
				p = 1
			end if
		end if

		if( p >= 0 ) then
			'' zstring?
			if( astGetDataType( expr1 ) <> FB_DATATYPE_WCHAR ) then
				'' remove internal escape format
				dim as zstring ptr zs = hUnescape( symbGetVarLitText( litsym ) )
				function = astNewCONSTi( asc( *zs, p ), FB_DATATYPE_UINT )
			'' wstring..
			else
				'' ditto
				dim as wstring ptr ws = hUnescapeW( symbGetVarLitTextW( litsym ) )
				function = astNewCONSTi( asc( *ws, p ), FB_DATATYPE_UINT )
			end if
			astDelNode( expr1 )
			expr1 = NULL
		end if
	end if

	if( expr1 <> NULL ) then
		function = rtlStrAsc( expr1, posexpr )
	end if
end function

'':::::
'' cCVXFunct	=	CVD       '(' Expression{str} ')'
'' 				|   CVS       '(' Expression{str} ')'
'' 				|   CVI       '(' Expression{str} ')'
'' 				|   CVL       '(' Expression{str} ')'
'' 				|   CVSHORT   '(' Expression{str} ')'
'' 				|   CVLONGINT '(' Expression{str} ')'
''
function cCVXFunct(byval tk as FB_TOKEN) as ASTNODE ptr
	'' CVD | CVS | CVI | CVL | CVSHORT | CVLONGINT
	lexSkipToken( )

	'' '('
	hMatchLPRNT( )

	'' string expression
	dim as ASTNODE ptr expr1 = any
	hMatchExpressionEx( expr1, FB_DATATYPE_STRING )

	'' ')'
	hMatchRPRNT( )

	'' constant? evaluate at compile-time
	dim as FBSYMBOL ptr litsym = NULL
	select case astGetDataType( expr1 )
	case FB_DATATYPE_CHAR
		litsym = astGetStrLitSymbol( expr1 )
	end select

	dim as integer allowconst = TRUE

	'' determine return type (use this to determine function name)
	dim as FB_DATATYPE functype = any
	select case as const tk
	case FB_TK_CVD
		functype = FB_DATATYPE_DOUBLE
		allowconst = FALSE
	case FB_TK_CVS
		functype = FB_DATATYPE_SINGLE
		allowconst = FALSE
	case FB_TK_CVI
		functype = fbLangGetType( INTEGER )
	case FB_TK_CVL
		functype = fbLangGetType( LONG )
	case FB_TK_CVSHORT
		functype = FB_DATATYPE_SHORT
	case else
		assert(tk = FB_TK_CVLONGINT)
		functype = FB_DATATYPE_LONGINT
	end select

	dim as zstring ptr zs = any
	dim as integer zslen = any
	if( (allowconst <> FALSE) and (litsym <> NULL) ) then
		'' remove internal escape format
		zs = hUnescape( symbGetVarLitText( litsym ) )
		zslen = len( *zs )
	else
		zs = NULL
		zslen = 0
	end if

	dim as ASTNODE ptr funcexpr = NULL
	if( zslen >= typeGetSize( functype ) ) then
		select case as const functype
		case FB_DATATYPE_DOUBLE
			funcexpr = astNewCONSTf( cvd( *zs ), FB_DATATYPE_DOUBLE )
		case FB_DATATYPE_SINGLE
			funcexpr = astNewCONSTf( cvs( *zs ), FB_DATATYPE_SINGLE )
		case FB_DATATYPE_INTEGER, FB_DATATYPE_LONG
			funcexpr = astNewCONSTi( cvl( *zs ), FB_DATATYPE_INTEGER )
		case FB_DATATYPE_SHORT
			funcexpr = astNewCONSTi( cvshort( *zs ), FB_DATATYPE_SHORT )
		case FB_DATATYPE_LONGINT
			funcexpr = astNewCONSTl( cvlongint( *zs ), FB_DATATYPE_LONGINT )
		end select
		astDelNode( expr1 )
	else
		select case as const functype
		case FB_DATATYPE_DOUBLE
			funcexpr = astNewCALL( PROCLOOKUP( CVD ) )
		case FB_DATATYPE_SINGLE
			funcexpr = astNewCALL( PROCLOOKUP( CVS ) )
		case FB_DATATYPE_INTEGER, FB_DATATYPE_LONG
			funcexpr = astNewCALL( PROCLOOKUP( CVL ) )
		case FB_DATATYPE_SHORT
			funcexpr = astNewCALL( PROCLOOKUP( CVSHORT ) )
		case FB_DATATYPE_LONGINT
			funcexpr = astNewCALL( PROCLOOKUP( CVLONGINT ) )
		end select

		'' byref expr as string
		if( astNewARG( funcexpr, expr1 ) = NULL ) then
			funcexpr = NULL
		end if
	end if

	if( funcexpr <> NULL ) then
		funcexpr = astNewCONV( functype, NULL, funcexpr )
	end if

	function = funcexpr
end function

'':::::
'' cMKXFunct	=	MKD       '(' Expression{double}  ')'
'' 				|   MKS       '(' Expression{float}   ')'
'' 				|   MKI       '(' Expression{int}     ')'
'' 				|   MKL       '(' Expression{long}    ')'
'' 				|   MKSHORT   '(' Expression{short}   ')'
'' 				|   MKLONGINT '(' Expression{longint} ')'
''
function cMKXFunct(byval tk as FB_TOKEN) as ASTNODE ptr
	lexSkipToken( )

	hMatchLPRNT( )

	dim as ASTNODE ptr expr1 = any
	hMatchExpressionEx( expr1, FB_DATATYPE_STRING )

	hMatchRPRNT( )

	dim as ASTNODE ptr funcexpr = NULL

	#macro doMKX( token )
		select case as const astGetDataType( expr1 )
		case FB_DATATYPE_LONGINT, FB_DATATYPE_ULONGINT
			funcexpr = astNewCONSTstr( str( token( astGetValueAsLongint( expr1 ) ) ) )
		case FB_DATATYPE_SINGLE, FB_DATATYPE_DOUBLE
			funcexpr = astNewCONSTstr( str( token( astGetValueAsDouble( expr1 ) ) ) )
		case FB_DATATYPE_LONG, FB_DATATYPE_ULONG
			if( FB_LONGSIZE = len( integer ) ) then
				funcexpr = astNewCONSTstr( str( token( astGetValueAsInt( expr1 ) ) ) )
			else
				funcexpr = astNewCONSTstr( str( token( astGetValueAsLongint( expr1 ) ) ) )
			end if
		case else
			funcexpr = astNewCONSTstr( str( token( astGetValueAsInt( expr1 ) ) ) )
		end select
	#endmacro

'	'' I don't know how to do this properly, the NULLs ruin it.
'	'' constant? eval at compile-time
'	if( astIsCONST( expr1 ) ) then
'		select case as const tk
'		case FB_TK_MKD
'			doMKX( mkd )
'		case FB_TK_MKS
'			doMKX( mks )
'		case FB_TK_MKI
'			doMKX( mki )
'		case FB_TK_MKL
'			doMKX( mkl )
'		case FB_TK_MKSHORT
'			doMKX( mkshort )
'		case FB_TK_MKLONGINT
'			doMKX( mklongint )
'		end select
'		astDelNode( expr1 )
'		expr1 = NULL
'	end if

	if( expr1 <> NULL ) then
		select case as const tk
		case FB_TK_MKD
			funcexpr = astNewCALL( PROCLOOKUP( MKD ) )
		case FB_TK_MKS
			funcexpr = astNewCALL( PROCLOOKUP( MKS ) )
		case FB_TK_MKI
			select case fbLangGetType( INTEGER )
			case FB_DATATYPE_INTEGER, FB_DATATYPE_LONG
				funcexpr = astNewCALL( PROCLOOKUP( MKI ) )
			case FB_DATATYPE_SHORT
				funcexpr = astNewCALL( PROCLOOKUP( MKSHORT ) )
			end select
		case FB_TK_MKL
			funcexpr = astNewCALL( PROCLOOKUP( MKL ) )
		case FB_TK_MKSHORT
			funcexpr = astNewCALL( PROCLOOKUP( MKSHORT ) )
		case else
			assert(tk = FB_TK_MKLONGINT)
			funcexpr = astNewCALL( PROCLOOKUP( MKLONGINT ) )
		end select

		'' byval expr as {type}
		if( astNewARG( funcexpr, expr1 ) = NULL ) then
			funcexpr = NULL
		end if
	end if

	function = funcexpr
end function


'':::::
'' cStringFunct	=	W|STR$ '(' Expression{int|float|double} ')'
'' 				|   MID$ '(' Expression ',' Expression (',' Expression)? ')'
'' 				|   W|STRING$ '(' Expression ',' Expression{int|str} ')' .
''              |   INSTR '(' (Expression{int} ',')? Expression{str}, "ANY"? Expression{str} ')'
''              |   INSTRREV '(' Expression{str}, "ANY"? Expression{str} (',' Expression{int})? ')'
''              |   RTRIM$ '(' Expression{str} (, "ANY" Expression{str} )? ')'
''
function cStringFunct(byval tk as FB_TOKEN) as ASTNODE ptr
	dim as ASTNODE ptr expr1 = any, expr2 = any, expr3 = any
	dim as integer dclass = any, dtype = any, is_any = any, is_wstr = any

	function = NULL

	select case tk
	'' W|STR '(' Expression{int|float|double|wstring} ')'
	case FB_TK_STR, FB_TK_WSTR
		is_wstr = (tk = FB_TK_WSTR)
		lexSkipToken( )

		hMatchLPRNT( )
		hMatchExpressionEx( expr1, FB_DATATYPE_INTEGER )
		hMatchRPRNT( )

		if( is_wstr = FALSE ) then
			expr1 = rtlToStr( expr1, fbLangIsSet( FB_LANG_QB ) )
		else
			expr1 = rtlToWstr( expr1 )
		end if
		if( expr1 = NULL ) then
			errReport( FB_ERRMSG_INVALIDDATATYPES )
			expr1 = astNewCONST( 0, FB_DATATYPE_INTEGER )
		end if

		function = expr1

	'' MID '(' Expression ',' Expression (',' Expression)? ')'
	case FB_TK_MID
		lexSkipToken( )

		hMatchLPRNT( )
		hMatchExpressionEx( expr1, FB_DATATYPE_STRING )
		hMatchCOMMA( )
		hMatchExpressionEx( expr2, FB_DATATYPE_INTEGER )
		if( hMatch( CHAR_COMMA ) ) then
			hMatchExpressionEx( expr3, FB_DATATYPE_INTEGER )
		else
			expr3 = astNewCONSTi( -1, FB_DATATYPE_INTEGER )
		end if
		hMatchRPRNT( )

		expr1 = rtlStrMid( expr1, expr2, expr3 )
		if( expr1 = NULL ) then
			errReport( FB_ERRMSG_INVALIDDATATYPES )
			expr1 = astNewCONST( 0, FB_DATATYPE_INTEGER )
		end if

		function = expr1

	'' W|STRING '(' Expression ',' Expression{int|str} ')'
	case FB_TK_STRING, FB_TK_WSTRING
		is_wstr = (tk = FB_TK_WSTRING)
		lexSkipToken( )

		hMatchLPRNT( )
		hMatchExpressionEx( expr1, FB_DATATYPE_INTEGER )
		hMatchCOMMA( )
		hMatchExpressionEx( expr2, FB_DATATYPE_INTEGER )
		hMatchRPRNT( )

		if( is_wstr = FALSE ) then
			expr1 = rtlStrFill( expr1, expr2 )
		else
			expr1 = rtlWstrFill( expr1, expr2 )
		end if
		if( expr1 = NULL ) then
			errReport( FB_ERRMSG_INVALIDDATATYPES )
			expr1 = astNewCONST( 0, FB_DATATYPE_INTEGER )
		end if

		function = expr1

	'' W|CHR '(' Expression (',' Expression )* ')'
	case FB_TK_CHR, FB_TK_WCHR
		is_wstr = (tk = FB_TK_WCHR)
		lexSkipToken( )

		function = cStrCHR(is_wstr)

	'' ASC '(' Expression (',' Expression)? ')'
	case FB_TK_ASC
		lexSkipToken( )

		function = cStrASC()

	case FB_TK_INSTR
		lexSkipToken( )

		hMatchLPRNT( )
		hMatchExpressionEx( expr1, FB_DATATYPE_INTEGER )
		hMatchCOMMA( )
		is_any = hMatch( FB_TK_ANY )
		hMatchExpressionEx( expr2, FB_DATATYPE_STRING )
		expr3 = NULL
		if( is_any = FALSE ) then
			if( hMatch( CHAR_COMMA ) ) then
				is_any = hMatch( FB_TK_ANY )
				hMatchExpressionEx( expr3, FB_DATATYPE_STRING )
			end if
		end if
		if( expr3 = NULL ) then
			expr3 = expr2
			expr2 = expr1
			expr1 = astNewCONSTi( 1, FB_DATATYPE_INTEGER )
		end if
		hMatchRPRNT( )

		expr1 = rtlStrInstr( expr1, expr2, expr3, is_any )
		if( expr1 = NULL ) then
			errReport( FB_ERRMSG_INVALIDDATATYPES )
			expr1 = astNewCONST( 0, FB_DATATYPE_INTEGER )
		end if

		function = expr1

	case FB_TK_INSTRREV
		lexSkipToken( )

		hMatchLPRNT( )
		hMatchExpressionEx( expr1, FB_DATATYPE_STRING )
		hMatchCOMMA( )
		is_any = hMatch( FB_TK_ANY )
		hMatchExpressionEx( expr2, FB_DATATYPE_STRING )
		if( hMatch( CHAR_COMMA ) ) then
			hMatchExpressionEx( expr3, FB_DATATYPE_INTEGER )
		else
			expr3 = astNewCONSTi( -1, FB_DATATYPE_INTEGER )
		end if
		hMatchRPRNT( )

		expr1 = rtlStrInstrRev( expr3, expr1, expr2, is_any )
		if( expr1 = NULL ) then
			errReport( FB_ERRMSG_INVALIDDATATYPES )
			expr1 = astNewCONST( 0, FB_DATATYPE_INTEGER )
		end if

		function = expr1

	case FB_TK_TRIM, FB_TK_LTRIM, FB_TK_RTRIM
		lexSkipToken( )

		hMatchLPRNT( )
		hMatchExpressionEx( expr1, FB_DATATYPE_STRING )
		if( hMatch( CHAR_COMMA ) ) then
			is_any = hMatch( FB_TK_ANY )
			hMatchExpressionEx( expr2, FB_DATATYPE_STRING )
		else
			is_any = FALSE
			expr2 = NULL
		end if
		hMatchRPRNT( )

		select case (tk)
		case FB_TK_TRIM
			expr1 = rtlStrTrim( expr1, expr2, is_any )
		case FB_TK_LTRIM
			expr1 = rtlStrLTrim( expr1, expr2, is_any )
		case FB_TK_RTRIM
			expr1 = rtlStrRTrim( expr1, expr2, is_any )
		end select

		if( expr1 = NULL ) then
			errReport( FB_ERRMSG_INVALIDDATATYPES )
			expr1 = astNewCONST( 0, FB_DATATYPE_INTEGER )
		end if

		function = expr1

	end select

end function
