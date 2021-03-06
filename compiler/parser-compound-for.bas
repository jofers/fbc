'' FOR..NEXT compound statement parsing
''
'' chng: sep/2004 written [v1ctor]


#include once "fb.bi"
#include once "fbint.bi"
#include once "parser.bi"
#include once "ast.bi"
#include once "rtl.bi"

enum FOR_FLAGS
    FOR_ISUDT			= &h0001
    FOR_HASCTOR			= &h0002
    FOR_ISLOCAL			= &h0004
end enum

#define CREATEFAKEID( ) _
	astNewVAR( symbAddTempVar( FB_DATATYPE_INTEGER ), 0, FB_DATATYPE_INTEGER )

declare function hUdtCallOpOvl _
	( _
		byval parent as FBSYMBOL ptr, _
		byval op as AST_OP, _
		byval inst_expr as ASTNODE ptr, _
		byval second_arg as ASTNODE ptr, _
		byval third_arg as ASTNODE ptr = NULL _
	) as ASTNODE ptr

declare sub hFlushBOP _
	( _
		byval op as integer, _
	 	byval lhs as FB_CMPSTMT_FORELM ptr, _
		byval rhs as FB_CMPSTMT_FORELM ptr, _
		byval ex as FBSYMBOL ptr _
	)

declare sub hFlushSelfBOP _
	( _
		byval op as integer, _
	 	byval lhs as FB_CMPSTMT_FORELM ptr, _
		byval rhs as FB_CMPSTMT_FORELM ptr _
	)
    
declare function hIterIsForeachCompatible _
    ( _
        byval itertype as FBSYMBOL ptr, _
        byval idexpr as FBSYMBOL ptr, _
        byval stk as FB_CMPSTMTSTK ptr _
    ) as integer

declare function hGetForeachMethod _
    ( _
        byval udt as FBSYMBOL ptr, _
        byval id as zstring ptr, _
        byref itertype as FBSYMBOL ptr _
    ) as FBSYMBOL ptr

declare function hCheckAndInitializeForeachCall _
    ( _
        byval ctnexpr as ASTNODE ptr, _
        byval idexpr as ASTNODE ptr, _
        byval stk as FB_CMPSTMTSTK ptr _
    ) as integer
declare function hIterStep _
    ( _
		byval stk as FB_CMPSTMTSTK ptr _
    ) as integer
    
''::::
private function hElmToExpr _
	( _
	 	byval v as FB_CMPSTMT_FORELM ptr _
	) as ASTNODE ptr

    '' This function creates an AST node using the value
    '' contained in the FB_CMPSTMT_FORELM. The structure
    '' either contains a symbol, which is used, or if no
    '' symbol is found then the embedded value is used to
    '' create a constant, which is used instead.
    '' The AST node is returned.

	'' if there's an embedded symbol, use it
	if( v->sym <> NULL ) then
		function = astNewVAR( v->sym, 0, v->dtype, symbGetSubType( v->sym ) )

	'' make a constant...
	else
		function = astNewCONST( @v->value, v->dtype )
	end if

end function

'':::::
private sub hUdtFor _
	( _
		byval stk as FB_CMPSTMTSTK ptr _
	)

	dim as ASTNODE ptr proc = any, step_expr = NULL

	'' only pass the step arg if it's an explicit step
	if( stk->for.explicit_step ) then
		step_expr = hElmToExpr( @stk->for.stp )
	end if

	proc = hUdtCallOpOvl( symbGetSubtype( stk->for.cnt.sym ), _
						  AST_OP_FOR, _
					  	  hElmToExpr( @stk->for.cnt ), _
					  	  step_expr )

	if( proc <> NULL ) then
    	astAdd( proc )
	end if

end sub

'':::::
private sub hUdtStep _
	( _
		byval stk as FB_CMPSTMTSTK ptr _
	)

	dim as ASTNODE ptr proc = any, step_expr = NULL
    dim as ASTNODE ptr idexpr = any
    dim as ASTNODE ptr asgnexpr = any

    '' only pass the step arg if it's an explicit step
    if( stk->for.explicit_step ) then
        step_expr = hElmToExpr( @stk->for.stp )
    end if

    proc = hUdtCallOpOvl( symbGetSubtype( stk->for.cnt.sym ), _
                          AST_OP_STEP, _
                          hElmToExpr( @stk->for.cnt ), _
                          step_expr )

    if( proc <> NULL ) then
        astAdd( proc )
    end if                              

end sub

'':::::
private sub hEachUdtNext _
    ( _
        byval stk as FB_CMPSTMTSTK ptr _
    )
    
    '' FOREACH: proc = begin_iter <> end_iter
    dim as FBSYMBOL ptr subtype = symbGetSubType( stk->for.stp.sym )
    dim as ASTNODE ptr beginvar = NULL, endvar = NULL
    dim as ASTNODE ptr proc
    
    beginvar = astNewVAR( stk->for.stp.sym, 0, FB_DATATYPE_STRUCT, subtype )
    if( beginvar <> NULL ) then
        subtype = symbGetSubType( stk->for.end.sym )
    end if
    if( subtype <> NULL ) then
        endvar = astNewVAR( stk->for.end.sym, 0, FB_DATATYPE_STRUCT, subtype )
    end if
    if( endvar <> NULL ) then
        proc = astNewBop( AST_OP_NE, beginvar, endvar )
    end if
    
    if( proc <> NULL ) then
    	'' if proc(...) <> 0 then goto init
    	astAdd( astNewBOP( AST_OP_NE, _
    				   	   proc, _
    				   	   astNewCONSTi( 0 ), _
    				   	   stk->for.inilabel, _
    				   	   AST_OPOPT_NONE ) )
    end if
end sub 

'':::::
private sub hUdtNext _
	( _
		byval stk as FB_CMPSTMTSTK ptr _
	)

	dim as ASTNODE ptr proc = any, step_expr = NULL
    
    '' only pass the step arg if it's an explicit step
    if( stk->for.explicit_step ) then
        step_expr = hElmToExpr( @stk->for.stp )
    end if

    proc = hUdtCallOpOvl( symbGetSubtype( stk->for.cnt.sym ), _
                          AST_OP_NEXT, _
                          hElmToExpr( @stk->for.cnt ), _
                          hElmToExpr( @stk->for.end ), _
                          step_expr )
                              
    if( proc <> NULL ) then
    	'' if proc(...) <> 0 then goto init
    	astAdd( astNewBOP( AST_OP_NE, _
    				   	   proc, _
    				   	   astNewCONSTi( 0 ), _
    				   	   stk->for.inilabel, _
    				   	   AST_OPOPT_NONE ) )
	end if

end sub

