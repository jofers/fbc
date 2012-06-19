'' proc (SUB, FUNCTION, OPERATOR, PROPERTY, CTOR/DTOR) header and body parsing
''
'' chng: sep/2004 written [v1ctor]


#include once "fb.bi"
#include once "fbint.bi"
#include once "parser.bi"
#include once "rtl.bi"
#include once "ast.bi"

declare function hBuildArgFunnelDefinition( byval proc as FBSYMBOL ptr, byval is_funnel as integer, byval is_proto as integer, byval dtype as FB_DATATYPE=FB_DATATYPE_VOID, byval subtype as FBSYMBOL ptr = NULL ) as FBSYMBOL ptr
declare sub      hBuildArgFunnelEntry( byval proc as FBSYMBOL ptr, byval is_nested as integer )
declare function hBuildArgFunnel     ( byval proc as FBSYMBOL ptr, byval is_nested as integer, byval dtype as FB_DATATYPE, byval subtype as FBSYMBOL ptr ) as FBSYMBOL ptr
declare function hBuildArgScatter    ( byval proc as FBSYMBOL ptr, byval is_nested as integer ) as FBSYMBOL ptr
declare function hBuildArgFunnelExit (  ) as integer

'' [ALIAS "id"]
function cAliasAttribute() as zstring ptr
	static as zstring * (FB_MAXNAMELEN+1) aliasid

	if (lexGetToken() = FB_TK_ALIAS) then
		lexSkipToken()

		if (lexGetClass() = FB_TKCLASS_STRLITERAL) then
			lexEatToken(aliasid)
			return @aliasid
		end if

		errReport(FB_ERRMSG_SYNTAXERROR)
	end if

	return NULL
end function

'' [LIB "string"]
sub cLibAttribute()
	if (lexGetToken() = FB_TK_LIB) then
		lexSkipToken()
		if (lexGetClass() <> FB_TKCLASS_STRLITERAL) then
			errReport(FB_ERRMSG_SYNTAXERROR)
		else
			fbAddLib(lexGetText())
			lexSkipToken()
		end if
	end if
end sub

sub cConstOrStaticAttribute( byval pattrib as integer ptr )
	select case( lexGetToken( ) )
	'' STATIC?
	case FB_TK_STATIC
		lexSkipToken( )
		*pattrib or= FB_SYMBATTRIB_STATIC
	'' CONST?
	case FB_TK_CONST
		lexSkipToken( )
		*pattrib or= FB_SYMBATTRIB_CONST
	end select
end sub

'':::::
private sub hParamError _
	( _
		byval proc as FBSYMBOL ptr, _
		byval argnum as integer, _
		byval errnum as integer = FB_ERRMSG_PARAMTYPEMISMATCHAT _
	)

	errReportParam( proc, argnum, NULL, errnum )

end sub

'':::::
private function hCheckPrototype _
	( _
		byval proto as FBSYMBOL ptr, _
		byval proc as FBSYMBOL ptr, _
		byval proc_dtype as integer, _
		byval proc_subtype as FBSYMBOL ptr _
	) as integer

    dim as FBSYMBOL ptr param = any, proto_param = any
    dim as integer params = any, proto_params = any, i = any

	function = FALSE

	'' check arg count
	param = symbGetProcHeadParam( proc )
	params = symbGetProcParams( proc )
	if( symbIsMethod( proc ) ) then
		params -= 1
		param = param->next
	end if

	proto_param = symbGetProcHeadParam( proto )
	proto_params = symbGetProcParams( proto )
	if( symbIsMethod( proto ) ) then
		proto_params -= 1
		proto_param = proto_param->next
	end if

	if( proto_params <> params ) then
		errReport( FB_ERRMSG_ARGCNTMISMATCH, TRUE )
		'' no error recovery: caller will take care
		exit function
	end if

	'' check return type
	if( symbGetFullType( proto ) <> proc_dtype ) then
		errReport( FB_ERRMSG_TYPEMISMATCH, TRUE )
		'' no error recovery: ditto
		exit function
	end if

	'' and sub type
	if( symbGetSubtype( proto ) <> proc_subtype ) then
		errReport( FB_ERRMSG_TYPEMISMATCH, TRUE )
		'' no error recovery: ditto
		exit function
	end if

	'' check return method
	if( proc->proc.returnMethod <> FB_RETURN_DEFAULT) and _
		( proto->proc.returnMethod <> proc->proc.returnMethod ) then
			errReportWarn( FB_WARNINGMSG_RETURNMETHODMISMATCH )
	end if

	'' check each arg
	for i = 1 to params
        dim as integer dtype = symbGetFullType( proto_param )

    	'' convert any AS ANY arg to the final one
    	if( typeGet( dtype ) = FB_DATATYPE_VOID ) then
    		proto_param->typ = param->typ
    		proto_param->subtype = param->subtype

    	'' check if types don't conflit
    	else
    		if( param->typ <> dtype ) then
                hParamError( proc, i )
                '' no error recovery: caller will take care
                exit function

            elseif( param->subtype <> symbGetSubtype( proto_param ) ) then
                hParamError( proc, i )
                '' no error recovery: ditto
                exit function
    		end if
    	end if

    	'' and mode
    	if( param->param.mode <> symbGetParamMode( proto_param ) ) then
			hParamError( proc, i )
			'' no error recovery: ditto
            exit function
    	end if

    	'' check names and change to the new one if needed
    	if( param->param.mode <> FB_PARAMMODE_VARARG ) then
    		symbSetName( proto_param, symbGetName( param ) )

    		'' as both have the same type, re-set the suffix, because for example
    		'' "a as integer" on the prototype and "a%" or just "a" on the proc
    		'' declaration when in a defint context is allowed in QB
    		if( symbIsSuffixed( param ) ) then
    			symbGetAttrib( proto_param ) or= FB_SYMBATTRIB_SUFFIXED
    		else
    		    symbGetAttrib( proto_param ) and = not FB_SYMBATTRIB_SUFFIXED
    		end if
    	end if

    	'' next arg
    	proto_param = proto_param->next
    	param = param->next
    next

    ''
    function = TRUE

end function

private sub hCheckAttribs _
	( _
		byval proto as FBSYMBOL ptr, _
		byval attrib as FB_SYMBATTRIB _
	)

	'' the body can only be STATIC if the proto is too
	if( (attrib and FB_SYMBATTRIB_STATIC) <> 0 ) then
		if( symbIsStatic( proto ) = FALSE ) then
			errReport( FB_ERRMSG_PROCPROTOTYPENOTSTATIC )
			return
		end if
	end if

	'' same for CONST
	if( (attrib and FB_SYMBATTRIB_CONST) <> 0 ) then
		if( symbIsConstant( proto ) = FALSE ) then
			errReport( FB_ERRMSG_PROCPROTOTYPENOTCONST )
			return
		end if
	end if

	symbGetAttrib( proto ) or= attrib
end sub

'':::::
private function hGetId _
	( _
		byval parent as FBSYMBOL ptr, _
		byval id as zstring ptr, _
		byval dtype as integer ptr, _
		byval is_sub as integer _
	) as FBSYMBOL ptr

	dim as FBSYMCHAIN ptr chain_ = any
	dim as FBSYMBOL ptr sym = any

	function = NULL

	'' no parent? read as-is
	if( parent = NULL ) then
		chain_ = lexGetSymChain( )
    else
		chain_ = symbLookupAt( parent, lexGetText( ), FALSE, FALSE )
	end if

    '' any symbol found?
    if( chain_ <> NULL ) then
    	'' same class?
    	sym = symbFindByClass( chain_, FB_SYMBCLASS_PROC )
    else
    	sym = NULL
    end if

	select case as const lexGetClass( )
	case FB_TKCLASS_IDENTIFIER
		if( fbLangOptIsSet( FB_LANG_OPT_PERIODS ) ) then
			'' if inside a namespace, symbols can't contain periods (.)'s
			if( symbIsGlobalNamespc( ) = FALSE ) then
  				if( lexGetPeriodPos( ) > 0 ) then
					errReport( FB_ERRMSG_CANTINCLUDEPERIODS )
				end if
			end if
		end if

	case FB_TKCLASS_QUIRKWD
		if( env.clopt.lang <> FB_LANG_QB ) then
			'' only if inside a ns and if not local
			if( (parent = NULL) or (parser.scope > FB_MAINSCOPE) ) then
				errReport( FB_ERRMSG_DUPDEFINITION )
				'' error recovery: fake an id, skip until next '('
				*id = *hMakeTmpStr( )
				*dtype = FB_DATATYPE_INVALID
				hSkipUntil( CHAR_LPRNT )
				return NULL
			end if
		end if

	case FB_TKCLASS_KEYWORD, FB_TKCLASS_OPERATOR
		if( env.clopt.lang <> FB_LANG_QB ) then
			errReport( FB_ERRMSG_DUPDEFINITION )
			'' error recovery: fake an id, skip until next '('
			*id = *hMakeTmpStr( )
			*dtype = FB_DATATYPE_INVALID
			hSkipUntil( CHAR_LPRNT )
			return NULL
		end if

	case else
		errReport( FB_ERRMSG_EXPECTEDIDENTIFIER )
		'' error recovery: fake an id, skip until next '('
		*id = *hMakeTmpStr( )
		*dtype = FB_DATATYPE_INVALID
		hSkipUntil( CHAR_LPRNT )
		return NULL
	end select

	*id = *lexGetText( )
	*dtype = lexGetType( )

	if( is_sub ) then
		if( *dtype <> FB_DATATYPE_INVALID ) then
			errReport( FB_ERRMSG_INVALIDCHARACTER )
			*dtype = FB_DATATYPE_INVALID
		end if
	end if

	lexSkipToken( )

	function = sym

end function

private sub hCheckRetType(byref dtype as integer, byref subtype as FBSYMBOL ptr)
	'' check for invalid types
	select case as const typeGet( dtype )
	case FB_DATATYPE_FIXSTR, FB_DATATYPE_CHAR, FB_DATATYPE_WCHAR
		errReport( FB_ERRMSG_CANNOTRETURNFIXLENFROMFUNCTS )
		'' error recovery: fake a type
		dtype = FB_DATATYPE_STRING
		subtype = NULL

	case FB_DATATYPE_VOID
		errReport( FB_ERRMSG_INVALIDDATATYPES )
		'' error recovery: fake a type
		dtype = typeAddrOf( dtype )
		subtype = NULL
	end select
end sub

