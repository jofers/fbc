'' AST conversion nodes
'' l = expression to convert; r = NULL
''
'' chng: sep/2004 written [v1ctor]


#include once "fb.bi"
#include once "fbint.bi"
#include once "ir.bi"
#include once "rtl.bi"
#include once "ast.bi"


'':::::
function hTruncateInt _
	( _
		byval dtype as integer, _
		byval value as integer ptr _
	) as integer

	'' makes sure value is represented exactly as it would be stored in dtype

	'' returns FALSE if conversion was lossless, or TRUE if the number changed

	'' considers signed <-> unsigned changes (e.g. 8-bit -1 <-> 255) as
	'' lossless, to prevent excessive warnings with things like &hff - counting_pine

	dim as integer value0 = *value

	select case as const dtype
	case FB_DATATYPE_BYTE
		*value = cbyte( value0 )
		return (cbyte( *value ) <> value0) and (cubyte( *value ) <> value0)

	case FB_DATATYPE_UBYTE
		*value = cubyte( cuint( value0 ) )
		return (cbyte( *value ) <> value0) and (cubyte( *value ) <> value0)

	case FB_DATATYPE_SHORT
		*value = cshort( value0 )
		return (cshort( *value ) <> value0) and (cushort( *value ) <> value0)

	case FB_DATATYPE_USHORT
		*value = cushort( cuint( value0 ) )
		return (cshort( *value ) <> value0) and (cushort( *value ) <> value0)

	end select

	return FALSE

end function

'':::::
private sub hCONVConstEvalInt _
	( _
		byval to_dtype as integer, _
		byval v as ASTNODE ptr _
	)

	dim as integer vdtype = typeGet( v->dtype )
	to_dtype = typeGet( to_dtype )

	select case as const vdtype
	case FB_DATATYPE_LONGINT, FB_DATATYPE_ULONGINT

		select case as const to_dtype
		case FB_DATATYPE_BYTE
			v->con.val.int = cbyte( v->con.val.long )

		case FB_DATATYPE_UBYTE
			v->con.val.int = cubyte( culngint( v->con.val.long ) )

		case FB_DATATYPE_SHORT
			v->con.val.int = cshort( v->con.val.long )

		case FB_DATATYPE_USHORT
			v->con.val.int = cushort( culngint( v->con.val.long ) )

		case FB_DATATYPE_INTEGER, FB_DATATYPE_ENUM, FB_DATATYPE_LONG
			v->con.val.int = cint( v->con.val.long )

		case FB_DATATYPE_UINT, FB_DATATYPE_POINTER, FB_DATATYPE_ULONG
			v->con.val.uint = cuint( culngint( v->con.val.long ) )

		end select

	case FB_DATATYPE_SINGLE, FB_DATATYPE_DOUBLE

		select case as const to_dtype
		case FB_DATATYPE_BYTE
			v->con.val.int = cbyte( v->con.val.float )

		case FB_DATATYPE_UBYTE
			v->con.val.int = cubyte( v->con.val.float )

		case FB_DATATYPE_SHORT
			v->con.val.int = cshort( v->con.val.float )

		case FB_DATATYPE_USHORT
			v->con.val.int = cushort( v->con.val.float )

		case FB_DATATYPE_INTEGER, FB_DATATYPE_ENUM, FB_DATATYPE_LONG
			v->con.val.int = cint( v->con.val.float )

		case FB_DATATYPE_UINT, FB_DATATYPE_POINTER, FB_DATATYPE_ULONG
			v->con.val.uint = cuint( v->con.val.float )

		end select

	case else

		if( hTruncateInt( to_dtype, @v->con.val.int ) <> FALSE ) then
			errReportWarn( FB_WARNINGMSG_CONVOVERFLOW )
		end if

	end select

end sub