'':::::
private sub hEachUdtStep _
    ( _
		byval stk as FB_CMPSTMTSTK ptr _
    )
    dim sym as FBSYMBOL ptr
    dim iter_subtype as FBSYMBOL ptr = symbGetSubType( stk->for.stp.sym ) 
    dim id_subtype as FBSYMBOL ptr = symbGetSubType( stk->for.cnt.sym ) 

    dim iter_var as ASTNODE ptr = NULL, proc as ASTNODE ptr = NULL
    dim as ASTNODE ptr asgnexpr = NULL, idexpr = NULL

    iter_var = astNewVAR( stk->for.stp.sym, 0, FB_DATATYPE_STRUCT, iter_subtype )

    '' count_var = *iter_var
    if( iter_var <> NULL ) then
        proc = astNewUOP( AST_OP_DEREF, iter_var )
    end if
    if( proc <> NULL ) then
        idexpr = astNewVAR( stk->for.cnt.sym, 0, symbGetType( stk->for.cnt.sym ), id_subtype )
    end if
    if( idexpr <> NULL ) then
        asgnexpr = astNewASSIGN( idexpr, proc )
    end if
    if( asgnexpr <> NULL ) then
        astAdd( asgnexpr )

        '' increment iter
        proc = hUdtCallOpOvl( symbGetSubtype( stk->for.stp.sym ), _
                              AST_OP_INC_SELF, _
                              hElmToExpr( @stk->for.stp ), _
                              NULL )
    end if
                              
    if( proc <> NULL ) then
        astAdd( proc )
    end if

end sub

'':::::
private sub hEachIterStepNext _
    ( _
		byval stk as FB_CMPSTMTSTK ptr _
    )

    dim sym as FBSYMBOL ptr
    dim yield_result_sym as FBSYMBOL ptr
    dim yield_result_var as ASTNODE ptr
    dim yield_branch as ASTNODE ptr
    dim proc_call as ASTNODE ptr
    dim iter_subtype as FBSYMBOL ptr = symbGetSubType( stk->for.stp.sym ) 

    dim iter_var as ASTNODE ptr = NULL, cnt_var as ASTNODE ptr
    
    '' FIBERSWITCH( iter )
    iter_var = astNewVAR( stk->for.stp.sym, 0, typeAddrOf( FB_DATATYPE_VOID ), NULL )
    if( iter_var <> NULL ) then
        sym = rtlProcLookup( @"fiberswitch", FB_RTL_IDX_FIBERSWITCH )
    end if
    if( sym <> NULL ) then
        proc_call = astNewCALL( sym )
    end if
    if( proc_call <> NULL ) then
        astNewARG( proc_call, iter_var )
        proc_call = astAdd( proc_call )
    end if
    
    '' yield_result_ptr = FIBERGETYIELD( iter )
    if( proc_call <> NULL ) then
        sym = rtlProcLookup( @"fibergetyield", FB_RTL_IDX_FIBERGETYIELD )
    end if
    if( sym <> NULL ) then
        iter_var = astNewVAR( stk->for.stp.sym, 0, typeAddrOf( FB_DATATYPE_VOID ), NULL )
    end if
    if( iter_var <> NULL ) then
        proc_call = astNewCALL( sym )
    end if
    if( proc_call <> NULL ) then
        astNewARG( proc_call, iter_var )
        yield_result_sym = symbAddTempVar( typeAddrOf( symbGetFullType( iter_subtype ) ), symbGetSubtype( iter_subtype ), FALSE, FALSE )
    end if
    if( yield_result_sym <> NULL ) then
        yield_result_var = astNewVAR( yield_result_sym, 0, symbGetFullType( yield_result_sym ), symbGetSubtype( yield_result_sym ) )
    end if
    if( yield_result_var <> NULL ) then
        astAdd( astNewASSIGN( yield_result_var, proc_call ) )
    end if
    
    '' if yield_result_ptr = NULL then goto endlabel
    if( yield_result_var <> NULL ) then
        yield_result_var = astNewVAR( yield_result_sym, 0, symbGetFullType( yield_result_sym ), symbGetSubtype( yield_result_sym ) )
    end if
    if( yield_result_var <> NULL ) then
        yield_branch = astNewBOP( AST_OP_EQ, yield_result_var, astNewCONSTi( 0 ), stk->for.endlabel, AST_OPOPT_NONE )
    end if
    if( yield_branch <> NULL ) then
        astAdd( yield_branch )
    end if
    
    '' else count = *yield_result_var
    if( yield_branch <> NULL ) then
        cnt_var = astNewVAR( stk->for.cnt.sym, 0, symbGetFullType( stk->for.cnt.sym ), symbGetSubtype( stk->for.cnt.sym ) )
    end if
    if( cnt_var <> NULL ) then
        yield_result_var = astNewVAR( yield_result_sym, 0, symbGetFullType( yield_result_sym ), symbGetSubtype( yield_result_sym ) )
    end if
    if( yield_result_var <> NULL ) then
        yield_result_var = astNewDEREF( yield_result_var )
    end if
    if( yield_result_var <> NULL ) then
        astAdd( astNewASSIGN( cnt_var, yield_result_var ) )
    end if
        
end sub

'':::::
private sub hScalarStep _
	( _
		byval stk as FB_CMPSTMTSTK ptr _
	)

	'' counter += step
	hFlushSelfBOP( AST_OP_ADD_SELF, @stk->for.cnt, @stk->for.stp )

end sub

'':::::
private sub hScalarNext _
	( _
		byval stk as FB_CMPSTMTSTK ptr _
	)

    '' is STEP known? (ie: an constant expression)
    if( stk->for.ispos.sym = NULL ) then
    	'' counter <= or >= end cond?
		hFlushBOP( iif( stk->for.ispos.value.int, AST_OP_LE, AST_OP_GE ), _
			   	   @stk->for.cnt, _
			   	   @stk->for.end, _
			   	   stk->for.inilabel )

    '' STEP unknown, check sign and branch
    else
		dim as FBSYMBOL ptr cl = symbAddLabel( NULL )

		'' if ispositive = FALSE then
		astAdd( astNewBOP( AST_OP_NE, _
					   	   hElmToExpr( @stk->for.ispos ), _
					   	   astNewCONSTi( 0 ), _
					   	   cl, _
					   	   AST_OPOPT_NONE ) )

    		'' if counter >= end_condition then
	    		'' goto top_of_FOR
				hFlushBOP( AST_OP_GE, @stk->for.cnt, @stk->for.end, stk->for.inilabel )

			'' else
				'' goto skip_positive_check
				astAdd( astNewBRANCH( AST_OP_JMP, stk->for.endlabel ) )

			'' end if

    	'' else
    	astAdd( astNewLABEL( cl, FALSE ) )

    		'' if cnt <= end then goto for_ini
			hFlushBOP( AST_OP_LE,  @stk->for.cnt, @stk->for.end, stk->for.inilabel )

		'' end if

		'' skip_positive_check:
    end if

