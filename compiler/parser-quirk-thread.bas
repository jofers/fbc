'' quick threadcall implementation
''
'' chng: oct/2011 written [jofers]

#include once "fb.bi"
#include once "fbint.bi"
#include once "parser.bi"

#include once "ast.bi"
#include once "rtl.bi"

'':::::
'' ThreadCallFunc =   THREADCALL proc_call
''
function cThreadCallFunc( ) as ASTNODE ptr
    dim as FBSYMBOL ptr sym, result
    dim as FBSYMCHAIN ptr chain_
    dim as integer check_paren
    dim as FB_CALL_ARG_LIST arg_list = ( 0, NULL, NULL )
    dim as ASTNODE ptr childcall 
    
    function = NULL
    
    '' THREADCALL
    lexSkipToken( )
    
    '' proc 
    chain_ = cIdentifier( NULL, FB_IDOPT_DEFAULT or FB_IDOPT_ALLOWSTRUCT )
    if( chain_ = NULL ) then
        exit function
    end if

    '' get symbol
    sym = symbFindByClass( chain_, FB_SYMBCLASS_PROC )
    if sym = NULL then
        errReport( FB_ERRMSG_EXPECTEDSUB )
        exit function
    end if
    
    '' must be a sub
    result = symbGetProcResult( sym )
    if( result <> NULL ) then
        if( symbGetType( result ) <> FB_DATATYPE_VOID ) then
            errReport( FB_ERRMSG_EXPECTEDSUB )
            exit function
        end if
    end if

    lexSkipToken( )
    
    '' '('?
    if( hMatch( CHAR_LPRNT ) = FALSE ) then
        dim params as integer
        params = symbGetProcParams( sym )
        if( params > 0 ) then
            errReport( FB_ERRMSG_EXPECTEDLPRNT )
            exit function
        end if
    else
        check_paren = TRUE
    end if
    
    '' arg_list
    childcall = cProcArgList( NULL, sym, NULL, @arg_list, 0 )

    '' ')'?
    if( check_paren = TRUE ) then
        if( lexGetToken( ) <> CHAR_RPRNT ) then
            errReport( FB_ERRMSG_EXPECTEDRPRNT )
            exit function
        end if
        lexSkipToken( )
    end if

    '' transform the call into a threadcall
	function = rtlThreadCall( childcall )
end function

function cYieldStmt( ) as integer
    dim expr as ASTNODE ptr
    dim id as string
    dim proc_funnel as FBSYMCHAIN ptr
    dim proc_iter as FBSYMBOL ptr
    dim proc_fiberyield as FBSYMBOL ptr
    dim call_fiberyield as ASTNODE ptr
    dim dtype as FB_DATATYPE
    dim subtype as FBSYMBOL ptr
    
    function = FALSE
    
    '' inside an iterator?
    if( symbIsIterator( parser.currproc ) = FALSE ) then
        errReport( FB_ERRMSG_ILLEGALOUTSIDEITERATOR )
        exit function
    end if

    '' YIELD
    lexSkipToken( )
    
    '' yielded expression
    expr = cExpression( )
    if( expr = NULL ) then
        exit function
    end if
    
    '' find iterator type
    id = symbGetProcFunnelName( parser.currproc )
    proc_funnel = symbLookupAt( symbGetParent( parser.currproc ), id, FALSE, FALSE )
    if( proc_funnel = NULL ) then
        exit function
    end if
    proc_iter = symbGetSubtype( proc_funnel->sym )
    if( proc_iter = NULL ) then
        exit function
    end if
    dtype = symbGetFullType( proc_iter )
    subtype = symbGetSubtype( proc_iter )
    
    '' numerical, incompatible type?  Attempt to cast
    dim as integer exprIsNumerical = FALSE, iterIsNumerical = FALSE
    select case typeGetClass( dtype )
        case FB_DATACLASS_INTEGER, FB_DATACLASS_FPOINT
            iterIsNumerical = TRUE
    end select
    select case astGetDataClass( expr )
        case FB_DATACLASS_INTEGER, FB_DATACLASS_FPOINT
            exprIsNumerical = TRUE
    end select
    if(( exprIsNumerical = TRUE and iterIsNumerical = TRUE ) and _
       ( dtype <> astGetFullType( expr ) ) and _
       (( subtype = NULL ) and ( astGetSubType( expr ) = NULL ))) then
        '' create variable, store expr casted to iter type
        dim as FBSYMBOL ptr symb
        dim as ASTNODE ptr rhs, lhs
        symb = symbAddTempVar( dtype, NULL, FALSE, FALSE )
        lhs = astNewVAR( symb, 0, dtype, NULL )
        rhs = astNewCONV( dtype, NULL, expr )
        astAdd( astNewASSIGN( lhs, rhs ))
        expr = astNewVAR( symb, 0, dtype, NULL )
    end if
    
    '' call FIBERYIELD( expr ), and modify parameter to suit our needs
    proc_fiberyield = rtlProcLookup( @"fiberyield", FB_RTL_IDX_FIBERYIELD )
    dim as FBSYMBOL ptr param = symbGetProcHeadParam( proc_fiberyield )
    symbGetFullType( param ) = dtype
    symbGetSubtype( param ) = subtype
    symbGetParamMode( param ) = FB_PARAMMODE_BYREF
    
    call_fiberyield = astNewCALL( proc_fiberyield )
    if( call_fiberyield = NULL ) then
        exit function
    end if
    astNewARG( call_fiberyield, expr )
    astAdd( call_fiberyield )
    
    function = TRUE
end function
