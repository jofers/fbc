'' AST decl nodes (VAR, CONST, etc)
''
'' chng: jun/2006 written [v1ctor]


#include once "fb.bi"
#include once "fbint.bi"
#include once "ir.bi"
#include once "ast.bi"

'':::::
private function hCtorList _
	( _
		byval sym as FBSYMBOL ptr _
	) as ASTNODE ptr

	dim as FBSYMBOL ptr cnt = any, label = any, this_ = any, subtype = any
	dim as ASTNODE ptr tree = NULL

	subtype = symbGetSubtype( sym )

    cnt = symbAddTempVar( FB_DATATYPE_INTEGER, NULL, FALSE, FALSE )
    label = symbAddLabel( NULL )
    this_ = symbAddTempVar( typeAddrOf( symbGetType( sym ) ), _
    					    subtype, _
    					    FALSE, _
    					    FALSE )

	'' fld = @sym(0)
	tree = astNewLINK( tree, _
		astBuildVarAssign( this_, _
			astNewADDROF( astNewVAR( sym, 0, symbGetFullType( sym ), subtype ) ) ) )

	'' for cnt = 0 to symbGetArrayElements( sym )-1
	tree = astBuildForBegin( tree, cnt, label, 0 )

	'' sym.constructor( )
	tree = astNewLINK( tree, astBuildCtorCall( symbGetSubtype( sym ), astBuildVarDeref( this_ ) ) )

	'' this_ += 1
	tree = astNewLINK( tree, astBuildVarInc( this_, 1 ) )

	'' next
	tree = astBuildForEnd( tree, cnt, label, 1, astNewCONSTi( symbGetArrayElements( sym ) ) )

	function = tree

end function

'':::::
private function hCallCtor _
	( _
		byval sym as FBSYMBOL ptr, _
		byval initree as ASTNODE ptr _
	) as ASTNODE ptr

	dim as integer lgt = any
   	dim as FBSYMBOL ptr subtype = any

    function = NULL

    '' static, shared (includes extern/public) or common? do nothing..
    if( (symbGetAttrib( sym ) and (FB_SYMBATTRIB_STATIC or _
       	 						   FB_SYMBATTRIB_SHARED or _
       	 						   FB_SYMBATTRIB_COMMON or _
       	 						   FB_SYMBATTRIB_DYNAMIC)) <> 0 ) then
    	exit function
    end if

    '' local..

   	'' initialized? do nothing..
   	if( initree <> NULL ) then
   		exit function
   	end if

   	'' not initialized..
   	subtype = symbGetSubtype( sym )

	'' Do not initialize?
	if( symbGetDontInit( sym ) ) then
		exit function
	end if

   	select case symbGetType( sym )
   	case FB_DATATYPE_STRUCT ', FB_DATATYPE_CLASS
   		'' has a default ctor?
   		if( symbGetCompDefCtor( subtype ) <> NULL ) then
   			'' proc result? astProcEnd() will take care of this
   			if( (symbGetAttrib( sym ) and FB_SYMBATTRIB_FUNCRESULT) <> 0 ) then
   				exit function
   			end if

   			'' scalar?
   			if( (symbGetArrayDimensions( sym ) = 0) or _
   				(symbGetArrayElements( sym ) = 1) ) then
   				'' sym.constructor( )
   				return astBuildCtorCall( subtype, _
   										 astNewVAR( sym, _
   											 		0, _
   											 		symbGetFullType( sym ), _
   											 		subtype ) )

   			'' array..
   			else
                return hCtorList( sym )
   			end if
   		end if
   	end select

    lgt = symbGetLen( sym ) * symbGetArrayElements( sym )

    function = astNewMEM( AST_OP_MEMCLEAR, _
    			  	  	  astNewVAR( sym, _
    			  		  	 	 	 0, _
    			   			 	 	 symbGetFullType( sym ), _
    			   			 	 	 subtype ), _
    			  	  	  astNewCONSTi( lgt ) )

end function

'':::::
function astNewDECL _
	( _
		byval sym as FBSYMBOL ptr, _
		byval initree as ASTNODE ptr _
	) as ASTNODE ptr

    dim as ASTNODE ptr n = any

	'' alloc new node
	n = astNewNode( AST_NODECLASS_DECL, FB_DATATYPE_INVALID )

	n->l = hCallCtor( sym, initree )

	function = n

end function

'':::::
function astLoadDECL _
	( _
		byval n as ASTNODE ptr _
	) as IRVREG ptr

	'' call ctor?
	if( n->l <> NULL ) then
		astLoad( n->l )
		astDelNode( n->l )
	end if

	function = NULL

end function