end sub

'':::::
private function hAllocTemp _
	( _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr _
	) as FBSYMBOL ptr

    '' make a temp symbol
	dim as FBSYMBOL ptr s = symbAddTempVar( dtype, subtype )

    '' lang QB doesn't allow UDT's anyway...
    if( env.clopt.lang <> FB_LANG_QB ) then
		symbUnsetIsTemp(s)
	end if

    function = s

end function

'':::::
private function hStoreTemp _
	( _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval expr as ASTNODE ptr _
	) as FBSYMBOL ptr

	'' This function creates a temporary symbol,
	'' which then has the expression 'expr' stored
	'' into it. The symbol is returned.
	dim as FBSYMBOL ptr s = hAllocTemp( dtype, subtype )

    '' expr is assigned into the symbol
	expr = astNewASSIGN( astNewVAR( s, 0, dtype, subtype ), expr )

	'' couldn't assign?
	if( expr = NULL ) then
		select case as const typeGet( dtype )
		'' TYPE or CLASS
		case FB_DATATYPE_STRUCT ', FB_DATATYPE_CLASS
			errReport( FB_ERRMSG_INVALIDDATATYPES )
		case else
			errReport( FB_ERRMSG_UDTINFORNEEDSOPERATORS, TRUE, _
			           astGetOpId( AST_OP_ASSIGN ) )
		end select
	else
		'' add to AST
		astAdd( expr )
	end if

	function = s

end function

'':::::
private sub hFlushBOP _
	( _
		byval op as integer, _
	 	byval lhs as FB_CMPSTMT_FORELM ptr, _
		byval rhs as FB_CMPSTMT_FORELM ptr, _
		byval ex as FBSYMBOL ptr _
	)

	'' This sub handles binary expression construction,
	'' and branching based on the result of those expressions.

	dim as ASTNODE ptr lhs_expr = any, rhs_expr = any, expr = any

	'' build expressions from the left and
	'' right-hand-side variables/constants
	lhs_expr = hElmToExpr( lhs )
	rhs_expr = hElmToExpr( rhs )

    '' attempt to build "lhs op rhs"
	expr = astNewBOP( op, lhs_expr, rhs_expr, ex, AST_OPOPT_NONE )

	'' fail?
	if( expr = NULL ) then
		'' this can only happen with UDT's
		errReport( FB_ERRMSG_UDTINFORNEEDSOPERATORS, TRUE, astGetOpId( op ) )
		exit sub
	end if

    '' UDT?
	if( astGetDataType( lhs ) = FB_DATATYPE_STRUCT ) then
		'' handle dtors, etc
		expr = astUpdComp2Branch( expr, ex, TRUE )

		'' fail?
		if( expr = NULL ) then
			'' this can only happen with UDT's
			errReport( FB_ERRMSG_UDTINFORNEEDSOPERATORS, TRUE, astGetOpId( op ) )
			exit sub
		end if
	end if

	'' add to AST
	astAdd( expr )

end sub

'':::::
private function hStepExpression _
	( _
		byval lhs_dtype as integer, _
	 	byval lhs_subtype as FBSYMBOL ptr, _
		byval rhs as FB_CMPSTMT_FORELM ptr _
	) as ASTNODE ptr

	'' This function generates the AST node for
	'' the STEP variable, which is used in hFlushSelfBOP
	'' as the right-hand-side to the FOR += operation.

    '' pointer counter?
    if ( typeIsPtr( lhs_dtype ) ) then

	    '' is STEP a complex expression?
		if( rhs->sym <> NULL ) then

			'' Creates an AST node with a binary expression.
			'' The left hand side of the expression is the
			'' STEP variable in a FOR block, the right-hand-side
			'' is an unsigned integer constant derived from the
			'' width of the counter variable.

			function = astNewBOP( AST_OP_MUL, _
			                      astNewVAR( rhs->sym, 0, FB_DATATYPE_INTEGER ), _
			                      astNewCONSTi( symbCalcLen( typeDeref( lhs_dtype ), _
			                                                 lhs_subtype, _
			                                                 FALSE ), _
			                                    FB_DATATYPE_UINT ) )

		'' constant STEP
		else

			'' Creates an AST node with a constant integer expression.
			'' The value of the constant is calculated by
			'' taking the STEP value, and multiplying it by
			'' the width of the counter type.

			function = astNewCONSTi( rhs->value.int * symbCalcLen( typeDeref( lhs_dtype ), _
			                                                       lhs_subtype, _
			                                                       FALSE ), _
			                         FB_DATATYPE_INTEGER )

		end if

    '' regular variable counter
    else

        '' no calculation needed
        function = hElmToExpr( rhs )

    end if

end function

'':::::
private sub hFlushSelfBOP _
	( _
		byval op as integer, _
	 	byval lhs as FB_CMPSTMT_FORELM ptr, _
		byval rhs as FB_CMPSTMT_FORELM ptr _
	)

	'' This sub handles the creation of the '+=' expression.

	dim as ASTNODE ptr lhs_expr = any, rhs_expr = any, expr = any
	dim as FBSYMBOL ptr lhs_subtype = symbGetSubtype( lhs->sym )

	lhs_expr = astNewVAR( lhs->sym, 0, astGetFullType( lhs ), lhs_subtype )
    rhs_expr = hStepExpression( astGetFullType( lhs ), lhs_subtype, rhs )

	'' attept to create the '+=' expression
	expr = astNewSelfBOP( op, lhs_expr, rhs_expr )

	'' fail?
	if( expr = NULL ) then
		'' this can only happen with UDT's
		errReport( FB_ERRMSG_UDTINFORNEEDSOPERATORS, TRUE, astGetOpId( op ) )
		exit sub
	end if

	'' add to AST
	astAdd( expr )

end sub

'':::::
private function hCallCtor _
	( _
		byval sym as FBSYMBOL ptr _
	) as integer

	dim as ASTNODE ptr expr = cInitializer( sym, FB_INIOPT_ISINI )
    if( expr = NULL ) then
    	return FALSE
    end if

    expr = astTypeIniFlush( expr, sym, AST_INIOPT_ISINI )
    if( expr = NULL ) then
    	return FALSE
    end if

	astAdd( expr )

	function = TRUE

end function