'':::::
private sub hCONVConstEvalFlt _
	( _
		byval to_dtype as integer, _
		byval v as ASTNODE ptr _
	)

	dim as integer vdtype = typeGet( v->dtype )
	to_dtype = typeGet( to_dtype )

	select case as const vdtype
	case FB_DATATYPE_SINGLE, FB_DATATYPE_DOUBLE
		'' do nothing..

	case FB_DATATYPE_LONGINT

		if( to_dtype = FB_DATATYPE_SINGLE ) then
			v->con.val.float = csng( v->con.val.long )
		else
			v->con.val.float = cdbl( v->con.val.long )
		end if

	case FB_DATATYPE_ULONGINT

		if( to_dtype = FB_DATATYPE_SINGLE ) then
			v->con.val.float = csng( cunsg( v->con.val.long ) )
		else
			v->con.val.float = cdbl( cunsg( v->con.val.long ) )
		end if

	case FB_DATATYPE_UINT, FB_DATATYPE_POINTER

		if( to_dtype = FB_DATATYPE_SINGLE ) then
			v->con.val.float = csng( cunsg( v->con.val.int ) )
		else
			v->con.val.float = cdbl( cunsg( v->con.val.int ) )
		end if

	case FB_DATATYPE_LONG

		if( FB_LONGSIZE = len( integer ) ) then
			if( to_dtype = FB_DATATYPE_SINGLE ) then
				v->con.val.float = csng( v->con.val.int )
			else
				v->con.val.float = cdbl( v->con.val.int )
			end if
		else
			if( to_dtype = FB_DATATYPE_SINGLE ) then
				v->con.val.float = csng( v->con.val.long )
			else
				v->con.val.float = cdbl( v->con.val.long )
			end if
		end if

	case FB_DATATYPE_ULONG

		if( FB_LONGSIZE = len( integer ) ) then
			if( to_dtype = FB_DATATYPE_SINGLE ) then
				v->con.val.float = csng( cunsg( v->con.val.int ) )
			else
				v->con.val.float = cdbl( cunsg( v->con.val.int ) )
			end if
		else
			if( to_dtype = FB_DATATYPE_SINGLE ) then
				v->con.val.float = csng( cunsg( v->con.val.long ) )
			else
				v->con.val.float = cdbl( cunsg( v->con.val.long ) )
			end if
		end if

	case else

		if( to_dtype = FB_DATATYPE_SINGLE ) then
			v->con.val.float = csng( v->con.val.int )
		else
			v->con.val.float = cdbl( v->con.val.int )
		end if

	end select

end sub

'':::::
private sub hCONVConstEval64 _
	( _
		byval to_dtype as integer, _
		byval v as ASTNODE ptr _
	)

	dim as integer vdtype = typeGet( v->dtype )
	to_dtype = typeGet( to_dtype )

	select case as const vdtype
	case FB_DATATYPE_LONGINT, FB_DATATYPE_ULONGINT
		'' do nothing

	case FB_DATATYPE_SINGLE, FB_DATATYPE_DOUBLE

		if( to_dtype = FB_DATATYPE_LONGINT ) then
			v->con.val.long = clngint( v->con.val.float )
		else
			v->con.val.long = culngint( v->con.val.float )
		end if

	case FB_DATATYPE_LONG

		if( FB_LONGSIZE = len( integer ) ) then
			if( to_dtype = FB_DATATYPE_LONGINT ) then
				v->con.val.long = clngint( v->con.val.int )
			else
				v->con.val.long = culngint( v->con.val.int )
			end if
		end if

	case FB_DATATYPE_ULONG
		if( FB_LONGSIZE = len( integer ) ) then
			if( to_dtype = FB_DATATYPE_LONGINT ) then
				v->con.val.long = clngint( cuint( v->con.val.int ) )
			else
				v->con.val.long = culngint( cuint( v->con.val.int ) )
			end if
		end if

	case else
		'' when expanding to 64bit, we must take care of signedness of source operand

		if( to_dtype = FB_DATATYPE_LONGINT ) then
			if( typeIsSigned( v->dtype ) ) then
				v->con.val.long = clngint( v->con.val.int )
			else
				v->con.val.long = clngint( cuint( v->con.val.int ) )
			end if
		else
			if( typeIsSigned( v->dtype ) ) then
				v->con.val.long = culngint( v->con.val.int )
			else
				v->con.val.long = culngint( cuint( v->con.val.int ) )
			end if
		end if

	end select