private sub hParseAttributes _
	( _
		byref attrib as FB_SYMBATTRIB, _
		byval stats as FB_SYMBSTATS, _
		byref priority as integer _
	)

	priority = 0

	'' Priority?
	if( lexGetClass( ) = FB_TKCLASS_NUMLITERAL ) then
		'' not ctor or dtor?
		if( (stats and (FB_SYMBSTATS_GLOBALCTOR or FB_SYMBSTATS_GLOBALDTOR)) = 0 ) then
			errReport( FB_ERRMSG_SYNTAXERROR )
			'' error recovery: skip token
			lexSkipToken( )
		'' not an integer
		elseif( lexGetType( ) <> FB_DATATYPE_INTEGER ) then
			errReport( FB_ERRMSG_INVALIDPRIORITY )
			'' error recovery: skip token
			lexSkipToken( )
		else
			priority = valint( *lexGetText() )
			if priority < 101 or priority > 65535 then
				errReport( FB_ERRMSG_INVALIDPRIORITY )
				'' error recovery: skip token
				lexSkipToken( )
			else
				priority and= &hffff
   				lexSkipToken( )
			end if
		end if
	end if

    '' STATIC?
    if( lexGetToken( ) = FB_TK_STATIC ) then
    	lexSkipToken( )
    	attrib or= FB_SYMBATTRIB_STATICLOCALS
    end if

    '' EXPORT?
    if( lexGetToken( ) = FB_TK_EXPORT ) then
		'' ctor or dtor?
		if( (stats and (FB_SYMBSTATS_GLOBALCTOR or FB_SYMBSTATS_GLOBALDTOR)) <> 0 ) then
			errReport( FB_ERRMSG_SYNTAXERROR )
			'' error recovery: skip token
			lexSkipToken( )
			return
		end if

    	'' private?
    	if( (attrib and FB_SYMBATTRIB_PRIVATE) > 0 ) then
			errReport( FB_ERRMSG_SYNTAXERROR )
    			'' error recovery: make it public
    			attrib and= not FB_SYMBATTRIB_PRIVATE
    	end if

    	lexSkipToken( )

    	fbSetOption( FB_COMPOPT_EXPORT, TRUE )
    	'''''if( fbGetOption( FB_COMPOPT_EXPORT ) = FALSE ) then
    	'''''	errReportWarn( FB_WARNINGMSG_CANNOTEXPORT )
    	'''''end if
    	attrib or= FB_SYMBATTRIB_EXPORT or FB_SYMBATTRIB_PUBLIC
    end if
end sub


'':::::
function cProcReturnMethod _
	( _
		byval dtype as FB_DATATYPE _
	) as FB_PROC_RETURN_METHOD

	'' (OPTION(LIT_STRING))?

	dim as string returnMethod

	function = FB_RETURN_DEFAULT

	'' not allowed for non floating-point types
	if( typeGetClass( dtype ) <> FB_DATACLASS_FPOINT ) then exit function

	if( lexGetToken( ) = FB_TK_OPTION ) then
		lexSkipToken( )
		hMatchLPRNT( )
		if( lexGetClass( ) <> FB_TKCLASS_STRLITERAL ) then
			errReport( FB_ERRMSG_SYNTAXERROR )
		else
			returnMethod = trim( ucase( *lexGetText( ) ) )
			if( returnMethod = "SSE" ) then
				function = FB_RETURN_SSE
			elseif( returnMethod = "FPU" ) then
				function = FB_RETURN_FPU
			end if
			lexSkipToken
		end if
		hMatchRPRNT( )
	end if
end function


'':::::
function cProcCallingConv _
	( _
		byval default as FB_FUNCMODE _
	) as FB_FUNCMODE

    '' Use the default FBCALL?
    if( default = FB_USE_FUNCMODE_FBCALL ) then
        default = env.target.fbcall
    end if

	'' (CDECL|STDCALL|PASCAL)?
	select case as const lexGetToken( )
	case FB_TK_CDECL
		function = FB_FUNCMODE_CDECL
		lexSkipToken( )

	case FB_TK_STDCALL
		'' FB_FUNCMODE_STDCALL may be remapped to FB_FUNCMODE_STDCALL_MS
		'' for targets that do not support the @N suffix
		function = env.target.stdcall
		lexSkipToken( )

	case FB_TK_PASCAL
		function = FB_FUNCMODE_PASCAL
		lexSkipToken( )

	case else
		select case as const parser.mangling
		case FB_MANGLING_BASIC
			function = default

		case FB_MANGLING_CDECL, FB_MANGLING_CPP
			function = FB_FUNCMODE_CDECL

		case FB_MANGLING_STDCALL
			'' FB_FUNCMODE_STDCALL may be remapped to FB_FUNCMODE_STDCALL_MS
			'' for targets that do not support the @N suffix
			function = env.target.stdcall

		case FB_MANGLING_STDCALL_MS
			function = FB_FUNCMODE_STDCALL_MS
		end select
	end select

end function

#define CREATEFAKEID( proc ) _
	symbAddProc( proc, hMakeTmpStr( ), NULL, dtype, subtype, attrib, mode )

'':::::
private function hDoNesting _
	( _
		byval ns as FBSYMBOL ptr _
	) as integer static

	'' proc body can be declared outside the original namespace
	'' if the prototype was declared inside one (as in C++), so
	'' change the hashtb too

	if( ns = symbGetCurrentNamespc( ) ) then
		return FALSE
	end if

	symbNestBegin( ns, TRUE )

	function = TRUE

end function

private sub cNakedAttribute(byval pattrib as integer ptr)
	if (hMatchText("NAKED")) then
		*pattrib or= FB_SYMBATTRIB_NAKED
	end if
end sub

'':::::
''ProcHeader   		=  ID CallConvention? OVERLOAD? (ALIAS LIT_STRING)?
''                     Parameters? ((AS SymbolType)? | CONSTRUCTOR|DESTRUCTOR)?
''					   Priority? STATIC? EXPORT?
''
function cProcHeader _
	( _
		byval attrib as FB_SYMBATTRIB, _
		byref is_nested as integer, _
		byval options as FB_PROCOPT _
	) as FBSYMBOL ptr

    static as zstring * FB_MAXNAMELEN+1 id
    dim as FBSYMBOL ptr proc = any, parent = any
    dim as integer is_extern = any

	is_nested = FALSE
	is_extern = FALSE

	'' ID
	if( (options and FB_PROCOPT_HASPARENT) <> 0 ) then
		parent = symbGetCurrentNamespc( )

	else
		parent = cParentId( FB_IDOPT_ISDECL or _
							FB_IDOPT_SHOWERROR or _
							FB_IDOPT_ALLOWSTRUCT )
		if( parent = NULL ) then
			if( symbGetCurrentNamespc( ) <> @symbGetGlobalNamespc( ) ) then
				parent = symbGetCurrentNamespc( )
			end if
		else
			'' ns used in a prototype?
			if( (options and FB_PROCOPT_ISPROTO) <> 0 ) then
				errReport( FB_ERRMSG_DECLOUTSIDECLASS )
			end if

			select case symbGetClass( parent )
			case FB_SYMBCLASS_STRUCT, FB_SYMBCLASS_CLASS
				attrib or= FB_SYMBATTRIB_OVERLOADED
			end select

			is_extern = TRUE
		end if
	end if

	dim as integer dtype = any, iter_dtype = any, lgt = any
	dim as FBSYMBOL ptr head_proc = any, subtype = any, iter_subtype = any
	dim as FB_SYMBSTATS stats = any

	head_proc = hGetId( parent, @id, @dtype, (options and FB_PROCOPT_ISSUB) <> 0 )

	hCheckSuffix( dtype )

	subtype = NULL
	stats = 0

	'' [NAKED]
	cNakedAttribute(@attrib)

	'' CallConvention?
	dim as FB_FUNCMODE mode = cProcCallingConv( )

	'' OVERLOAD?
	if( lexGetToken( ) = FB_TK_OVERLOAD ) then
		if( fbLangOptIsSet( FB_LANG_OPT_FUNCOVL ) = FALSE ) then
			errReportNotAllowed( FB_LANG_OPT_FUNCOVL )
		else
			attrib or= FB_SYMBATTRIB_OVERLOADED
		end if
		lexSkipToken( )
	end if

	if( (options and FB_PROCOPT_ISPROTO) <> 0 ) then
		'' [LIB "string"]
		cLibAttribute()
	end if

	'' [ALIAS "id"]
	dim as zstring ptr palias = cAliasAttribute()

	proc = symbPreAddProc( @id )

	'' extern implementation?
	if( (options and FB_PROCOPT_ISPROTO) = 0 ) then
		'' must be done before parsing the params
		if( parent <> NULL ) then
			is_nested = hDoNesting( parent )
		end if
	end if

	symbGetAttrib( proc ) = attrib

	'' Parameters?
	cParameters( parent, proc, mode, (options and FB_PROCOPT_ISPROTO) <> 0 )

	'' not vararg?
	if( iif( symbGetProcParams( proc ) > 0, _
	         symbGetProcTailParam( proc )->param.mode <> FB_PARAMMODE_VARARG, _
	         TRUE ) ) then
		if( (options and FB_PROCOPT_HASPARENT) <> 0 ) then
			attrib or= FB_SYMBATTRIB_OVERLOADED
		end if
	end if

    select case as const lexGetToken( )
    '' (CONSTRUCTOR | DESTRUCTOR)?
    case FB_TK_CONSTRUCTOR, FB_TK_DESTRUCTOR

        '' method?
        if( (attrib and FB_SYMBATTRIB_METHOD) <> 0) then
			errReport( FB_ERRMSG_SYNTAXERROR, TRUE )
        else
        	'' not a sub?
        	if( (options and FB_PROCOPT_ISSUB) = 0 ) then
				errReport( FB_ERRMSG_SYNTAXERROR, TRUE )
        	end if

        	'' not argless?
        	if( symbGetProcParams( proc ) <> 0 ) then
				errReport( FB_ERRMSG_ARGCNTMISMATCH, TRUE )
        	end if

			if( lexGetToken( ) = FB_TK_CONSTRUCTOR ) then
				stats or= FB_SYMBSTATS_GLOBALCTOR
			else
				stats or= FB_SYMBSTATS_GLOBALDTOR
			end if

			lexSkipToken( )
		end if

    '' (AS SymbolType)?
    case FB_TK_AS
    	if( (dtype <> FB_DATATYPE_INVALID) or ((options and FB_PROCOPT_ISSUB) <> 0) ) then
			errReport( FB_ERRMSG_SYNTAXERROR )
    	end if

    	lexSkipToken( )

    	if( cSymbolType( dtype, subtype, lgt ) = FALSE ) then
			errReport( FB_ERRMSG_EXPECTEDIDENTIFIER )
			'' error recovery: fake a type
			dtype = FB_DATATYPE_INTEGER
			subtype = NULL
    	else
			hCheckRetType( dtype, subtype )
    	end if

        proc->proc.returnMethod = cProcReturnMethod( dtype )

	case else
		if( (options and FB_PROCOPT_ISSUB) = 0 ) then
			if( fbLangOptIsSet( FB_LANG_OPT_DEFTYPE ) = FALSE ) then
				errReportNotAllowed( FB_LANG_OPT_DEFTYPE, FB_ERRMSG_DEFTYPEONLYVALIDINLANG )
				'' error recovery: fake a type
				dtype = FB_DATATYPE_INTEGER
			end if
		end if
    end select

    if( ((options and FB_PROCOPT_ISSUB) <> 0) or (attrib and FB_SYMBATTRIB_ITERATOR) ) then
        iter_dtype = dtype
        iter_subtype = subtype
    	dtype = FB_DATATYPE_VOID
    	subtype = NULL
    end if

	''
	if( dtype = FB_DATATYPE_INVALID ) then
		dtype = symbGetDefType( id )
	end if

	'' prototype?
	if( (options and FB_PROCOPT_ISPROTO) <> 0 ) then
    	proc = symbAddPrototype( proc, @id, palias, dtype, subtype, attrib, mode )
        if( attrib and FB_SYMBATTRIB_ITERATOR <> 0 ) then
            hBuildArgFunnelDefinition( proc, FALSE, TRUE )
            hBuildArgFunnelDefinition( proc, TRUE, TRUE, iter_dtype, iter_subtype )
        end if

    	if( proc = NULL ) then
			errReport( FB_ERRMSG_DUPDEFINITION )
    	end if

    	return proc
    end if

	'' function body..
	dim as integer priority = any
	hParseAttributes( attrib, stats, priority )

    '' no preview proc or proto with the same name?
    if( head_proc = NULL ) then
    	'' extern decl but no prototype?
    	if( is_extern ) then
			errReport( FB_ERRMSG_DECLOUTSIDECLASS )
    	end if
        
    	head_proc = symbAddProc( proc, @id, palias, dtype, subtype, attrib, mode )

    	if( head_proc = NULL ) then
			errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
			'' error recovery: create a fake symbol
			proc = CREATEFAKEID( proc )
    	else
    		proc = head_proc
    	end if
        
        if ( attrib and FB_SYMBATTRIB_ITERATOR ) then
            '' build iterator helper functions here
            dim as FBSYMBOL ptr proc_scatter, proc_funnel
            proc_scatter = hBuildArgScatter( proc, is_nested )
            proc_funnel = hBuildArgFunnel( proc, is_nested, iter_dtype, iter_subtype )
            if( proc_scatter = NULL or proc_funnel = NULL ) then
                function = FALSE
                exit function
            end if
        end if

    '' another proc or proto defined already..
    else
		'' property?
		if( symbIsProperty( head_proc ) ) then
			errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
			'' error recovery: create a fake symbol
			return CREATEFAKEID( proc )
		end if

    	'' overloaded?
    	if( symbGetProcIsOverloaded( head_proc ) ) then
    		attrib or= FB_SYMBATTRIB_OVERLOADED

            '' try to find a prototype with the same signature
    		head_proc = symbFindOverloadProc( head_proc, proc )

    		'' none found? then try to overload..
    		if( head_proc = NULL ) then
				'' extern decl but no prototype?
				if( is_extern ) then
					errReport( FB_ERRMSG_DECLOUTSIDECLASS )
				end if

    			head_proc = symbAddProc( proc, @id, palias, dtype, subtype, attrib, mode )

    			'' dup def?
                if( head_proc = NULL ) then
					errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
					'' error recovery: create a fake symbol
					return CREATEFAKEID( proc )
    			end if
                
                hBuildArgFunnelDefinition( proc, FALSE, TRUE )
                hBuildArgFunnelDefinition( proc, TRUE, TRUE, iter_dtype, iter_subtype )

    			proc = head_proc
    		end if
    	end if

    	if( head_proc <> proc ) then
    		'' already parsed?
    		if( symbGetIsDeclared( head_proc ) ) then
				errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
				'' error recovery: create a fake symbol
				return CREATEFAKEID( proc )
    		end if

    		'' there's already a prototype for this proc, check for
    		'' declaration conflits and fix up the arguments
    		if( hCheckPrototype( head_proc, proc, dtype, subtype ) = FALSE ) then
				'' error recovery: create a fake symbol
				return CREATEFAKEID( proc )
    		end if

    		'' check calling convention
    		if( symbGetProcMode( head_proc ) <> mode ) then
				errReport( FB_ERRMSG_ILLEGALPARAMSPEC, TRUE )
    		end if

    		'' use the prototype
    		proc = head_proc

			hCheckAttribs( proc, attrib )

    		symbSetIsDeclared( proc )
    	end if
    end if

	'' ctor or dtor?
	if( (stats and FB_SYMBSTATS_GLOBALCTOR) <> 0 ) then
    	symbAddGlobalCtor( proc )
		symbSetProcPriority( proc, priority )

    elseif( (stats and FB_SYMBSTATS_GLOBALDTOR) <> 0 ) then
    	symbAddGlobalDtor( proc )
		symbSetProcPriority( proc, priority )

    end if

    ''
    symbSetProcIncFile( proc, env.inf.incfile )

    function = proc

end function

'':::::
private function hCheckOpOvlParams _
	( _
		byval parent as FBSYMBOL ptr, _
		byval op as integer, _
		byval proc as FBSYMBOL ptr, _
		byval options as FB_PROCOPT _
	) as integer

    dim as integer is_method = symbIsMethod( proc )

#macro hCheckParam( proc, param, num )
	'' vararg?
	if( symbGetParamMode( param ) = FB_PARAMMODE_VARARG ) then
		hParamError( proc, num, FB_ERRMSG_VARARGPARAMNOTALLOWED )
		exit function
	end if

	'' optional?
	if( symbGetIsOptional( param ) ) then
		hParamError( proc, num, FB_ERRMSG_PARAMCANTBEOPTIONAL )
		exit function
	end if
	#endmacro

	function = FALSE

	'' 1st) check the number of params
	dim as integer min_params = any, max_params = any
	select case as const astGetOpClass( op )
	case AST_NODECLASS_UOP, AST_NODECLASS_ADDROF
		min_params = iif( astGetOpIsSelf( op ), 0, 1 )
		max_params = min_params

	case AST_NODECLASS_CONV
		min_params = 0
		max_params = min_params

	case AST_NODECLASS_ASSIGN, AST_NODECLASS_MEM
		min_params = 1
		max_params = min_params

	case AST_NODECLASS_COMP
		'' self only if FOR, STEP and NEXT
		if( astGetOpIsSelf( op ) ) then
			min_params = 0
	'			min_params = iif( op = AST_OP_NEXT, 1, 0 )
			max_params = 1
			if( op = AST_OP_NEXT ) then
				min_params += 1
				max_params += 1
			end if
		else
			min_params = 2
			max_params = min_params
		end if

	'' bop..
	case else
		min_params = iif( astGetOpIsSelf( op ), 1, 2 )
		max_params = min_params
	end select

	dim as integer params = symbGetProcParams( proc )
	dim as integer real_params = params - iif( is_method, 1, 0 )
	if( (real_params < min_params) or (real_params > max_params) ) then
		errReport( FB_ERRMSG_ARGCNTMISMATCH, TRUE )
	   	exit function
	end if

	'' 2nd) check method-only ops
	select case as const astGetOpClass( op )
	case AST_NODECLASS_CONV, AST_NODECLASS_ASSIGN
		if( is_method = FALSE ) then
			if( (options and FB_PROCOPT_ISPROTO) <> 0 ) then
				errReport( FB_ERRMSG_OPMUSTBEAMETHOD, TRUE )
			end if
		end if

	case AST_NODECLASS_BOP, AST_NODECLASS_ADDROF
		if( is_method or astGetOpIsSelf( op ) ) then
			if( parent = NULL ) then
				errReport( FB_ERRMSG_OPMUSTBEAMETHOD, TRUE )
			end if
		else
			if( parent <> NULL ) then
				errReport( FB_ERRMSG_OPCANNOTBEAMETHOD, TRUE )
			end if
		end if

	case AST_NODECLASS_MEM, AST_NODECLASS_COMP
		if astGetOpIsSelf( op ) then
			if( parent = NULL ) then
				errReport( FB_ERRMSG_OPMUSTBEAMETHOD, TRUE )
			end if
		end if

	case else
		if( is_method ) then
			errReport( FB_ERRMSG_OPCANNOTBEAMETHOD, TRUE )
		end if
	end select

	if( params > 0 ) then
		'' 3rd) check the params, at least one param must be an
		''      user-defined type (struct, enum or class)
		dim as FBSYMBOL ptr param = symbGetProcHeadParam( proc )

		hCheckParam( proc, param, 1 )

		select case as const astGetOpClass( op )
		'' unary, cast or addressing?
		case AST_NODECLASS_UOP, AST_NODECLASS_CONV, AST_NODECLASS_ADDROF
			'' is the param an UDT?
			select case symbGetType( param )
			case FB_DATATYPE_STRUCT, FB_DATATYPE_ENUM ', FB_DATATYPE_CLASS

			case else
				hParamError( proc, 1, FB_ERRMSG_ATLEASTONEPARAMMUSTBEANUDT )
				exit function
			end select

		'' binary?
		case AST_NODECLASS_BOP

            if( params > 1 ) then
				dim as FBSYMBOL ptr nxtparam = param->next

				hCheckParam( proc, nxtparam, 2 )

				'' is the 1st param an UDT?
				select case symbGetType( param )
				case FB_DATATYPE_STRUCT, FB_DATATYPE_ENUM ', FB_DATATYPE_CLASS

				case else
					'' try the 2nd one..
					select case symbGetType( nxtparam )
					case FB_DATATYPE_STRUCT, FB_DATATYPE_ENUM ', FB_DATATYPE_CLASS

					case else
						hParamError( proc, 2, FB_ERRMSG_ATLEASTONEPARAMMUSTBEANUDT )
						exit function
					end select
				end select
			end if

		'' NEW or DELETE?
		case AST_NODECLASS_MEM

			select case op
			case AST_OP_NEW_SELF, AST_OP_NEW_VEC_SELF
				'' must be an integer
				if( typeGetClass( symbGetType( param ) ) = FB_DATACLASS_INTEGER ) then
					dim as integer is_integer = TRUE
					if( typeIsPtr( symbGetType( param ) ) ) then
						is_integer = FALSE
					end if
					select case symbGetType( param )
					case FB_DATATYPE_CHAR, FB_DATATYPE_WCHAR
						is_integer = FALSE
					end select
					if( is_integer = FALSE ) then
						hParamError( proc, 1, FB_ERRMSG_PARAMMUSTBEANINTEGER )
						exit function
					end if
				else
					hParamError( proc, 1, FB_ERRMSG_PARAMMUSTBEANINTEGER )
					exit function
				end if

			case else
				'' must be a pointer
				if( typeGetClass( symbGetType( param ) ) = FB_DATACLASS_INTEGER ) then
					if( typeIsPtr( symbGetType( param ) ) = FALSE ) then
						hParamError( proc, 1, FB_ERRMSG_PARAMMUSTBEAPOINTER )
						exit function
					end if
				else
					hParamError( proc, 1, FB_ERRMSG_PARAMMUSTBEAPOINTER )
					exit function
				end if

			end select

		'' FOR, STEP or NEXT?
		case AST_NODECLASS_COMP

			if( astGetOpIsSelf( op ) ) then
				if( params > 1 ) then

				'' skip the instance ptr
				if( is_method ) then
					param = param->next
				end if

				'' must be of the same type as parent
				if( (param = NULL) or (parent = NULL) ) then
					hParamError( proc, 1, FB_ERRMSG_PARAMTYPEINCOMPATIBLEWITHPARENT )
					exit function
				end if

				hCheckParam( proc, param, 1 )

				'' same type?
				if( (symbGetType( param ) <> symbGetType( parent )) or _
					(symbGetSubtype( param ) <> parent) ) then
					hParamError( proc, 1, FB_ERRMSG_PARAMTYPEINCOMPATIBLEWITHPARENT )
					exit function
				end if

			end if
		end if

		end select
	end if

	'' 4th) check the result

	select case astGetOpClass( op )
	case AST_NODECLASS_CONV
		'' return and param types can't be the same
		if( symbGetSubtype( proc ) = parent ) then
			errReport( FB_ERRMSG_SAMEPARAMANDRESULTTYPES, TRUE )
			exit function
		end if

		'' return type can't be a void
		if( symbGetType( proc ) = FB_DATATYPE_VOID ) then
			errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
			exit function
		end if

	'' unary?
	case AST_NODECLASS_UOP
		'' return type can't be a void
		if( symbGetType( proc ) = FB_DATATYPE_VOID ) then
			errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
			exit function
		end if

	'' assignment?
	case AST_NODECLASS_ASSIGN
		'' it must be a SUB
		if( symbGetType( proc ) <> FB_DATATYPE_VOID ) then
			errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
			exit function
		end if

	'' addressing?
	case AST_NODECLASS_ADDROF
		'' return type can't be a void
		if( symbGetType( proc ) = FB_DATATYPE_VOID ) then
			errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
			exit function
		end if

		select case op
		case AST_OP_ADDROF
			'' return type must be a pointer
			if( typeIsPtr( symbGetType( proc ) ) = FALSE ) then
				errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
				exit function
			end if

		case AST_OP_FLDDEREF
			'' return type must be an UDT
			select case symbGetType( proc )
			case FB_DATATYPE_STRUCT ', FB_DATATYPE_CLASS

			case else
				errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
				exit function
			end select
		end select

	'' mem?
	case AST_NODECLASS_MEM
		select case op
		case AST_OP_NEW_SELF, AST_OP_NEW_VEC_SELF
			'' should return a pointer
			if( typeIsPtr( symbGetType( proc ) ) = FALSE ) then
				errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
				exit function
			end if

		case else
			'' should not return anything
			if( symbGetType( proc ) <> FB_DATATYPE_VOID ) then
				errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
				exit function
			end if
		end select

	'' binary?
	case AST_NODECLASS_BOP

		select case as const op
		'' relational? it must return an integer
		case AST_OP_EQ, AST_OP_NE, AST_OP_GT, AST_OP_LT, AST_OP_GE, AST_OP_LE
			if( symbGetType( proc ) <> FB_DATATYPE_INTEGER ) then
				errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
				exit function
			end if

		'' self? must be a SUB
		case else
			if( astGetOpIsSelf( op ) ) then
				if( symbGetType( proc ) <> FB_DATATYPE_VOID ) then
					errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
					exit function
				end if

			'' anything else, it can't be a void
			else
				if( symbGetType( proc ) = FB_DATATYPE_VOID ) then
					errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
					exit function
				end if

			end if
		end select

	case AST_NODECLASS_COMP

		'' FOR, STEP or NEXT?
		if( astGetOpIsSelf( op ) ) then
			'' it must return an integer (if NEXT) or void otherwise
			dim as integer valid_op = TRUE
			if( op = AST_OP_NEXT ) then
				valid_op = ( symbGetType( proc ) = FB_DATATYPE_INTEGER )
			else
				valid_op = ( symbGetType( proc ) = FB_DATATYPE_VOID )
			end if

			if( valid_op = FALSE ) then
				errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
				exit function
			end if

		'' anything else, it can't be a void
		else
			if( symbGetType( proc ) = FB_DATATYPE_VOID ) then
				errReport( FB_ERRMSG_INVALIDRESULTTYPEFORTHISOP, TRUE )
				exit function
			end if

		end if

	end select

	function = TRUE

end function

'':::::
private function hCheckIsSelfCloneByval _
	( _
		byval parent as FBSYMBOL ptr, _
		byval proc as FBSYMBOL ptr, _
		byval is_prototype as integer _
	) as integer

	function = FALSE

	dim as FBSYMBOL ptr param = symbGetProcHeadParam( proc )

	'' if it's a proto, skip the instance param
	if( is_prototype ) then
		param = param->next
	end if
	
	if( param = NULL ) then
		exit function
	end if
	
	'' struct?
	if( symbGetType( param ) <> FB_DATATYPE_STRUCT ) then
		exit function
	end if

	'' same parent?
	if( symbGetSubtype( param ) <> parent ) then
		exit function
	end if
	
	'' byval?
	if( symbGetParamMode( param ) <> FB_PARAMMODE_BYVAL ) then
		exit function
	end if

	'' pointer?
	if( typeGetClass( symbGetType( param ) ) = FB_DATACLASS_INTEGER ) then
		if( typeIsPtr( symbGetType( param ) ) ) then
			exit function
		end if
	end if
	
	'' At least one additional non-optional parameter?
	param = param->next
	while( param <> NULL )
		if( symbGetIsOptional( param ) = FALSE ) then
			exit function
		end if
		param = param->next
	wend

	function = TRUE

end function

'':::::
''OperatorHeader   	=  Operator CallConvention? OVERLOAD? (ALIAS LIT_STRING)?
''                     Parameters? (AS SymbolType)? STATIC? EXPORT?
''
function cOperatorHeader _
	( _
		byval attrib as FB_SYMBATTRIB, _
		byref is_nested as integer, _
		byval options as FB_PROCOPT _
	) as FBSYMBOL ptr

    dim as integer is_extern = any
    dim as FBSYMBOL ptr proc = any, parent = any

	is_nested = FALSE
	is_extern = FALSE

    '' operators are always overloaded
	attrib or= FB_SYMBATTRIB_OPERATOR or FB_SYMBATTRIB_OVERLOADED

	'' parent? This happens with declares that occur
	'' in a type body, the 'type' is the namespace
	if( (options and FB_PROCOPT_HASPARENT) <> 0 ) then
		parent = symbGetCurrentNamespc( )

	'' not inside of an explicit block, this is like:
	'' operator foo.+, 'foo' is parsed, and returned
	else
		parent = cParentId( FB_IDOPT_ISOPERATOR or _
							FB_IDOPT_ISDECL or _
							FB_IDOPT_SHOWERROR or _
							FB_IDOPT_ALLOWSTRUCT )

		'' The parent id isn't used for globals like 'operator +'
		if( parent ) then
			'' Explicit parent id
			'' namespace used in a prototype?
			if( (options and FB_PROCOPT_ISPROTO) <> 0 ) then
				errReport( FB_ERRMSG_DECLOUTSIDECLASS )
			end if
			is_extern = TRUE
		end if
	end if

	'' Operator
	dim as integer op = cOperator( )

	select case op
	case INVALID, _
	     AST_OP_ANDALSO, AST_OP_ANDALSO_SELF, _
	     AST_OP_ORELSE, AST_OP_ORELSE_SELF
		errReport( FB_ERRMSG_EXPECTEDOPERATOR )
		'' error recovery: fake an op
		op = AST_OP_ADD
	end select


	select case as const op
	'' self ops?
	case AST_OP_ASSIGN to AST_OP_CAST
		'' no parent?
		if( parent = NULL ) then
			'' fake it...
			if( astGetOpIsSelf( op ) ) then
				errReport( FB_ERRMSG_OPMUSTBEAMETHOD, TRUE )
				op = AST_OP_ADD
			end if
		end if

	case else
		'' non-self op in a type declaration... !!WRITEME!! static global operators should be allowed?
		if( (options and FB_PROCOPT_HASPARENT) <> 0 ) then
			errReport( FB_ERRMSG_METHODINANONUDT, TRUE, " (TODO)" )
		end if
	end select

    '' check if method should be static or not
    select case as const op
    case AST_OP_NEW_SELF, AST_OP_NEW_VEC_SELF, _
    	 AST_OP_DEL_SELF, AST_OP_DEL_VEC_SELF

    	 attrib or= FB_SYMBATTRIB_STATIC
    	 attrib and= not FB_SYMBATTRIB_METHOD

    case else
    	if( (options and FB_PROCOPT_HASPARENT) <> 0 ) then
    		if( (attrib and FB_SYMBATTRIB_STATIC) <> 0 ) then
				errReport( FB_ERRMSG_OPERATORCANTBESTATIC, TRUE )
				attrib and= not FB_SYMBATTRIB_STATIC
			end if
		end if
	end select

	dim as integer dtype = any, lgt = any
    dim as FBSYMBOL ptr subtype = any

	subtype = NULL

	'' [NAKED]
	cNakedAttribute(@attrib)

	'' CallConvention?
	dim as FB_FUNCMODE mode = cProcCallingConv( )

	'' OVERLOAD?
	if( lexGetToken( ) = FB_TK_OVERLOAD ) then
		'' allow it for consistency even though it is not needed 
		'' member procs are overloaded by default
		lexSkipToken( )
	end if

	if( (options and FB_PROCOPT_ISPROTO) <> 0 ) then
		'' [LIB "string"]
		cLibAttribute()
	end if

	'' [ALIAS "id"]
	dim as zstring ptr palias = cAliasAttribute()

	proc = symbPreAddProc( NULL )

	'' extern implementation?
	if( (options and FB_PROCOPT_ISPROTO) = 0 ) then
		'' must be done before parsing the params
		if( parent <> NULL ) then
			is_nested = hDoNesting( parent )
		end if
	end if

    symbGetAttrib( proc ) = attrib

	'' Parameters?
	cParameters( parent, proc, mode, (options and FB_PROCOPT_ISPROTO) <> 0 )

    '' special cases, '-' or '+' with just one param are actually unary ops
    select case op
    case AST_OP_SUB
    	if( symbGetProcParams( proc ) = 1 ) then
    		op = AST_OP_NEG
    	end if

    case AST_OP_ADD
    	if( symbGetProcParams( proc ) = 1 ) then
    		op = AST_OP_PLUS
    	end if

    '' '*' with one param is actually a deref
    case AST_OP_MUL
    	if( symbGetProcParams( proc ) = 1 ) then
    		op = AST_OP_DEREF
    	end if

    end select

	'' self? (but type casting)
	if( astGetOpNoResult( op ) ) then
		dtype = FB_DATATYPE_VOID
		subtype = NULL
	else
		'' AS SymbolType
		if( lexGetToken( ) <> FB_TK_AS ) then
			errReport( FB_ERRMSG_EXPECTEDRESTYPE )
			'' error recovery: fake a type
			dtype = FB_DATATYPE_INTEGER
			subtype = NULL
		else
			lexSkipToken( )
			if( cSymbolType( dtype, subtype, lgt ) = FALSE ) then
				errReport( FB_ERRMSG_EXPECTEDIDENTIFIER )
				'' error recovery: fake a type
				dtype = FB_DATATYPE_INTEGER
				subtype = NULL
			else
				hCheckRetType( dtype, subtype )
			end if
			proc->proc.returnMethod = cProcReturnMethod( dtype )
		end if
	end if

	symbGetFullType( proc ) = dtype
	symbGetSubtype( proc ) = subtype

	symbSetProcOpOvl( proc, op )

	'' operator LET can't take a byval arg of its own type
	if( op = AST_OP_ASSIGN ) then
		if( hCheckIsSelfCloneByval( parent, proc, ( (options and FB_PROCOPT_ISPROTO) <> 0 ) ) ) then
			errReport( FB_ERRMSG_CLONECANTTAKESELFBYVAL, TRUE )
			exit function
		end if
	end if

	if( (options and FB_PROCOPT_ISPROTO) <> 0 ) then
		'' check params
		hCheckOpOvlParams( parent, op, proc, options )
		proc = symbAddOperator( proc, op, palias, dtype, subtype, attrib, mode )
		if( proc = NULL ) then
			errReport( FB_ERRMSG_DUPDEFINITION )
		end if
		return proc
	end if

	hParseAttributes( attrib, 0, 0 )

	dim as FBSYMBOL ptr head_proc = any

	'' no preview proc or proto for this operator?
	head_proc = symbGetCompOpOvlHead( parent, op )
	if( head_proc = NULL ) then
		'' extern decl but no prototype?
		if( is_extern ) then
			errReport( FB_ERRMSG_DECLOUTSIDECLASS )
		end if

		'' check params
		if( hCheckOpOvlParams( parent, op, proc, options ) = FALSE ) then
			'' error recovery: skip the whole compound stmt
			hSkipCompound( FB_TK_OPERATOR )
			exit function
		end if

		head_proc = symbAddOperator( proc, op, palias, dtype, subtype, _
		                             attrib, mode, FB_SYMBOPT_DECLARING )

		if( head_proc = NULL ) then
			errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
			'' error recovery: create a fake symbol
			proc = CREATEFAKEID( proc )
		else
			proc = head_proc
		end if

	'' another proc or proto defined already..
	else
		'' try to find a prototype with the same signature
		head_proc = symbFindOpOvlProc( op, head_proc, proc )

		'' none found? then try to overload..
		if( head_proc = NULL ) then
			'' extern decl but no prototype?
			if( is_extern ) then
				errReport( FB_ERRMSG_DECLOUTSIDECLASS )
			end if

			'' check params
			if( hCheckOpOvlParams( parent, op, proc, options ) = FALSE ) then
				'' error recovery: skip the whole compound stmt
				hSkipCompound( FB_TK_OPERATOR )
				exit function
			end if

			head_proc = symbAddOperator( proc, op, palias, dtype, subtype, _
			                             attrib, mode, FB_SYMBOPT_DECLARING )

			'' dup def?
			if( head_proc = NULL ) then
				errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
				'' error recovery: create a fake symbol
				return CREATEFAKEID( proc )
			end if

			proc = head_proc
		else
			'' already parsed?
			if( symbGetIsDeclared( head_proc ) ) then
				errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
				'' error recovery: create a fake symbol
				return CREATEFAKEID( proc )
			end if

			'' check params
			if( hCheckOpOvlParams( parent, op, proc, options ) = FALSE ) then
				'' error recovery: skip the whole compound stmt
				hSkipCompound( FB_TK_OPERATOR )
				exit function
			end if

			'' there's already a prototype for this operator, check for
			'' declaration conflits and fix up the arguments
			if( hCheckPrototype( head_proc, proc, dtype, subtype ) = FALSE ) then
				'' error recovery: create a fake symbol
				return CREATEFAKEID( proc )
			end if

			'' check calling convention
			if( symbGetProcMode( head_proc ) <> mode ) then
				errReport( FB_ERRMSG_ILLEGALPARAMSPEC, TRUE )
			end if

			'' use the prototype
			proc = head_proc

			hCheckAttribs( proc, attrib )

			symbSetIsDeclared( proc )
		end if
	end if

    ''
    symbSetProcIncFile( proc, env.inf.incfile )

    function = proc

end function

'':::::
private function hCheckParent _
	( _
		byval parent as FBSYMBOL ptr, _
		byval is_prototype as integer, _
		byval tk as FB_TOKEN _
	) as integer

	function = FALSE

	if( parent = NULL ) then
		errReport( FB_ERRMSG_EXPECTEDCLASSID )
		'' error recovery: skip the whole statement
		if( is_prototype ) then
			hSkipStmt( )
		else
    			hSkipCompound( tk )
    		end if
		exit function
	end if

	if( symbGetParent( parent ) <> symbGetCurrentNamespc( ) ) then
		errReport( FB_ERRMSG_DECLOUTSIDENAMESPC )
		'' error recovery: skip the whole statement
		if( is_prototype ) then
			hSkipStmt( )
		else
			hSkipCompound( tk )
		end if
		exit function
	end if

	'' ns used in a prototype?
	if( is_prototype ) then
		errReport( FB_ERRMSG_DECLOUTSIDECLASS )
	end if

	select case symbGetClass( parent )
	case FB_SYMBCLASS_STRUCT, FB_SYMBCLASS_CLASS

	case else
		errReport( FB_ERRMSG_PARENTISNOTACLASS )
		'' error recovery: skip the whole statement
		if( is_prototype ) then
			hSkipStmt( )
		else
			hSkipCompound( tk )
		end if
		exit function
	end select

	function = TRUE

end function

'':::::
private sub hCheckPropParams _
	( _
		byval proc as FBSYMBOL ptr, _
		byval is_get as integer _
	)

	dim as integer min_params = any, max_params = any

	if( is_get ) then
		min_params = 0
		max_params = 1
	else
		min_params = 1
		max_params = 2
	end if

	''
	if ((symbGetProcParams( proc ) < 1 + min_params) or _
	    (symbGetProcParams( proc ) > 1 + max_params)) then
		errReport( iif( is_get, _
		                FB_ERRMSG_PARAMCNTFORPROPGET, _
		                FB_ERRMSG_PARAMCNTFORPROPSET ), _
		           TRUE )
	end if

	'' any optional param?
	dim as FBSYMBOL ptr param = symbGetProcTailParam( proc )
	dim as integer i = 0
	do while( param <> NULL )
		if( symbGetIsOptional( param ) ) then
			hParamError( proc, 1+i, FB_ERRMSG_PARAMCANTBEOPTIONAL )
		end if

		i += 1
		param = param->prev
	loop
end sub

private sub setUdtPropertyFlags _
	( _
		byval parent as FBSYMBOL ptr, _
		byval is_indexed as integer, _
		byval is_get as integer _
	)

	if( is_indexed ) then
		if( is_get = FALSE ) then
			symbSetUDTHasIdxSetProp( parent )
		else
			symbSetUDTHasIdxGetProp( parent )
		end if
	else
		if( is_get = FALSE ) then
			symbSetUDTHasSetProp( parent )
		else
			symbSetUDTHasGetProp( parent )
		end if
	end if
end sub

'':::::
''PropHeader   		=  ID CallConvention? OVERLOAD? (ALIAS LIT_STRING)?
''                     Parameters? (AS SymbolType)? STATIC? EXPORT?
''
function cPropertyHeader _
	( _
		byval attrib as FB_SYMBATTRIB, _
		byref is_nested as integer, _
		byval is_prototype as integer _
	) as FBSYMBOL ptr

    static as zstring * FB_MAXNAMELEN+1 id
    dim as FBSYMBOL ptr proc = any, parent = any
    dim as integer is_extern = any

	function = NULL

	is_nested = FALSE
	is_extern = FALSE

	attrib or= FB_SYMBATTRIB_PROPERTY or FB_SYMBATTRIB_OVERLOADED

	'' parent
	if( (attrib and FB_SYMBATTRIB_METHOD) <> 0 ) then
		parent = symbGetCurrentNamespc( )

	else
		parent = cParentId( FB_IDOPT_ISDECL or _
							FB_IDOPT_SHOWERROR or _
							FB_IDOPT_ALLOWSTRUCT )

        if( hCheckParent( parent, is_prototype, FB_TK_CONSTRUCTOR ) = FALSE ) then
        	exit function
        end if

		attrib or= FB_SYMBATTRIB_METHOD

		is_extern = TRUE
	end if

	'' id
	dim as integer dtype = any, lgt = any
	dim as FBSYMBOL ptr head_proc = any, subtype = any
	dim as FB_SYMBSTATS stats = any

	head_proc = hGetId( parent, @id, @dtype, TRUE )

	hCheckSuffix( dtype )

	subtype = NULL
	stats = 0

	'' [NAKED]
	cNakedAttribute(@attrib)

	'' CallConvention?
	dim as FB_FUNCMODE mode = cProcCallingConv( )

	'' OVERLOAD?
	if( lexGetToken( ) = FB_TK_OVERLOAD ) then
		'' allow it for consistency even though it is not needed 
		'' member procs are overloaded by default
		lexSkipToken( )
	end if

	if( is_prototype ) then
		'' [LIB "string"]
		cLibAttribute()
	end if

	'' [ALIAS "id"]
	dim as zstring ptr palias = cAliasAttribute()

	proc = symbPreAddProc( @id )

	'' extern implementation?
	if( is_prototype = FALSE ) then
		'' must be done before parsing the params
		if( parent <> NULL ) then
			is_nested = hDoNesting( parent )
		end if
	end if

	symbGetAttrib( proc ) = attrib

	'' Parameters?
	cParameters( parent, proc, mode, is_prototype )

    '' (AS SymbolType)?
    dim as integer is_get = any
    if( lexGetToken( ) = FB_TK_AS ) then

    	lexSkipToken( )

    	if( cSymbolType( dtype, subtype, lgt ) = FALSE ) then
			errReport( FB_ERRMSG_EXPECTEDIDENTIFIER )
			'' error recovery: fake a type
			dtype = FB_DATATYPE_INTEGER
			subtype = NULL
    	else
			hCheckRetType( dtype, subtype )
    	end if

    	is_get = TRUE

	proc->proc.returnMethod = cProcReturnMethod( dtype )

	else
		is_get = FALSE
    end if

    ''
    dim as integer is_indexed = any
    if( is_get = FALSE ) then
    	dtype = FB_DATATYPE_VOID
    	subtype = NULL

		is_indexed = symbGetProcParams( proc ) = 1+2

    else
		if( dtype = FB_DATATYPE_INVALID ) then
			dtype = symbGetDefType( id )
		end if

		is_indexed = symbGetProcParams( proc ) = 1+1
    end if

    ''
    symbGetFullType( proc ) = dtype
    symbGetSubType( proc ) = subtype

	hCheckPropParams( proc, is_get )

	'' prototype?
	if( is_prototype ) then
    	proc = symbAddPrototype( proc, @id, palias, dtype, subtype, attrib, mode )
    	if( proc = NULL ) then
			errReport( FB_ERRMSG_DUPDEFINITION )
    	end if

		setUdtPropertyFlags(parent, is_indexed, is_get)

    	return proc
    end if

	'' function body..

	hParseAttributes( attrib, stats, 0 )

    '' no preview proc or proto with the same name?
    if( head_proc = NULL ) then
    	'' extern decl but no prototype?
    	if( is_extern ) then
			errReport( FB_ERRMSG_DECLOUTSIDECLASS )
    	end if

    	head_proc = symbAddProc( proc, @id, palias, dtype, subtype, attrib, mode )

    	if( head_proc = NULL ) then
			errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
			'' error recovery: create a fake symbol
			proc = CREATEFAKEID( proc )
    	else
    		proc = head_proc
    	end if

    '' another proc or proto defined already..
    else
		'' not a property?
		if( symbIsProperty( head_proc ) = FALSE ) then
			errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
			'' error recovery: create a fake symbol
			return CREATEFAKEID( proc )
		end if

		'' try to find a prototype with the same signature
    	head_proc = symbFindOverloadProc( head_proc, _
    									  proc, _
    									  iif( is_get, _
    									  	   FB_SYMBLOOKUPOPT_PROPGET, _
    									  	   FB_SYMBLOOKUPOPT_NONE ) )

    	'' none found? then try to overload..
    	if( head_proc = NULL ) then

    		'' extern decl but no prototype?
    		if( is_extern ) then
				errReport( FB_ERRMSG_DECLOUTSIDECLASS )
			end if

    		head_proc = symbAddProc( proc, @id, palias, dtype, subtype, attrib, mode )
    		'' dup def?
    		if( head_proc = NULL ) then
				errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
				'' error recovery: create a fake symbol
				return CREATEFAKEID( proc )
    		end if

    		proc = head_proc

    	else
    		'' already parsed?
    		if( symbGetIsDeclared( head_proc ) ) then
				errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
				'' error recovery: create a fake symbol
				return CREATEFAKEID( proc )
    		end if

    		'' there's already a prototype for this proc, check for
    		'' declaration conflits and fix up the arguments
    		if( hCheckPrototype( head_proc, proc, dtype, subtype ) = FALSE ) then
				'' error recovery: create a fake symbol
				return CREATEFAKEID( proc )
    		end if

    		'' check calling convention
    		if( symbGetProcMode( head_proc ) <> mode ) then
				errReport( FB_ERRMSG_ILLEGALPARAMSPEC, TRUE )
    		end if

    		'' use the prototype
    		proc = head_proc

			hCheckAttribs( proc, attrib )

    		''
    		symbSetIsDeclared( proc )
    	end if
    end if

    ''
    symbSetProcIncFile( proc, env.inf.incfile )

	setUdtPropertyFlags(parent, is_indexed, is_get)

    function = proc

end function

'':::::
''CtorHeader   		=  CDECL? OVERLOAD? (ALIAS LIT_STRING)? Parameters? STATIC? EXPORT?
''
function cCtorHeader _
	( _
		byval attrib as FB_SYMBATTRIB, _
		byref is_nested as integer, _
		byval is_prototype as integer _
	) as FBSYMBOL ptr

	#define CREATEFAKE() symbAddProc( proc, hMakeTmpStr( ), NULL, _
	                                  FB_DATATYPE_VOID, NULL, attrib, mode )

    dim as integer lgt = any, is_extern = any, is_ctor = any
    dim as FBSYMBOL ptr proc = any, parent = any

	function = NULL

	is_nested = FALSE
	is_ctor = (attrib and FB_SYMBATTRIB_CONSTRUCTOR) <> 0
	is_extern = FALSE

	if( is_ctor ) then
		attrib or= FB_SYMBATTRIB_OVERLOADED
	end if

	if( (attrib and FB_SYMBATTRIB_METHOD) <> 0 ) then
		parent = symbGetCurrentNamespc( )

	else
		parent = cParentId( FB_IDOPT_DONTCHKPERIOD or _
							FB_IDOPT_ISDECL or _
							FB_IDOPT_SHOWERROR or _
							FB_IDOPT_ALLOWSTRUCT )

        if( hCheckParent( parent, is_prototype, FB_TK_CONSTRUCTOR ) = FALSE ) then
        	exit function
        end if

		attrib or= FB_SYMBATTRIB_METHOD

		is_extern = TRUE
	end if

	'' [NAKED]
	cNakedAttribute(@attrib)

	'' CallConvention?
	'' ctors and dtors must be always CDECL if passed to REDIM
	dim as FB_FUNCMODE mode = cProcCallingConv( FB_FUNCMODE_CDECL )

	'' OVERLOAD?
	if( lexGetToken( ) = FB_TK_OVERLOAD ) then
		'' allow it for consistency even though it is not needed 
		'' member procs are overloaded by default
		lexSkipToken( )
	end if

	if( is_prototype ) then
		'' [LIB "string"]
		cLibAttribute()
	end if

	'' [ALIAS "id"]
	dim as zstring ptr palias = cAliasAttribute()

	proc = symbPreAddProc( NULL )

	'' extern implementation?
	if( is_prototype = FALSE ) then
		'' must be done before parsing the params
		if( parent <> NULL ) then
			is_nested = hDoNesting( parent )
		end if
	end if

	symbGetAttrib( proc ) = attrib

	'' Parameters?
	cParameters( parent, proc, mode, is_prototype )

	'' dtor?
	if( is_ctor = FALSE ) then
		if( symbGetProcParams( proc ) > 1 ) then
			errReport( FB_ERRMSG_DTORCANTCONTAINPARAMS )
		end if
	else
		'' ctor can't take a byval arg of its own type as only non-optional arg
		if( hCheckIsSelfCloneByval( parent, proc, is_prototype ) ) then
			errReport( FB_ERRMSG_CLONECANTTAKESELFBYVAL, TRUE )
			exit function
		end if

		'' vararg?
		if( symbGetParamMode( symbGetProcTailParam( proc ) ) = FB_PARAMMODE_VARARG ) then
			hParamError( proc, 0, FB_ERRMSG_VARARGPARAMNOTALLOWED )
			'' error recovery: remove the param
			dim as FBSYMBOL ptr param
			param = symbGetProcTailParam( proc )
			symbGetProcTailParam( proc ) = param->prev
			if( param->prev <> NULL ) then
				param->prev->next = NULL
			end if
			symbGetProcParams( proc ) -= 1
			symbFreeSymbol( param )
		end if
	end if

	if( is_prototype ) then
    	proc = symbAddCtor( proc, palias, attrib, mode )
    	if( proc = NULL ) then
    		errReport( FB_ERRMSG_DUPDEFINITION )
    	end if

    	return proc
	end if

	hParseAttributes( attrib, 0, 0 )

    dim as FBSYMBOL ptr head_proc

    '' no preview proc or proto?
    if( is_ctor ) then
    	head_proc = symbGetCompCtorHead( parent )
    else
    	head_proc = symbGetCompDtor( parent )
    end if

    if( head_proc = NULL ) then
    	'' extern decl but no prototype?
    	if( is_extern ) then
			errReport( FB_ERRMSG_DECLOUTSIDECLASS )
    	end if

    	head_proc = symbAddCtor( proc, palias, attrib, mode, FB_SYMBOPT_DECLARING )

    	if( head_proc = NULL ) then
			errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
			'' error recovery: create a fake symbol
			proc = CREATEFAKE()
    	else
    		proc = head_proc
    	end if

    '' another proc or proto defined already..
    else
		'' try to find a prototype with the same signature
    	head_proc = symbFindCtorProc( head_proc, proc )

		'' none found? then try to overload..
    	if( head_proc = NULL ) then
    		'' extern decl but no prototype?
    		if( is_extern ) then
				errReport( FB_ERRMSG_DECLOUTSIDECLASS )
    		end if

    		head_proc = symbAddCtor( proc, palias, attrib, mode, FB_SYMBOPT_DECLARING )

    		'' dup def?
    		if( head_proc = NULL ) then
				errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
				'' error recovery: create a fake symbol
				return CREATEFAKE()
    		end if

    		proc = head_proc

    	else
    		'' already parsed?
    		if( symbGetIsDeclared( head_proc ) ) then
				errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
				'' error recovery: create a fake symbol
				return CREATEFAKE()
    		end if

    		'' there's already a prototype for this operator, check for
    		'' declaration conflits and fix up the arguments
    		if( hCheckPrototype( head_proc, proc, FB_DATATYPE_VOID, NULL ) = FALSE ) then
				'' error recovery: create a fake symbol
				return CREATEFAKE()
    		end if

    		'' check calling convention
    		if( symbGetProcMode( head_proc ) <> mode ) then
				errReport( FB_ERRMSG_ILLEGALPARAMSPEC, TRUE )
    		end if

    		'' use the prototype
    		proc = head_proc

			hCheckAttribs( proc, attrib )

    		''
    		symbSetIsDeclared( proc )
    	end if
	end if

    ''
    symbSetProcIncFile( proc, env.inf.incfile )

    function = proc

end function

'':::::
''ProcStmtBegin	  =	  (PRIVATE|PUBLIC)? STATIC?
''						(SUB|FUNCTION|CONSTRUCTOR|DESTRUCTOR|OPERATOR) ProcHeader .
''
function cProcStmtBegin _
	( _
		byval attrib as FB_SYMBATTRIB _
	) as integer

	dim as integer tkn = any, is_nested = any
    dim as FBSYMBOL ptr proc = any
    dim as ASTNODE ptr procnode = any
    dim as FB_CMPSTMTSTK ptr stk = any

	function = FALSE

#macro hCheckStatic( attrib )
	if( (attrib and FB_SYMBATTRIB_STATIC) <> 0 ) then
		errReport( FB_ERRMSG_MEMBERCANTBESTATIC )
		attrib and= not FB_SYMBATTRIB_STATIC
	end if
#endmacro

	if( (attrib and (FB_SYMBATTRIB_PUBLIC or FB_SYMBATTRIB_PRIVATE)) = 0 ) then
		if( env.opt.procpublic ) then
			attrib or= FB_SYMBATTRIB_PUBLIC
		else
			attrib or= FB_SYMBATTRIB_PRIVATE
		end if
	end if

	cConstOrStaticAttribute( @attrib )

	'' SUB | FUNCTION
	tkn = lexGetToken( )
	select case as const tkn
	case FB_TK_SUB, FB_TK_FUNCTION
    
    case FB_TK_ITERATOR
        attrib or= FB_SYMBATTRIB_ITERATOR or FB_SYMBATTRIB_OVERLOADED

	case FB_TK_CONSTRUCTOR
		if( fbLangOptIsSet( FB_LANG_OPT_CLASS ) = FALSE ) then
			errReportNotAllowed( FB_LANG_OPT_CLASS )
		else
			attrib or= FB_SYMBATTRIB_CONSTRUCTOR
		end if

		hCheckStatic( attrib )

	case FB_TK_DESTRUCTOR
		if( fbLangOptIsSet( FB_LANG_OPT_CLASS ) = FALSE ) then
			errReportNotAllowed( FB_LANG_OPT_CLASS )
		else
			attrib or= FB_SYMBATTRIB_DESTRUCTOR
		end if

		hCheckStatic( attrib )

	case FB_TK_OPERATOR
		if( fbLangOptIsSet( FB_LANG_OPT_OPEROVL ) = FALSE ) then
			errReportNotAllowed( FB_LANG_OPT_OPEROVL )
		else
			attrib or= FB_SYMBATTRIB_OPERATOR or FB_SYMBATTRIB_OVERLOADED
		end if

	case FB_TK_PROPERTY
		if( fbLangOptIsSet( FB_LANG_OPT_CLASS ) = FALSE ) then
			errReportNotAllowed( FB_LANG_OPT_CLASS )
		else
			attrib or= FB_SYMBATTRIB_PROPERTY or FB_SYMBATTRIB_OVERLOADED
		end if

		hCheckStatic( attrib )

	case else
		errReport( FB_ERRMSG_SYNTAXERROR )
		exit function
	end select

	if( cCompStmtIsAllowed( FB_CMPSTMT_MASK_PROC ) = FALSE ) then
    	'' error recovery: skip the whole compound stmt
    	hSkipCompound( tkn )
		exit function
	end if

	lexSkipToken( )

	'' ProcHeader
	select case as const tkn
	case FB_TK_SUB, FB_TK_FUNCTION
		proc = cProcHeader( attrib, is_nested, iif( tkn = FB_TK_SUB, _
		                                            FB_PROCOPT_ISSUB, _
		                                            FB_PROCOPT_NONE ) )
    case FB_TK_ITERATOR
        if( lexGetToken( ) = FB_TK_FUNCTION ) then
            lexSkipToken( )
        else
            errReport( FB_ERRMSG_SYNTAXERROR )
            exit function
        end if
		proc = cProcHeader( attrib, is_nested, FB_PROCOPT_NONE )
                                                    
	case FB_TK_CONSTRUCTOR, FB_TK_DESTRUCTOR
		proc = cCtorHeader( attrib, is_nested, FALSE )

	case FB_TK_OPERATOR
        proc = cOperatorHeader( attrib, is_nested, FB_PROCOPT_NONE )

	case FB_TK_PROPERTY
        proc = cPropertyHeader( attrib, is_nested, FALSE )

	end select

	if( proc = NULL ) then
		exit function
	end if

	'' STATIC or CONST can only be used with member functions
	if( symbGetClass( symbGetNamespace( proc ) ) = FB_SYMBCLASS_NAMESPACE ) then
		if( symbIsStatic( proc ) ) then
			errReport( FB_ERRMSG_ONLYMEMBERFUNCTIONSCANBESTATIC, TRUE )
			symbGetAttrib( proc ) and= not FB_SYMBATTRIB_STATIC
		elseif( symbIsConstant( proc ) ) then
			errReport( FB_ERRMSG_ONLYMEMBERFUNCTIONSCANBECONST, TRUE )
			symbGetAttrib( proc ) and= not FB_SYMBATTRIB_CONST
		end if
	end if

	'' emit proc setup
	procnode = astProcBegin( proc, FALSE )
	if( procnode = NULL ) then
		exit function
	end if

	'' push to stmt stack
	stk = cCompStmtPush( FB_TK_FUNCTION, _
						 FB_CMPSTMT_MASK_DEFAULT or FB_CMPSTMT_MASK_DATA )

	stk->proc.tkn = tkn
	stk->proc.node = procnode
	stk->proc.is_nested = is_nested

	stk->proc.cmplabel = NULL
	stk->proc.endlabel = astGetProcExitlabel( procnode )

	'' init
	astAdd( astNewLABEL( astGetProcInitlabel( procnode ) ) )

	function = TRUE

end function

'':::::
''ProcStmtEnd	  =	  END (SUB | FUNCTION) .
''
function cProcStmtEnd _
	( _
		_
	) as integer static

	dim as FB_CMPSTMTSTK ptr stk

	function = FALSE 
    
	stk = cCompStmtGetTOS( FB_TK_FUNCTION )
	if( stk = NULL ) then
		exit function
	end if

	'' END
	lexSkipToken( )

	dim as integer res
    dim as FBSYMBOL ptr proc_current
    proc_current = parser.currproc

    if( symbIsIterator( proc_current ) = TRUE ) then
        res = hMatch( FB_TK_FUNCTION )
    else
        res = hMatch( stk->proc.tkn )
    end if
    
	if( res = FALSE ) then
		select case stk->proc.tkn
		case FB_TK_SUB
			errReport( FB_ERRMSG_EXPECTEDENDSUB )
		case FB_TK_FUNCTION
			errReport( FB_ERRMSG_EXPECTEDENDFUNCTION )
		case FB_TK_CONSTRUCTOR
			errReport( FB_ERRMSG_EXPECTEDENDCTOR )
		case FB_TK_DESTRUCTOR
			errReport( FB_ERRMSG_EXPECTEDENDDTOR )
		case FB_TK_OPERATOR
			errReport( FB_ERRMSG_EXPECTEDENDOPERATOR )
		case FB_TK_PROPERTY
			errReport( FB_ERRMSG_EXPECTEDENDPROPERTY )
		case FB_TK_ITERATOR
            errReport( FB_ERRMSG_EXPECTEDENDFUNCTION )
		end select
	end if

	'' function and the result wasn't set?
	dim as FBSYMBOL ptr proc_res

	proc_res = symbGetProcResult( parser.currproc )
	if( proc_res <> NULL ) then
		if( symbGetIsAccessed( proc_res ) = FALSE ) then
			if ((parser.currproc->attrib and FB_SYMBATTRIB_NAKED)) = 0 then
				errReportWarn( FB_WARNINGMSG_NOFUNCTIONRESULT )
			end if
		end if
	end if

    '' always finish
	function = astProcEnd( stk->proc.node, FALSE )

    '' was the namespace changed?
	if( stk->proc.is_nested ) then
		symbNestEnd( TRUE )
	end if

	'' pop from stmt stack
    cCompStmtPop( stk )
    
	if( res = FALSE ) then
		function = FALSE
	end if

end function

function hBuildArgFunnelDefinition(  _
    byval proc as FBSYMBOL ptr, _
    byval is_funnel as integer, _
    byval is_proto as integer,  _
    byval dtype as FB_DATATYPE, _
    byval subtype as FBSYMBOL ptr _
) as FBSYMBOL ptr
    dim as zstring  * FB_MAXNAMELEN+1 funnel_proc_id
    dim as FBSYMBOL ptr               funnel_proc, head_proc
    dim as FBSYMBOL ptr               param_proc, param_funnel
    dim as FBSYMBOL ptr               proc_funnel_subtype
    dim as FB_DATATYPE proc_funnel_dtype
    dim as integer proc_funnel_attrib
    dim as integer proc_funnel_mode
    dim as integer is_nested
    
    function = NULL
    
    '' copy proc attributes
    if( is_funnel = TRUE ) then
        funnel_proc_id = symbGetProcFunnelName( proc )
    else
        funnel_proc_id = symbGetProcScatterName( proc )
    end if
    
    funnel_proc = symbPreAddProc( @funnel_proc_id )
    if( is_proto = FALSE ) then
        if( symbGetParent( proc ) <> NULL ) then
            is_nested = hDoNesting( symbGetParent( proc ) )
        end if
    end if
    
    '' copy parameters
    if( is_funnel = TRUE ) then
        '' ...from args to heap
        param_proc = symbGetProcHeadParam( proc )
        for i as integer = 1 to symbGetProcParams( proc ) 
            dim as ASTNODE ptr optexpr = NULL
            if( symbGetParamOptExpr( param_proc ) <> NULL ) then
                optexpr = astCloneTree( symbGetParamOptExpr( param_proc ) )
            end if
        
            param_funnel = symbAddProcParam(    _
                funnel_proc,                    _
                symbGetName( param_proc ),      _
                symbGetFullType( param_proc ),  _
                symbGetSubType( param_proc ),   _
                symbGetLen( param_proc ),       _
                symbGetParamMode( param_proc ), _
                symbGetAttrib( param_proc ),    _
                optexpr                         _
            )
            
            param_proc = symbGetParamNext( param_proc )
        next i

        '' define function
        proc_funnel_dtype = FB_DATATYPE_ITER
        proc_funnel_subtype = symbAddIter( dtype, subtype )
        proc_funnel_attrib = ( symbGetAttrib( proc ) or FB_SYMBOPT_RTL ) and (not FB_SYMBATTRIB_ITERATOR)
        proc_funnel_mode = symbGetProcMode( proc )
    else
        '' ...from heap to args
        param_funnel = symbAddProcParam(              _
            funnel_proc,                              _
            @"funnneled_arg",                         _
            typeAddrOf( FB_DATATYPE_VOID ),           _
            NULL,                                     _
            symbCalcLen( FB_DATATYPE_POINTER, NULL ), _
            FB_PARAMMODE_BYVAL,                       _
            FB_SYMBATTRIB_PARAMBYVAL,                 _
            NULL                                      _
        )
        
        proc_funnel_dtype = FB_DATATYPE_VOID
        proc_funnel_subtype = NULL
        proc_funnel_attrib = FB_SYMBATTRIB_NONE
        proc_funnel_mode = env.target.fbcall
    end if

    symbGetAttrib( funnel_proc ) = proc_funnel_attrib
    
    if( is_proto ) then
        head_proc = symbAddPrototype(       _
            funnel_proc,                    _
            @funnel_proc_id,                _
            NULL,                           _
            proc_funnel_dtype,              _
            proc_funnel_subtype,            _
            proc_funnel_attrib,             _
            proc_funnel_mode                _
        )
    else
        head_proc = symbAddProc(            _
            funnel_proc,                    _
            @funnel_proc_id,                _
            NULL,                           _
            proc_funnel_dtype,              _
            proc_funnel_subtype,            _
            proc_funnel_attrib,             _
            proc_funnel_mode                _
        ) 
    end if
            
    if( head_proc = NULL ) then
		errReport( FB_ERRMSG_DUPDEFINITION, TRUE )
		'' error recovery: create a fake symbol
		dim dtype as FB_DATATYPE = FB_DATATYPE_VOID
        dim subtype as FBSYMBOL ptr = NULL
        dim attrib as integer = symbGetAttrib( proc )
        dim mode as integer = symbGetProcMode( proc )
        dim procnode as ASTNODE ptr = NULL
        funnel_proc = CREATEFAKEID( funnel_proc )
    else
    	funnel_proc = head_proc
    end if
    
    function = funnel_proc
end function

sub hBuildArgFunnelEntry(  _
    byval funnel_proc as FBSYMBOL ptr, _
    byval is_nested as integer _
) 
    dim as ASTNODE ptr                funnel_proc_node
	dim as FB_CMPSTMTSTK ptr          stk

    symbSetProcIncFile( funnel_proc, env.inf.incfile )
    
    '' enter function
	funnel_proc_node = astProcBegin( funnel_proc, FALSE )
	if( funnel_proc_node = NULL ) then
		exit sub
	end if

	'' push to stmt stack
	stk = cCompStmtPush( FB_TK_FUNCTION, _
						 FB_CMPSTMT_MASK_DEFAULT or FB_CMPSTMT_MASK_DATA )
	stk->proc.tkn = FB_TK_ITERATOR
	stk->proc.node = funnel_proc_node
	stk->proc.is_nested = is_nested
	stk->proc.cmplabel = NULL
	stk->proc.endlabel = astGetProcExitlabel( funnel_proc_node )

	'' init
	astAdd( astNewLABEL( astGetProcInitlabel( funnel_proc_node ) ) )
end sub

function hBuildArgScatter(     _
    byval proc as FBSYMBOL ptr, _
    byval is_nested_in as integer _
) as FBSYMBOL ptr
    dim as string name_scatter
    dim as FBSYMBOL ptr proc_scatter, proc_symbol
    dim as FBSYMCHAIN ptr chain_scatter
    dim as FBSYMBOL ptr param, param_heap
    dim as ASTNODE ptr call_node, rhs
    dim as integer offset   
    dim as integer is_nested
    is_nested = is_nested_in
    function = NULL
    
    if( proc = NULL ) then
        exit function
    end if
    
    '' name should already exist if properly declared
    name_scatter = symbGetProcScatterName( proc )
    chain_scatter = symbLookupAt( symbGetParent( proc ), name_scatter, FALSE, FALSE )
    if( chain_scatter = NULL ) then
        proc_scatter = hBuildArgFunnelDefinition( proc, FALSE, FALSE )
    else
        proc_scatter = symbFindByClass( chain_scatter, FB_SYMBCLASS_PROC )
        if( symbGetParent( proc ) <> null ) then
            is_nested = hDoNesting( symbGetParent( proc ) )
        end if
    end if
    
    '' call original procedure
    hBuildArgFunnelEntry( proc_scatter, is_nested )
    param_heap = symbGetProcFirstParam( proc_scatter )
    call_node = astNewCALL( proc )
    
    '' get heaped arguments    
    param = symbGetProcLastParam( proc )
    offset = 0
    for i as integer = 1 to symbGetProcParams( proc )
        dim as FB_DATATYPE dtype
        dim as FBSYMBOL ptr subtype
        dtype = symbGetFullType( param )
        subtype = symbGetSubtype( param )
        if( symbGetParamMode( param ) = FB_PARAMMODE_BYREF ) then
            dtype = typeAddrOf( dtype )
        end if
        
        rhs = astNewVAR( symbGetParamVar( param_heap ), 0, typeAddrOf( FB_DATATYPE_VOID ), NULL )
        rhs = astNewBOP( AST_OP_ADD, rhs, astNewCONSTi( offset ) )
        rhs = astNewCONV( typeAddrOf( dtype ), subtype, rhs )
        rhs = astNewDEREF( rhs )
        
        if( symbGetParamMode( param ) = FB_PARAMMODE_BYREF ) then
            astNewARG( call_node, rhs, , FB_PARAMMODE_BYVAL )
        else
            astNewARG( call_node, rhs )
        end if

        offset += symbGetLen( param )
        param = symbGetProcPrevParam( proc, param )
    next i
    
    astAdd( call_node )
    
    '' free argument heap
    proc_symbol = rtlProcLookup( "deallocate", FB_RTL_IDX_DEALLOCATE )
    call_node = astNewCALL( proc_symbol )
    rhs = astNewVAR( symbGetParamVar( param_heap ), 0, typeAddrOf( FB_DATATYPE_VOID ), NULL )
    astNewARG( call_node, rhs )
    astAdd( call_node )
    
    hBuildArgFunnelExit( )
    
    function = proc_scatter
end function

function hBuildArgFunnel(          _
    byval proc as FBSYMBOL ptr,    _
    byval is_nested_in as integer, _
    byval dtype as FB_DATATYPE,    _
    byval subtype as FBSYMBOL ptr  _
) as FBSYMBOL ptr
    dim as string name_funnel, name_scatter
    dim as FBSYMCHAIN ptr chain_funnel, chain_scatter
    dim as FBSYMBOL ptr proc_funnel, proc_scatter, proc_symbol
    dim as FBSYMBOL ptr param, param_heap, result
    dim as ASTNODE ptr call_node, lhs, rhs
    dim as integer stack_size, is_nested
    is_nested = is_nested_in
    
    function = NULL
    
    if( proc = NULL ) then
        exit function
    end if
    
    '' names should already exist if properly declared
    name_funnel = symbGetProcFunnelName( proc )
    name_scatter = symbGetProcScatterName( proc )
	chain_funnel = symbLookupAt( symbGetParent( proc ), name_funnel, FALSE, FALSE )
    chain_scatter = symbLookupAt( symbGetParent( proc ), name_scatter, FALSE, FALSE )
    if( chain_scatter = NULL ) then
        exit function
    else
        proc_scatter = symbFindByClass( chain_scatter, FB_SYMBCLASS_PROC )
    end if
    if( chain_funnel = NULL ) then
        proc_funnel = hBuildArgFunnelDefinition( proc, TRUE, FALSE, dtype, subtype )
    else
        proc_funnel = symbFindByClass( chain_funnel, FB_SYMBCLASS_PROC )
        if( symbGetParent( proc ) <> null ) then
            is_nested = hDoNesting( symbGetParent( proc ) )
        end if
    end if
    
    hBuildArgFunnelEntry( proc_funnel, is_nested )
    
    '' Calculate stack size
    param = symbGetProcFirstParam( proc_funnel )
    stack_size = 0
    for i as integer = 1 to symbGetProcParams( proc_funnel )
        stack_size += symbGetLen( param )
        param = symbGetProcNextParam( proc_funnel, param )
    next i
    
    '' dim arg_heap as any ptr = allocate( sizeof( params ) )
    param_heap = symbAddTempVar( typeAddrOf( FB_DATATYPE_VOID ), NULL, FALSE, FALSE )
    proc_symbol = rtlProcLookup( "allocate", FB_RTL_IDX_ALLOCATE )
    rhs = astNewCALL( proc_symbol )
    astNewARG( rhs, astNewCONSTi( stack_size ) )
    lhs = astNewVAR( param_heap, 0, typeAddrOf( FB_DATATYPE_VOID ), NULL )
    astAdd( astNewASSIGN( lhs, rhs ) )

    '' memcpy *CPtr(UByte ptr, arg_heap), first_arg, sizeof( params )
    param = symbGetProcLastParam( proc_funnel )
    if( symbGetParamMode( param ) = FB_PARAMMODE_BYREF ) then
        rhs = astNewVAR( symbGetParamVar( param ), 0, typeAddrOf( symbGetFullType( param ) ), symbGetSubtype( param ) )
    else
        rhs = astNewVAR( symbGetParamVar( param ), 0, symbGetFullType( param ), symbGetSubtype( param ) )
    end if
    lhs = astNewVAR( param_heap, 0, typeAddrOf( FB_DATATYPE_VOID ), NULL )
    lhs = astNewCONV( typeAddrOf( FB_DATATYPE_BYTE ), NULL, lhs )
    lhs = astNewDEREF( lhs )
    astAdd( rtlMemCopy( lhs, rhs, stack_size ) )
    
    '' Debug
    /'
    rtlPrint( NULL, FALSE, FALSE, astNewCONSTstr( "" ) )
    rtlPrint( NULL, FALSE, FALSE, astNewCONSTstr( "START STACK DUMP" ) )
    for i as integer = 1 to stack_size
        rhs = astNewVAR( param_heap, 0, typeAddrOf( FB_DATATYPE_VOID ), NULL )
        rhs = astNewCONV( typeAddrOf( FB_DATATYPE_UBYTE ), NULL, rhs )
        rhs = astNewBOP( AST_OP_ADD, rhs, astNewCONSTi( i-1 ) )
        rhs = astNewDEREF( rhs )
        rtlPrint( NULL, FALSE, TRUE, rhs )
        rtlPrint( NULL, FALSE, TRUE, astNewCONSTstr( " " ) )
    next i
    rtlPrint( NULL, FALSE, FALSE, astNewCONSTstr( "" ) )
    rtlPrint( NULL, FALSE, FALSE, astNewCONSTstr( "END STACK DUMP" ) )
    rtlPrint( NULL, FALSE, FALSE, astNewCONSTstr( "" ) )
    '/
    
    '' Create iterator's fiber
    proc_symbol = rtlProcLookup( @"fb_FiberIterCreate", FB_RTL_IDX_FIBERITERCREATE )
    call_node = astNewCALL( proc_symbol )
    rhs = astNewVAR( proc_scatter, 0, FB_DATATYPE_FUNCTION, proc_scatter )
    rhs = astNewADDROF( rhs )
    astNewARG( call_node, rhs )
    rhs = astNewVAR( param_heap, 0, typeAddrOf( FB_DATATYPE_VOID ), NULL )
    astNewARG( call_node, rhs )
        
    '' Return execution pointer
    result = symbGetProcResult( proc_funnel )
    symbSetProcStatReturnUsed( proc_funnel )
	parser.ctxsym    = NULL
	parser.ctx_dtype = FB_DATATYPE_INVALID
    symbSetIsAccessed( result )
	astAdd( astNewASSIGN( astBuildProcResultVar( proc_funnel, result ), call_node ) )
    
    '' exit function
    hBuildArgFunnelExit( )
    
    function = proc_funnel
end function
    
function hBuildArgFunnelExit (  ) as integer
	dim as FB_CMPSTMTSTK ptr stk
    
    function = FALSE

	stk = cCompStmtGetTOS( FB_TK_FUNCTION )
	if( stk = NULL ) then
		exit function
	end if
       
    '' always finish
	function = astProcEnd( stk->proc.node, FALSE )

	'' was the namespace changed?
	if( stk->proc.is_nested ) then
		symbNestEnd( TRUE )
	end if

	'' pop from stmt stack
	cCompStmtPop( stk )
    
    function = TRUE
    exit function
end function