private sub hForAssign _
	( _
		byval stk as FB_CMPSTMTSTK ptr, _
		byref isconst as integer, _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval flags as FOR_FLAGS, _
		byval idexpr as ASTNODE ptr _
	)

	'' This function handles the '= InitialCondition'
	'' expression of a FOR block.

	'' =
	if( lexGetToken( ) <> FB_TK_ASSIGN) then
		errReport( FB_ERRMSG_EXPECTEDEQ )
	else
		lexSkipToken( )
	end if

	'' Not a local UDT with a constructor?
	if( ((flags and FOR_HASCTOR) = 0) or ((flags and FOR_ISLOCAL) = 0) ) then
		dim as ASTNODE ptr expr = cExpression( )
		if( expr = NULL ) then
			errReport( FB_ERRMSG_EXPECTEDEXPRESSION )
			'' error recovery: fake an expr
			expr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
		end if

		'' initial condition is a non-UDT constant?
		if( astIsCONST( expr ) and ((flags and FOR_ISUDT) = 0) ) then
			'' convert the constant to counter's type
			expr = astNewCONV( dtype, subtype, expr )
			if( expr = NULL ) then
				errReport( FB_ERRMSG_INVALIDDATATYPES )
				'' error recovery: fake an expr
				expr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
			end if

			'' take the constant value
			astCONST2FBValue( @stk->for.cnt.value, expr )

			isconst += 1
		end if

		'' save initial condition into counter
		expr = astNewASSIGN( idexpr, expr )
		if( expr = NULL ) then
			if( (flags and FOR_ISUDT) <> 0 ) then
				errReport( FB_ERRMSG_INVALIDDATATYPES )
			else
				errReport( FB_ERRMSG_UDTINFORNEEDSOPERATORS, TRUE, @"let" )
			end if
		else
			astAdd( expr )
		end if

	'' UDT has a constructor and is local..
	else
		if( hCallCtor( stk->for.cnt.sym ) = FALSE ) then
			errReport( FB_ERRMSG_EXPECTEDEXPRESSION )
		end if
	end if
end sub

'':::::
private sub hForTo _
	( _
		byval stk as FB_CMPSTMTSTK ptr, _
		byref isconst as integer, _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval flags as FOR_FLAGS _
	)

    '' This function handles the 'TO EndCondition'
    '' expression of a FOR block.

	'' TO
	if( lexGetToken( ) <> FB_TK_TO ) then
		errReport( FB_ERRMSG_EXPECTEDTO )
	else
		lexSkipToken( )
	end if

	'' EndCondition

	'' UDT has no constructor?
	if( (flags and FOR_HASCTOR) = 0 ) then
		dim as ASTNODE ptr expr = cExpression( )
		if( expr = NULL ) then
			errReport( FB_ERRMSG_EXPECTEDEXPRESSION )
			'' error recovery: fake an expr
			expr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
		end if

		'' EndCondition is a non-UDT constant?
		if( astIsCONST( expr ) and ((flags and FOR_ISUDT) = 0) ) then
			expr = astNewCONV( dtype, subtype, expr )
			if( expr = NULL ) then
				errReport( FB_ERRMSG_INVALIDDATATYPES )
				'' error recovery: fake an expr
				expr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
			end if

			'' remove any symbol, and
			stk->for.end.sym = NULL
			stk->for.end.dtype = dtype

			'' insert constant value instead, deleting
			'' source expression
			astCONST2FBValue( @stk->for.end.value, expr )
			astDelNode( expr )

			isconst += 1

		'' store end condition into a temp var
		else
			'' generate a symbol using the expression's type
			stk->for.end.sym = hStoreTemp( dtype, subtype, expr )
			stk->for.end.dtype = symbGetType( stk->for.end.sym )
		end if

	'' UDT has a constructor..
	else

		'' generate a symbol using the expression's type
		stk->for.end.sym = hAllocTemp( dtype, subtype )
		stk->for.end.dtype = symbGetType( stk->for.end.sym )

		'' build constructor call
		if( hCallCtor( stk->for.end.sym ) = FALSE ) then
			errReport( FB_ERRMSG_INVALIDDATATYPES )
		end if
	end if

end sub

private function hStepIsPositive _
	( _
		byval dtype as integer, _
		byval expr as ASTNODE ptr _
	) as integer

	select case as const typeGet( dtype )
	case FB_DATATYPE_LONGINT, FB_DATATYPE_ULONGINT
		function = (astGetValLong( expr ) >= 0)

	case FB_DATATYPE_SINGLE, FB_DATATYPE_DOUBLE
		function = (astGetValFloat( expr ) >= 0)

	case FB_DATATYPE_LONG, FB_DATATYPE_ULONG
		if( FB_LONGSIZE = len( integer ) ) then
			function = (astGetValInt( expr ) >= 0)
		else
			function = (astGetValLong( expr ) >= 0)
		end if

	case else
		function = (astGetValInt( expr ) >= 0)
	end select

end function