end sub

'':::::
private function hCheckPtr _
	( _
		byval to_dtype as integer, _
		byval to_subtype as FBSYMBOL ptr, _
		byval expr_dtype as integer, _
		byval expr as ASTNODE ptr _
	) as integer

	function = FALSE

	'' to pointer? only allow integers and pointers
	if( typeIsPtr( to_dtype ) ) then
		select case as const typeGet( expr_dtype )
		case FB_DATATYPE_INTEGER, FB_DATATYPE_UINT, FB_DATATYPE_ENUM, _
		     FB_DATATYPE_LONG, FB_DATATYPE_ULONG
			return TRUE

		'' only allow other int dtypes if it's 0 (due QB's INTEGER = short)
		case FB_DATATYPE_BYTE, FB_DATATYPE_UBYTE, _
		     FB_DATATYPE_SHORT, FB_DATATYPE_USHORT
			if( astIsCONST( expr ) = FALSE ) then
				exit function
			end if
			return (astGetValueAsInt( expr ) = 0)

		case FB_DATATYPE_POINTER
			'' Both are pointers, fall through to checks below

		case else
			exit function
		end select

	'' from pointer? only allow integers and pointers
	elseif( typeIsPtr( expr_dtype ) ) then
		select case as const typeGet( to_dtype )
		case FB_DATATYPE_INTEGER, FB_DATATYPE_UINT, FB_DATATYPE_ENUM, _
		     FB_DATATYPE_LONG, FB_DATATYPE_ULONG
			return TRUE

		case FB_DATATYPE_POINTER
			'' Both are pointers, fall through to checks below

		case else
			exit function
		end select
	else
		'' No pointers at all, nothing to do
		return TRUE
	end if

	'' Both are pointers
	'' if any of them is a derived class, only allow cast to a base or derived
	if( typeGetDtOnly( to_dtype ) = FB_DATATYPE_STRUCT ) then
		if( to_subtype->udt.base <> NULL ) then
			if( typeGetDtOnly( expr_dtype ) <> FB_DATATYPE_STRUCT ) then
				if( typeGetDtOnly( expr_dtype ) <> FB_DATATYPE_VOID ) then
					exit function
				end if
			else			
				'' not a upcasting?
				if( symbGetUDTBaseLevel( expr->subtype, to_subtype ) = 0 ) then
					'' try downcasting..
					if( symbGetUDTBaseLevel( to_subtype, expr->subtype ) = 0 ) then
						exit function
					End If
				End If
			end if
		End If
	End If

	if( typeGetDtOnly( expr_dtype ) = FB_DATATYPE_STRUCT ) then		
		if( expr->subtype->udt.base <> NULL ) then
			if( typeGetDtOnly( to_dtype ) <> FB_DATATYPE_STRUCT ) then
				if( typeGetDtOnly( to_dtype ) <> FB_DATATYPE_VOID ) then
					exit function
				end if
			else
				'' not a upcasting?
				if( symbGetUDTBaseLevel( to_subtype, expr->subtype ) = 0 ) then
					'' try downcasting..
					if( symbGetUDTBaseLevel( expr->subtype, to_subtype ) = 0 ) then
						exit function
					End If
				End If
			end if
		End If
	End If

	function = TRUE

end function

'':::::
function astCheckCONV _
	( _
		byval to_dtype as integer, _
		byval to_subtype as FBSYMBOL ptr, _
		byval l as ASTNODE ptr _
	) as integer

	dim as integer ldtype = any

	function = FALSE

	'' UDT? only upcasting supported by now
	if( typeGet( to_dtype ) = FB_DATATYPE_STRUCT ) then
		return symbGetUDTBaseLevel( l->subtype, to_subtype ) > 0
	end if

	ldtype = astGetFullType( l )

	'' string? neither
	if( typeGetClass( ldtype ) = FB_DATACLASS_STRING ) then
		exit function
	end if

	'' check pointers
	if( hCheckPtr( to_dtype, to_subtype, ldtype, l ) = FALSE ) then
		exit function
	end if

	select case typeGet( ldtype )
	'' CHAR and WCHAR literals are also from the INTEGER class
	case FB_DATATYPE_CHAR, FB_DATATYPE_WCHAR
		'' don't allow, unless it's a deref pointer
		if( astIsDEREF( l ) = FALSE ) then
			exit function
		end if

	'' UDT's? ditto
	case FB_DATATYPE_STRUCT
		exit function
	end select

	function = TRUE