'':::::
private sub hForStep _
	( _
		byval stk as FB_CMPSTMTSTK ptr, _
		byref isconst as integer, _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval flags as FOR_FLAGS _
	)

	'' STEP
	stk->for.explicit_step = FALSE
	if( lexGetToken( ) = FB_TK_STEP ) then
		lexSkipToken( )
		stk->for.explicit_step = TRUE
	end if

	dim as integer iscomplex = FALSE

	if( (flags and FOR_HASCTOR) = 0 ) then
		dim as ASTNODE ptr expr = any

		if( stk->for.explicit_step ) then
			expr = cExpression( )
			if( expr = NULL ) then
				errReport( FB_ERRMSG_EXPECTEDEXPRESSION )
				'' error recovery: fake an expr
				expr = astNewCONSTi( 1, FB_DATATYPE_INTEGER )
			end if
		else
			'' no STEP was specified, so it's 1
			'' (the step's type will be converted below)
			expr = astNewCONSTi( 1, FB_DATATYPE_INTEGER )
		end if

		'' store step into a temp var

		'' non-UDT constant?
		if( astIsCONST( expr ) and ((flags and FOR_ISUDT) = 0) ) then
			expr = astNewCONV( dtype, subtype, expr )
			if( expr = NULL ) then
				errReport( FB_ERRMSG_INVALIDDATATYPES )
				'' error recovery: fake an expr
				expr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
			end if

			'' get step's positivity
			stk->for.ispos.value.int = hStepIsPositive( dtype, expr )

			'' get constant step
			stk->for.stp.sym = NULL
			if( typeIsPtr( dtype ) ) then
				stk->for.stp.dtype = FB_DATATYPE_LONG
			else
				stk->for.stp.dtype = dtype
			end if

			'' store expr into value, and del temp expression
			astCONST2FBValue( @stk->for.stp.value, expr )
			astDelNode( expr )

			isconst += 1

		else
			iscomplex = TRUE

			'' make a copy of type info, so we can hack
			'' the pointer stuff if necessary
			dim as integer tmp_dtype = dtype
			dim as FBSYMBOL ptr tmp_subtype = subtype

			'' step can't be a pointer if counter is
			if( typeIsPtr( dtype ) ) then
				tmp_dtype = FB_DATATYPE_LONG
				tmp_subtype = NULL
			end if

			'' generate a symbol using the expression's type
			stk->for.stp.sym = hStoreTemp( tmp_dtype, tmp_subtype, expr )
			stk->for.stp.dtype = symbGetType( stk->for.stp.sym )
		end if

	'' UDT has a constructor..
	else
		iscomplex = TRUE

		if( stk->for.explicit_step = TRUE ) then
			'' generate a symbol using the expression's type
			stk->for.stp.sym = hAllocTemp( dtype, subtype )
			stk->for.stp.dtype = symbGetType( stk->for.end.sym )
		end if

		if( stk->for.explicit_step ) then
			'' build constructor call
			if( hCallCtor( stk->for.stp.sym ) = FALSE ) then
				errReport( FB_ERRMSG_INVALIDDATATYPES )
			end if
		end if
	end if

    '' if STEP's sign is unknown, we have to check for that
    if( iscomplex and ((flags and FOR_ISUDT) = 0) ) then
    	dim as FB_CMPSTMT_FORELM cmp = any

    	cmp.dtype = stk->for.stp.dtype
		cmp.sym = NULL

		select case as const cmp.dtype
		case FB_DATATYPE_LONGINT, FB_DATATYPE_ULONGINT
			cmp.value.long = 0

		case FB_DATATYPE_SINGLE, FB_DATATYPE_DOUBLE
			cmp.value.float = 0.0

		case FB_DATATYPE_LONG, FB_DATATYPE_ULONG
			if( FB_LONGSIZE = len( integer ) ) then
				cmp.value.int = 0
			else
				cmp.value.long = 0
			end if

		case else
			cmp.value.int = 0
		end select

		stk->for.ispos.sym = symbAddTempVar( FB_DATATYPE_INTEGER )
		stk->for.ispos.dtype = FB_DATATYPE_INTEGER

        '' rhs = STEP >= 0
		dim as ASTNODE ptr rhs = astNewBOP( AST_OP_GE, _
		                                    hElmToExpr( @stk->for.stp ), _
		                                    hElmToExpr( @cmp ) )

		'' GE failed?
		if( rhs = NULL ) then
			errReport( FB_ERRMSG_INVALIDDATATYPES )
			'' fake it
			rhs = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
		end if

		'' is_positive = rhs
		astAdd( astNewASSIGN( astNewVAR( stk->for.ispos.sym, 0, FB_DATATYPE_INTEGER ), rhs ) )

    '' no need for a sign check
	else
		stk->for.ispos.sym = NULL
	end if
end sub

'':::::
''ForStmtBegin    =   FOR ID (AS DataType)? '=' Expression TO Expression (STEP Expression)? .
''               |=   FOREACH ID (AS DataType)? IN ForeachCompatibleType
function cForStmtBegin _
	( _
		byval keywd as integer _
	) as integer

	dim as FOR_FLAGS flags = 0

	function = FALSE

	'' FOR|FOREACH
	lexSkipToken( )

	'' ID
	dim as FBSYMCHAIN ptr chain_ = any
	dim as FBSYMBOL ptr base_parent = any
    dim as ASTNODE ptr ctnexpr = any
    dim as FB_DATATYPE itertype

	chain_ = cIdentifier( base_parent, FB_IDOPT_ISDECL or FB_IDOPT_DEFAULT )

    '' open outer scope
    dim as ASTNODE ptr outerscopenode = astScopeBegin( )
	if( outerscopenode = NULL ) then
		errReport( FB_ERRMSG_RECLEVELTOODEEP )
	end if

    dim as ASTNODE ptr idexpr = any, expr = any

    '' new variable?
	if( lexGetLookAhead( 1 ) = FB_TK_AS ) then
		dim as FBSYMBOL ptr sym = hVarDeclEx( FB_SYMBATTRIB_NONE, _
											  FALSE, _
											  lexGetToken( ), _
											  TRUE )
		if( sym = NULL ) then
			'' error recovery: fake a var
			idexpr = CREATEFAKEID( )
		else
			flags or= FOR_ISLOCAL
			idexpr = astNewVAR( sym, _
								0, _
								symbGetFullType( sym ), _
								symbGetSubtype( sym ) )
		end if

	'' tried array...
	elseif( lexGetLookAhead( 1 ) = CHAR_LPRNT ) then
		errReport( FB_ERRMSG_EXPECTEDSCALAR, TRUE )
		'' error recovery: skip until next ')' and fake a var
		hSkipUntil( CHAR_RPRNT )
		idexpr = CREATEFAKEID( )

	'' look up the variable
	else
		idexpr = cVariable( chain_ )
		if( idexpr = NULL ) then
			errReport( FB_ERRMSG_EXPECTEDVAR )
			'' error recovery: fake a var
			idexpr = CREATEFAKEID( )
		end if

		if( astIsVAR( idexpr ) = FALSE ) then
			errReport( FB_ERRMSG_EXPECTEDSCALAR, TRUE )
			'' error recovery: fake a var
			astDelTree( idexpr )
			idexpr = CREATEFAKEID( )
		end if
	end if

	dim as integer dtype = astGetDataType( idexpr )
	dim as FBSYMBOL ptr subtype = astGetSubType( idexpr )
	
	if( typeIsConst( astGetFullType( idexpr ) ) ) then
		errReport( FB_ERRMSG_CONSTANTCANTBECHANGED )
	end if

    if( keywd = FB_TK_FOR ) then
        select case as const dtype
        case FB_DATATYPE_BYTE to FB_DATATYPE_DOUBLE

        case FB_DATATYPE_STRUCT ', FB_DATATYPE_CLASS
            flags or= FOR_ISUDT
            if( symbGetHasCtor( symbGetSubtype( astGetSymbol( idexpr ) ) ) ) then
                flags or= FOR_HASCTOR
            end if
            
        case else
            '' not a ptr?
            if( typeIsPtr( dtype ) = FALSE ) then
                errReport( FB_ERRMSG_EXPECTEDSCALAR, TRUE )
                '' error recovery: fake a var
                astDelTree( idexpr )
                idexpr = CREATEFAKEID( )
                dtype = astGetDataType( idexpr )
            end if
        end select
    end if
        
    '' push a FOR context
	dim as FB_CMPSTMTSTK ptr stk = cCompStmtPush( FB_TK_FOR )

	'' extract counter variable from the expression
	stk->for.cnt.sym = astGetSymbol( idexpr )
	stk->for.cnt.dtype = dtype
    stk->for.class_ = FB_CMPSTMT_FOR_INVALID

	dim as integer isconst = 0
    
	'' labels
    dim as FBSYMBOL ptr il = any, tl = NULL, el = any, cl = NULL
    
    if( keywd = FB_TK_FOR ) then
        '' =
        hForAssign( stk, isconst, dtype, subtype, flags, idexpr )

        '' TO
        hForTo( stk, isconst, dtype, subtype, flags )

        '' STEP
        hForStep( stk, isconst, dtype, subtype, flags )

        '' determine type of for loop
        if( ( flags and FOR_ISUDT ) <> 0 ) then
            stk->for.class_ = FB_CMPSTMT_FOR_UDT
        else
            stk->for.class_ = FB_CMPSTMT_FOR_SCALAR
        end if
    else
        '' IN
        if( lexGetToken( ) <> FB_TK_IN ) then
            errReport( FB_ERRMSG_EXPECTEDIN, TRUE )
        end if
        lexSkipToken( )
        
        '' Get object or iterator
        ctnexpr = cExpression( )
        if ( ctnexpr = NULL ) then
            errReport( FB_ERRMSG_EXPECTEDEXPRESSION )
        end if
        
        '' determine type of foreach loop
        if( astGetFullType( ctnexpr ) = FB_DATATYPE_ITER ) then
            stk->for.class_ = FB_CMPSTMT_FOR_EACH_ITER
        elseif( astGetFullType( ctnexpr ) = FB_DATATYPE_STRUCT ) then
            stk->for.class_ = FB_CMPSTMT_FOR_EACH_UDT
        end if
    end if
    
    if( stk->for.class_ = FB_CMPSTMT_FOR_INVALID ) then
        errReport( FB_ERRMSG_UDTNOTFOREACHCOMPATIBLE, TRUE )
    end if

    '' start and end label (will be used by any EXIT FOR)
	il = symbAddLabel( NULL )
    el = symbAddLabel( NULL, FB_SYMBOPT_NONE )
    
    '' we need to "peek" at the end label,
    '' to allow an overloaded FOR operator to jump to it,
    '' if the operator returns FALSE
	stk->for.endlabel = el
    
    select case( stk->for.class_ )
        case FB_CMPSTMT_FOR_SCALAR
            '' comp/end label (will be used by any CONTINUE/EXIT FOR)
            tl = symbAddLabel( NULL, FB_SYMBOPT_NONE )
            cl = symbAddLabel( NULL, FB_SYMBOPT_NONE )
            
            '' if inic, endc and stepc are all constants,
            '' check if this test is needed
            if( isconst = 3 ) then
                expr = astNewBOP( iif( stk->for.ispos.value.int, AST_OP_LE, AST_OP_GE ), _
                                  astNewCONST( @stk->for.cnt.value, stk->for.cnt.dtype ), _
                                  astNewCONST( @stk->for.end.value, stk->for.end.dtype ) )

                if( astGetValInt( expr ) = FALSE ) then
                    astAdd( astNewBRANCH( AST_OP_JMP, el ) )
                end if

                astDelNode( expr )
            else 
                astAdd( astNewBRANCH( AST_OP_JMP, tl ) )
            end if
            
            '' top of loop
            astAdd( astNewLABEL( il ) )
           
        case FB_CMPSTMT_FOR_UDT
            '' comp/end label (will be used by any CONTINUE/EXIT FOR)
            tl = symbAddLabel( NULL, FB_SYMBOPT_NONE )
            cl = symbAddLabel( NULL, FB_SYMBOPT_NONE )

            '' call FOR operator to initialize
            hUdtFor( stk )
            
            '' branch to test
            astAdd( astNewBRANCH( AST_OP_JMP, tl ) )
            
            '' top of loop
            astAdd( astNewLABEL( il ) )
            
        case FB_CMPSTMT_FOR_EACH_UDT
            '' comp label (will be used by CONTINUE FOR)
            cl = symbAddLabel( NULL, FB_SYMBOPT_NONE )
        
            '' C-style UDT iterators: check criteria
            if( hCheckAndInitializeForeachCall( ctnexpr, idexpr, stk ) = 0 ) then
                errReport( FB_ERRMSG_TYPEMISMATCH )
            end if
            
            '' branch to test
            astAdd( astNewBRANCH( AST_OP_JMP, cl ) )
            
            '' top of loop
            astAdd( astNewLABEL( il ) )

            '' step after test passes       
            hEachUdtStep( stk )

        case FB_CMPSTMT_FOR_EACH_ITER
            '' built-in iterators: only requires variable to store iterator expression
            dim ctnsubtype as FBSYMBOL ptr = symbGetSubtype( ctnexpr )
            dim iter_var as ASTNODE ptr
            stk->for.stp.sym = symbAddTempVar( FB_DATATYPE_ITER, ctnsubtype )
            stk->for.stp.dtype = FB_DATATYPE_ITER
            iter_var = astNewVAR( stk->for.stp.sym, 0, FB_DATATYPE_ITER, ctnsubtype )
            if( iter_var <> NULL ) then
                astAdd( astNewASSIGN( iter_var, ctnexpr ) )
            end if
            
            '' top of loop
            astAdd( astNewLABEL( il ) )

            '' step, and result is test 
            hEachIterStepNext( stk )
    end select

	'' push to stmt stack
	stk->scopenode = astScopeBegin( )
	stk->for.outerscopenode = outerscopenode
	stk->for.inilabel = il
	stk->for.testlabel = tl
	stk->for.cmplabel = cl

	function = TRUE

end function

'':::::
private function hUdtCallOpOvl _
	( _
		byval parent as FBSYMBOL ptr, _
		byval op as AST_OP, _
		byval inst_expr as ASTNODE ptr, _
		byval second_arg as ASTNODE ptr, _
		byval third_arg as ASTNODE ptr _
	) as ASTNODE ptr

    dim as FBSYMBOL ptr sym = any

    '' check if op was overloaded
    sym = symbGetCompOpOvlHead( parent, op )

	if( sym = NULL ) then
		errReport( FB_ERRMSG_UDTINFORNEEDSOPERATORS, _
				   TRUE, _
                   astGetOpId( op ) )
		return NULL
	end if

	'' check for overloaded versions (note: don't pass the instance ptr)
	dim as FB_ERRMSG err_num = any
	if( second_arg = NULL ) then
		sym = symbFindClosestOvlProc( sym, 0, NULL, @err_num )
	else
		dim as FB_CALL_ARG args(0 to 1) = any
		dim as integer params = 1
		with args(0)
			.expr = second_arg
			.mode = INVALID
			.next = NULL
		end with

		'' link in that pesky 3rd arg.
		if( op = AST_OP_NEXT ) then
			if( third_arg <> NULL ) then
				args(0).next = @args(1)
				params += 1
				with args(1)
					.expr = third_arg
					.mode = INVALID
					.next = NULL
				end with
			end if
		end if

		sym = symbFindClosestOvlProc( sym, params, @args(0), @err_num )
	end if

	if( sym = NULL ) then
		'' some other error?
		if( err_num <> FB_ERRMSG_OK ) then
			errReport( err_num, TRUE )

		'' build a message for the user
		else
			dim as string op_version = *astGetOpId( op ) + " (with"
			select case as const op
			case AST_OP_FOR, AST_OP_STEP, AST_OP_INC_SELF
				'' supposed to be 1 arg
				if( second_arg = NULL ) then
					op_version += "out"
				end if
			case AST_OP_NEXT
				'' supposed to be 2 args
				if( third_arg = NULL ) then
					op_version += "out"
				end if
			end select
			op_version += " step)"
			errReport( FB_ERRMSG_UDTINFORNEEDSOPERATORS, TRUE, strptr(op_version) )
		end if
		return NULL
	end if

	dim as ASTNODE ptr proc = astNewCALL( sym )

	'' push the instance pointer
	if( astNewARG( proc, inst_expr ) = NULL ) then
		return NULL
	end if

	'' and the 2nd arg
	if( second_arg <> NULL ) then
		if( astNewARG( proc, second_arg ) = NULL ) then
			return NULL
		end if
	end if

	'' and the 3rd arg
	if( third_arg <> NULL ) then
		if( astNewARG( proc, third_arg ) = NULL ) then
			return NULL
		end if
	end if

	function = proc

end function

private sub hForStmtClose(byval stk as FB_CMPSTMTSTK ptr)
	'' close the scope block
	if( stk->scopenode <> NULL ) then
		astScopeEnd( stk->scopenode )
	end if
    
    select case stk->for.class_ 
        case FB_CMPSTMT_FOR_SCALAR
            '' emit cmp label
            astAdd( astNewLABEL( stk->for.cmplabel ) )        

            '' update
            hScalarStep( stk )
            
            '' emit test label
            astAdd( astNewLABEL( stk->for.testlabel ) )
            
            '' check
            hScalarNext( stk )
            
        case FB_CMPSTMT_FOR_UDT
            '' emit cmp label
            astAdd( astNewLABEL( stk->for.cmplabel ) )        

            '' update
            hUdtStep( stk )
            
            '' emit test label
            astAdd( astNewLABEL( stk->for.testlabel ) )

            '' check
            hUdtNext( stk )
            
        case FB_CMPSTMT_FOR_EACH_UDT
            '' emit cmp label
            astAdd( astNewLABEL( stk->for.cmplabel ) )        
        
            '' check
            hEachUdtNext( stk )

        case FB_CMPSTMT_FOR_EACH_ITER
            '' jump to top
            astAdd( astNewBRANCH( AST_OP_JMP, stk->for.inilabel ) )

    end select

	'' end label (loop exit)
	astAdd( astNewLABEL( stk->for.endlabel ) )

	'' close the outer scope block
	if( stk->for.outerscopenode <> NULL ) then
		astScopeEnd( stk->for.outerscopenode )
	end if
end sub

'':::::
''ForStmtEnd      =   NEXT (ID (',' ID?))? .
''
function cForStmtEnd _
	( _
	) as integer

	dim as FB_CMPSTMTSTK ptr stk = any

	function = FALSE

	'' NEXT
	lexSkipToken( )

	do
		'' TOS = top of stack
		stk = cCompStmtGetTOS( FB_TK_FOR )
		if( stk = NULL ) then
			exit function
		end if

		hForStmtClose( stk )

		'' ID?
		if( lexGetClass( ) <> FB_TKCLASS_IDENTIFIER ) then

			'' pop from stmt stack
			cCompStmtPop( stk )

			exit do
		end if

		'' ID
		dim as FBSYMCHAIN ptr chain_ = any
		dim as FBSYMBOL ptr base_parent = any
		chain_ = cIdentifier( base_parent, FB_IDOPT_ISDECL or FB_IDOPT_DEFAULT )

		'' look up the variable
		dim as ASTNODE ptr idexpr = cVariable( chain_ )

		if( idexpr = NULL ) then
			errReport( FB_ERRMSG_EXPECTEDVAR )
		else
			'' Same symbol?
			if( idexpr->sym <> stk->for.cnt.sym ) then
				errReport( FB_ERRMSG_FORNEXTVARIABLEMISMATCH )
			end if

			if( fbPdCheckIsSet( FB_PDCHECK_NEXTVAR ) ) then
				errReportWarn( FB_WARNINGMSG_NEXTVARMEANINGLESS, *symbGetName(idexpr->sym) )
			end if

			'' delete idexpr, we don't need it, for anything
			astDelTree( idexpr )
		end if

		'' pop from stmt stack
		cCompStmtPop( stk )

		'' ','?
		if( lexGetToken( ) <> CHAR_COMMA ) then
			exit do
		end if

		lexSkipToken( )
	loop

	function = TRUE

end function

function hCheckAndInitializeForeachCall _
    ( _
        byval ctnexpr as ASTNODE ptr, _
        byval idexpr as ASTNODE ptr, _
        byval stk as FB_CMPSTMTSTK ptr _
    ) as integer
    
    dim as FBSYMBOL ptr itertype = NULL
    dim as FBSYMBOL ptr beginmethod = NULL
    dim as FBSYMBOL ptr endingmethod = NULL
    dim as integer result = TRUE
    
    '' must be a UDT
	dim as integer ctndtype = astGetDataType( ctnexpr )
	dim as FBSYMBOL ptr ctnsubtype = astGetSubType( ctnexpr )
    if( ctndtype <> FB_DATATYPE_STRUCT ) then
        errReport( FB_ERRMSG_EXPECTEDUDT )
        result = FALSE
    end if
    
    '' must have a "begin" method returning an iterator object
    beginmethod = hGetForeachMethod( ctnsubtype, @"BEGIN", itertype )
    if( beginmethod = NULL ) then
        errReport( FB_ERRMSG_UDTNOTFOREACHCOMPATIBLE )
        result = FALSE
    end if
    
    '' must have an "ending" method returning the same type of iterator object
    endingmethod = hGetForeachMethod( ctnsubtype, @"ENDING", itertype )
    if( endingmethod = NULL )  then
        errReport( FB_ERRMSG_UDTNOTFOREACHCOMPATIBLE )
        result =FALSE
    end if 
    
    '' iterator must have <>, ++, and * methods defined
    if( result = TRUE ) then
        if( hIterIsForeachCompatible( itertype, stk->for.cnt.sym, stk ) = FALSE ) then
            errReport( FB_ERRMSG_ITERUDTNOTFOREACHCOMPATIBLE )
            result = FALSE
        end if
    end if
    
    if( result = FALSE ) then
        '' error recovery: iterator symbols are the container's type
        stk->for.container.dtype = FB_DATATYPE_STRUCT
        stk->for.container.sym = symbAddTempVar( ctndtype, ctnsubtype, FALSE, FALSE )
        stk->for.stp.dtype = FB_DATATYPE_STRUCT
        stk->for.stp.sym = symbAddTempVar( ctndtype, ctnsubtype, FALSE, FALSE )
        stk->for.end.dtype = FB_DATATYPE_STRUCT
        stk->for.end.sym = symbAddTempVar( ctndtype, ctnsubtype, FALSE, FALSE )
        return FALSE
    end if    
    
    dim itervar as ASTNODE ptr
    dim proccall as ASTNODE ptr
    dim asgnnode as ASTNODE ptr
    dim errfound as integer = FALSE
    
    '' initialize container object
    if( astIsVAR( ctnexpr ) = FALSE ) then
        '' create variable
        stk->for.container.dtype = FB_DATATYPE_STRUCT
        stk->for.container.sym = symbAddTempVar( ctndtype, ctnsubtype, FALSE, FALSE )

        '' copy expression to variable
        dim as ASTNODE ptr varexpr, asgnexpr
        varexpr = astNewVAR( stk->for.container.sym, 0, ctndtype, ctnsubtype )
        asgnexpr = astNewASSIGN( varexpr, ctnexpr )
        if( astAdd( asgnexpr ) = FALSE ) then
            errfound = FALSE
        end if
    else
        '' already a variable? just record info
        stk->for.container.dtype = FB_DATATYPE_STRUCT
        stk->for.container.sym = astGetSymbol( ctnexpr )
    end if
    
    '' dim begin_var as iter_type = container_udt::begin()
    stk->for.stp.dtype = FB_DATATYPE_STRUCT
    stk->for.stp.sym = symbAddTempVar( FB_DATATYPE_STRUCT, itertype )
    if( stk->for.stp.sym = NULL ) then
        errfound = TRUE
    end if
    
    dim as ASTNODE ptr ctnvar
    ctnvar = astNewVAR( stk->for.container.sym, 0, ctndtype, ctnsubtype )
    itervar = astNewVAR( stk->for.stp.sym, 0, FB_DATATYPE_STRUCT, itertype )
    proccall = astNewCALL( beginmethod )
    if( ctnvar = NULL or itervar = NULL or proccall = NULL ) then
        errfound = TRUE
    end if
    
    astNewARG( proccall, ctnvar )
    if( astAdd( astNewASSIGN( itervar, proccall ) ) = FALSE ) then
        errfound = TRUE
    end if
    
    '' dim ending_var as iter_type = container_udt::ending()
    stk->for.end.dtype = FB_DATATYPE_STRUCT
    stk->for.end.sym = symbAddTempVar( FB_DATATYPE_STRUCT, itertype )
    if( stk->for.stp.sym = NULL ) then
        errfound = TRUE
    end if

    ctnvar = astNewVAR( stk->for.container.sym, 0, ctndtype, ctnsubtype )
    itervar = astNewVAR( stk->for.end.sym, 0, FB_DATATYPE_STRUCT, itertype )
    proccall = astNewCALL( endingmethod )
    if( ctnvar = NULL or itervar = NULL or proccall = NULL ) then
        errfound = TRUE
    end if
    
    astNewARG( proccall, ctnvar )
    asgnnode = astNewASSIGN( itervar, proccall )
    if( astAdd( astNewASSIGN( itervar, proccall ) ) = FALSE ) then
        errfound = TRUE
    end if
    
    '' catch-all error for any internal failures
    if( errfound = TRUE ) then
        errReport( FB_ERRMSG_INTERNAL )
        return FALSE
    else
        return TRUE
    end if    
    
end function

function hGetForeachMethod _
    ( _
        byval udt as FBSYMBOL ptr, _
        byval id as zstring ptr, _
        byref itertype as FBSYMBOL ptr _
    ) as FBSYMBOL ptr
    
    '' look up symbol in udt
    dim as FBSYMCHAIN ptr chain_
    chain_ = symbLookupAt( udt, id, FALSE, TRUE )
    if( chain_ = NULL ) then
        function = NULL
    end if
    dim as FBSYMBOL ptr elm = chain_->sym

    '' symbol found, is it a method with no parameters returning a UDT?
    if( not symbIsMethod( elm ) ) then 
        return NULL
    end if
    
    '' Allow no more params than the object itself
    if( symbGetProcParams( elm ) > 1 ) then
        return NULL
    end if
    
    if( symbGetType( elm ) <> FB_DATATYPE_STRUCT ) then
        return NULL
    end if
    
    '' return type UDT, if supplied, must match the for-loop variable
    dim as FBSYMBOL ptr subtype = symbGetSubType( elm )
    if( itertype = NULL ) then
        itertype = subtype
    elseif( symbIsEqual( subtype, itertype ) = FALSE ) then
        return NULL
    end if
   
    return elm
   
end function

function hIterIsForeachCompatible _
    ( _
        byval itertype as FBSYMBOL ptr, _
        byval idvar as FBSYMBOL ptr, _
        byval stk as FB_CMPSTMTSTK ptr _
    ) as integer
    
    dim as FB_ERRMSG errmsg
    dim sym as FBSYMBOL ptr
    
    dim itervar1 as ASTNODE ptr 
    dim itervar2 as ASTNODE ptr 

    itervar1 = astNewVAR( stk->for.stp.sym, 0, FB_DATATYPE_STRUCT, itertype )
    itervar2 = astNewVAR( stk->for.end.sym, 0, FB_DATATYPE_STRUCT, itertype )
    
    '' must have operator <> (itertype, itertype)
    if( symbFindBopOvlProc( AST_OP_NE, itervar1, itervar2, @errmsg ) = NULL ) then
        return FALSE
    end if
    
    '' must have operator itertype::++
    if( symbFindSelfUopOvlProc( AST_OP_INC_SELF, itervar1, @errmsg ) = NULL ) then
        return FALSE
    end if
    
    '' must have operator itertype::*
    sym = symbFindUopOvlProc( AST_OP_DEREF, itervar1, @errmsg ) 
    if( sym = NULL ) then 
        return FALSE
    end if
    
    astDelTree( itervar1 )
    astDelTree( itervar2 )
    
    '' can what the iterator returns be assigned to the for-loop variable?
    dim iterreturn as ASTNODE ptr
    iterreturn = astNewVAR( sym, 0, symbGetType( sym ), symbGetSubtype( sym ) )
    if( astCheckCONV( _
        symbGetType( stk->for.cnt.sym ), _
        symbGetSubtype( stk->for.cnt.sym ), _
        iterreturn ) ) = FALSE then
        return FALSE
    end if

    return TRUE
    
end function 