end function

'':::::
#macro hDoGlobOpOverload( to_dtype, to_subtype, node )
	scope
		dim as FBSYMBOL ptr proc = any
		dim as FB_ERRMSG err_num = any

		proc = symbFindCastOvlProc( to_dtype, to_subtype, node, @err_num )
		if( proc <> NULL ) then
			'' build a proc call
			return astBuildCall( proc, l, NULL )
		else
			if( err_num <> FB_ERRMSG_OK ) then
				return NULL
			end if
		end if
	end scope
#endmacro

'':::::
function astNewCONV _
	( _
		byval to_dtype as integer, _
		byval to_subtype as FBSYMBOL ptr, _
		byval l as ASTNODE ptr, _
		byval op as AST_OP, _
		byval check_str as integer _
	) as ASTNODE ptr

	dim as ASTNODE ptr n = any
	dim as integer ldclass = any, ldtype = any

	function = NULL

	ldtype = astGetFullType( l )

	'' same type?
	if( typeGetDtAndPtrOnly( ldtype ) = typeGetDtAndPtrOnly( to_dtype ) ) then
		if( l->subtype = to_subtype ) then
			return l
		end if
	end if

	'' try casting op overloading
	hDoGlobOpOverload( to_dtype, to_subtype, l )

	select case as const typeGet( to_dtype )
	'' to UDT? as op overloading failed, refuse.. ditto with void (used by uop/bop
	'' to cast to be most precise possible) and strings
	case FB_DATATYPE_VOID, FB_DATATYPE_STRING
		exit function
		 
	case FB_DATATYPE_STRUCT ', FB_DATATYPE_CLASS
		if( symbGetUDTBaseLevel( l->subtype, to_subtype ) = 0 ) then
			exit function
		End If
        
    case FB_DATATYPE_ITER
        '' iterators only convert to "any iterator"
        if( ( l->dtype <> FB_DATATYPE_ITER ) or ( symbGetFullType( to_subtype ) <> FB_DATATYPE_VOID ) ) then
            exit function
        end if           

	case else
		select case typeGet( ldtype )
		'' from UDT? ditto..
		case FB_DATATYPE_STRUCT ', FB_DATATYPE_CLASS
			exit function
		end select

	end select

	ldclass = typeGetClass( ldtype )

	select case op
	'' sign conversion?
	case AST_OP_TOSIGNED, AST_OP_TOUNSIGNED
		'' float? invalid
		if( ldclass <> FB_DATACLASS_INTEGER ) then
			exit function
		end if
	end select

	'' check pointers
	if( hCheckPtr( to_dtype, to_subtype, ldtype, l ) = FALSE ) then
		exit function
	end if

	'' string?
	if( check_str ) then
		select case as const typeGet( ldtype )
		case FB_DATATYPE_STRING, FB_DATATYPE_FIXSTR, _
			 FB_DATATYPE_CHAR, FB_DATATYPE_WCHAR
			return rtlStrToVal( l, to_dtype )
		end select

	else
		if( ldclass = FB_DATACLASS_STRING ) then
			exit function

		'' CHAR and WCHAR literals are also from the INTEGER class
		else
			select case typeGet( ldtype )
			case FB_DATATYPE_CHAR, FB_DATATYPE_WCHAR
				'' don't allow, unless it's a deref pointer
				if( astIsDEREF( l ) = FALSE ) then
					exit function
				end if
			end select
		end if
	end if

	'' constant? evaluate at compile-time
	if( astIsCONST( l ) ) then
		select case as const typeGet( to_dtype )
		case FB_DATATYPE_LONGINT, FB_DATATYPE_ULONGINT
			hCONVConstEval64( to_dtype, l )

		case FB_DATATYPE_SINGLE, FB_DATATYPE_DOUBLE
			hCONVConstEvalFlt( to_dtype, l )

		case FB_DATATYPE_LONG, FB_DATATYPE_ULONG
			if( FB_LONGSIZE = len( integer ) ) then
				hCONVConstEvalInt( to_dtype, l )
			else
				hCONVConstEval64( to_dtype, l )
			end if

		case else
			'' bytes/shorts/integers/enum
			hCONVConstEvalInt( to_dtype, l )
		end select

		l->class = AST_NODECLASS_CONST
		astGetFullType( l ) = to_dtype
		l->subtype = to_subtype
		return l
	end if

	dim as integer doconv = TRUE

	'' high-level IR? always convert..
	if( irGetOption( IR_OPT_HIGHLEVEL ) ) then
		'' special case: if it's a float to int, use a builtin function
		if( (ldclass = FB_DATACLASS_FPOINT) and (typeGetClass( to_dtype ) = FB_DATACLASS_INTEGER) ) then
			return rtlMathFTOI( l, to_dtype )
		else
			select case( typeGetDtAndPtrOnly( to_dtype ) )
			case FB_DATATYPE_STRUCT '', FB_DATATYPE_CLASS
				'' C (not C++) doesn't support casting from a UDT to another, so do this instead: lhs = *((typeof(lhs)*)&rhs)
				return astNewDEREF( astNewCONV( typeAddrOf( to_dtype ), to_subtype, astNewADDROF( l ) ) )   
			end select
		end if
	else
		'' only convert if the classes are different (ie, floating<->integer) or
		'' if sizes are different (ie, byte<->int)
		if( ldclass = typeGetClass( to_dtype ) ) then
			select case typeGet( to_dtype )
			case FB_DATATYPE_STRUCT '', FB_DATATYPE_CLASS   
				'' do nothing
				doconv = FALSE
			case else
				if( typeGetSize( ldtype ) = typeGetSize( to_dtype ) ) then
					doconv = FALSE
				end if
			End Select
		end if

		if( irGetOption( IR_OPT_FPUCONV ) ) then
			if (ldclass = FB_DATACLASS_FPOINT) and ( typeGetClass( to_dtype ) = FB_DATACLASS_FPOINT ) then
				if( typeGetSize( ldtype ) <> typeGetSize( to_dtype ) ) then
					doConv = TRUE
				end if
			end if
		end if

		'' casting another cast?
		if( l->class = AST_NODECLASS_CONV ) then
			'' no conversion in both?
			if( l->cast.doconv = FALSE ) then
				if( doconv = FALSE ) then
					'' just replace the bottom cast()'s type
					astGetFullType( l ) = to_dtype
					l->subtype = to_subtype
					return l
				end if
			end if
		end if
	end if

	'' alloc new node
	n = astNewNode( AST_NODECLASS_CONV, to_dtype, to_subtype )

	n->l = l
	n->cast.doconv = doconv

	function = n

end function

'':::::
function astNewOvlCONV _
	( _
		byval to_dtype as integer, _
		byval to_subtype as FBSYMBOL ptr, _
		byval l as ASTNODE ptr _
	) as ASTNODE ptr

	'' try casting op overloading only
	hDoGlobOpOverload( to_dtype, to_subtype, l )

	'' nothing to do
	function = l

end function

'':::::
function astLoadCONV _
	( _
		byval n as ASTNODE ptr _
	) as IRVREG ptr

	dim as ASTNODE ptr l = any
	dim as IRVREG ptr vs = any, vr = any

	l = n->l

	if( l = NULL ) then
		return NULL
	end if

	vs = astLoad( l )

	if( ast.doemit ) then
		vs->vector = n->vector
		if( n->cast.doconv ) then
			vr = irAllocVreg( astGetDataType( n ), n->subtype )
			vr->vector = n->vector
			irEmitConvert( astGetDataType( n ), n->subtype, vr, vs )
		else
			vr = vs
			irSetVregDataType( vr, astGetDataType( n ), n->subtype )
		end if
	end if

	astDelNode( l )

	function = vr

end function


