#ifndef __IR_BI__
#define __IR_BI__

const IR_INITADDRNODES		= 2048
const IR_INITVREGNODES		= IR_INITADDRNODES*3

const IR_MAXDIST			= 2147483647

''
enum IRVREGTYPE_ENUM
	IR_VREGTYPE_IMM
	IR_VREGTYPE_VAR
	IR_VREGTYPE_IDX
	IR_VREGTYPE_PTR
	IR_VREGTYPE_REG
	IR_VREGTYPE_OFS
end enum

'' sections
enum IR_SECTION
	IR_SECTION_CONST
	IR_SECTION_DATA
	IR_SECTION_BSS
	IR_SECTION_CODE
	IR_SECTION_DIRECTIVE
    IR_SECTION_CONSTRUCTOR
    IR_SECTION_DESTRUCTOR
    IR_SECTION_INFO
end enum

enum IR_REGFAMILY
	IR_REG_FPU_STACK
	IR_REG_SSE
end enum

enum IR_OPTIONVALUE
	IR_OPTIONVALUE_MAXMEMBLOCKLEN				= 1
end enum


''
type IRVREG_ as IRVREG
type IRTAC_ as IRTAC

type IRTACVREG
	vreg		as IRVREG_ ptr
	pParent		as IRVREG_ ptr ptr              '' pointer to parent if idx or aux
	next		as IRTACVREG ptr				'' next in tac (-> vr, v1 or v2)
end type

type IRTACVREG_GRP
	reg			as IRTACVREG
	idx			as IRTACVREG					'' index
	aux			as IRTACVREG                    '' auxiliary
end type

type IRTAC
	pos			as integer

	op			as AST_OP						'' opcode

	vr			as IRTACVREG_GRP                '' result
	v1			as IRTACVREG_GRP                '' operand 1
	v2			as IRTACVREG_GRP				'' operand 2

	ex1			as FBSYMBOL ptr					'' extra field, used by call/jmp
	ex2			as integer						'' /
end type

type IRVREG
	typ			as IRVREGTYPE_ENUM				'' VAR, IMM, IDX, etc

	dtype		as FB_DATATYPE					'' CHAR, INTEGER, ...
	subtype		as FBSYMBOL ptr

	reg			as integer						'' reg
	regFamily		as IR_REGFAMILY
	vector		as integer

	value		as FBVALUE						'' imm value (hi-word of longint's at vaux->value)

	sym			as FBSYMBOL ptr					'' symbol
	ofs			as integer						'' +offset
	mult		as integer						'' multipler

	vidx		as IRVREG ptr					'' index vreg
	vaux		as IRVREG ptr					'' aux vreg (used with longint's)

	tacvhead	as IRTACVREG ptr				'' back-link to tac table
	tacvtail	as IRTACVREG ptr				'' /
	taclast		as IRTAC ptr					'' /
end type

'' if changed, update the _vtbl symbols at ir-*.bas::*_ctor
type IR_VTBL
	init as sub(byval backend as FB_BACKEND)
	end as sub()

	flush as sub _
	( _
	)

	emitBegin as function _
	( _
	) as integer

	emitEnd as sub _
	( _
		byval tottime as double _
	)

	getOptionValue as function _
	( _
		byval opt as IR_OPTIONVALUE _
	) as integer

	procBegin as sub _
	( _
		byval proc as FBSYMBOL ptr _
	)

	procEnd as sub _
	( _
		byval proc as FBSYMBOL ptr _
	)

	procAllocArg as function _
	( _
		byval proc as FBSYMBOL ptr, _
		byval sym as FBSYMBOL ptr, _
		byval lgt as integer _
	) as integer

	procAllocLocal as function _
	( _
		byval proc as FBSYMBOL ptr, _
		byval sym as FBSYMBOL ptr, _
		byval lgt as integer _
	) as integer

	procGetFrameRegName as function _
	( _
	) as const zstring ptr

	scopeBegin as sub _
	( _
		byval s as FBSYMBOL ptr _
	)

	scopeEnd as sub _
	( _
		byval s as FBSYMBOL ptr _
	)

	procAllocStaticVars as sub(byval head_sym as FBSYMBOL ptr)

	emit as sub _
	( _
		byval op as integer, _
		byval v1 as IRVREG ptr, _
		byval v2 as IRVREG ptr, _
		byval vr as IRVREG ptr, _
		byval ex1 as FBSYMBOL ptr = NULL, _
		byval ex2 as integer = 0 _
	)

	emitConvert as sub _
	( _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval v1 as IRVREG ptr, _
		byval v2 as IRVREG ptr _
	)

	emitLabel as sub _
	( _
		byval label as FBSYMBOL ptr _
	)

	emitLabelNF as sub _
	( _
		byval l as FBSYMBOL ptr _
	)

	emitReturn as sub _
	( _
		byval bytestopop as integer _
	)

	emitProcBegin as sub _
	( _
		byval proc as FBSYMBOL ptr, _
		byval initlabel as FBSYMBOL ptr _
	)

	emitProcEnd as sub _
	( _
		byval proc as FBSYMBOL ptr, _
		byval initlabel as FBSYMBOL ptr, _
		byval exitlabel as FBSYMBOL ptr _
	)

	emitPushArg as sub _
	( _
		byval vr as IRVREG ptr, _
		byval plen as integer, _
		byval level as integer _
	)

	emitASM as sub _
	( _
		byval text as zstring ptr _
	)

	emitComment as sub _
	( _
		byval text as zstring ptr _
	)

	emitJmpTb as sub _
	( _
		byval op as AST_JMPTB_OP, _
		byval dtype as integer, _
		byval label as FBSYMBOL ptr _
	)

	emitBop as sub _
	( _
		byval op as integer, _
		byval v1 as IRVREG ptr, _
		byval v2 as IRVREG ptr, _
		byval vr as IRVREG ptr, _
		byval ex as FBSYMBOL ptr _
	)

	emitUop as sub _
	( _
		byval op as integer, _
		byval v1 as IRVREG ptr, _
		byval vr as IRVREG ptr _
	)

	emitStore as sub _
	( _
		byval v1 as IRVREG ptr, _
		byval v2 as IRVREG ptr _
	)

	emitSpillRegs as sub _
	( _
	)

	emitLoad as sub _
	( _
		byval v1 as IRVREG ptr _
	)

	emitLoadRes as sub _
	( _
		byval v1 as IRVREG ptr, _
		byval vr as IRVREG ptr _
	)

	emitStack as sub _
	( _
		byval op as integer, _
		byval v1 as IRVREG ptr _
	)

	emitPushUDT as sub _
	( _
		byval v1 as IRVREG ptr, _
		byval lgt as integer _
	)

	emitAddr as sub _
	( _
		byval op as integer, _
		byval v1 as IRVREG ptr, _
		byval vr as IRVREG ptr _
	)

	emitCall as sub _
	( _
		byval proc as FBSYMBOL ptr, _
		byval bytestopop as integer, _
		byval vr as IRVREG ptr, _
		byval level as integer _
	)

	emitCallPtr as sub _
	( _
		byval v1 as IRVREG ptr, _
		byval vr as IRVREG ptr, _
		byval bytestopop as integer, _
		byval level as integer _
	)

	emitStackAlign as sub _
	( _
		byval bytes as integer _
	)

	emitJumpPtr as sub _
	( _
		byval v1 as IRVREG ptr _
	)

	emitBranch as sub _
	( _
		byval op as integer, _
		byval label as FBSYMBOL ptr _
	)

	emitMem as sub _
	( _
		byval op as integer, _
		byval v1 as IRVREG ptr, _
		byval v2 as IRVREG ptr, _
		byval bytes as integer _
	)

	emitScopeBegin as sub _
	( _
		byval s as FBSYMBOL ptr _
	)

	emitScopeEnd as sub _
	( _
		byval s as FBSYMBOL ptr _
	)

	emitDBG as sub _
	( _
		byval op as integer, _
		byval proc as FBSYMBOL ptr, _
		byval ex as integer _
	)

	emitVarIniBegin as sub( byval sym as FBSYMBOL ptr )
	emitVarIniEnd as sub( byval sym as FBSYMBOL ptr )
	emitVarIniI as sub( byval dtype as integer, byval value as integer )
	emitVarIniF as sub( byval dtype as integer, byval value as double )
	emitVarIniI64 as sub( byval dtype as integer, byval value as longint )
	emitVarIniOfs as sub( byval sym as FBSYMBOL ptr, byval ofs as integer )

	emitVarIniStr as sub _
	( _
		byval totlgt as integer, _
		byval litstr as zstring ptr, _
		byval litlgt as integer _
	)

	emitVarIniWstr as sub _
	( _
		byval totlgt as integer, _
		byval litstr as wstring ptr, _
		byval litlgt as integer _
	)

	emitVarIniPad as sub( byval bytes as integer )
	emitVarIniScopeBegin as sub( )
	emitVarIniScopeEnd as sub( )

	allocVreg as function _
	( _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr _
	) as IRVREG ptr

	allocVrImm as function _
	( _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval value as integer _
	) as IRVREG ptr

	allocVrImm64 as function _
	( _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval value as longint _
	) as IRVREG ptr

	allocVrImmF as function _
	( _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval value as double _
	) as IRVREG ptr

	allocVrVar as function _
	( _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval symbol as FBSYMBOL ptr, _
		byval ofs as integer _
	) as IRVREG ptr

	allocVrIdx as function _
	( _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval symbol as FBSYMBOL ptr, _
		byval ofs as integer, _
		byval mult as integer, _
		byval vidx as IRVREG ptr _
	) as IRVREG ptr

	allocVrPtr as function _
	( _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval ofs as integer, _
		byval vidx as IRVREG ptr _
	) as IRVREG ptr

	allocVrOfs as function _
	( _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr, _
		byval symbol as FBSYMBOL ptr, _
		byval ofs as integer _
	) as IRVREG ptr

	setVregDataType as sub _
	( _
		byval vreg as IRVREG ptr, _
		byval dtype as integer, _
		byval subtype as FBSYMBOL ptr _
	)

	getDistance as function _
	( _
		byval vreg as IRVREG ptr _
	) as uinteger

	loadVr as sub _
	( _
		byval reg as integer, _
		byval vreg as IRVREG ptr, _
		byval doload as integer _
	)

	storeVr as sub _
	( _
		byval vreg as IRVREG ptr, _
		byval reg as integer _
	)

	xchgTOS as sub _
	( _
		byval reg as integer _
	)

	makeTmpStr as function  _
	( _
		byval islabel as integer _
	) as zstring ptr
end type

enum IR_OPT
	IR_OPT_FPUCONV       = &h00000001  '' Should float operands always be converted?
	IR_OPT_FPUIMMEDIATES = &h00000002  '' Floating-point immediates allowed?
	IR_OPT_FPUBOPFLAGS   = &h00000004  '' Do float BOPs set flags for conditional jumps (x86)?
	IR_OPT_FPUSELFBOPS   = &h00000008  '' Are float self-BOPs available?

	IR_OPT_CPUBOPFLAGS   = &h00000100  '' Integer BOPs set flags for conditional jumps (x86)?
	IR_OPT_CPUSELFBOPS   = &h00000200  '' Integer self-BOPs available?
	IR_OPT_64BITCPUREGS  = &h00000400  '' 64-bit wide registers?

	IR_OPT_ADDRCISC      = &h00010000  '' complex addressing modes (base+idx*disp)
	IR_OPT_NOINLINEOPS   = &h00020000  '' "Complex" math operators unavailable?
	IR_OPT_HIGHLEVEL     = &h00040000  '' Preserve the high level constructions?
end enum

type IRCTX
	inited			as integer
	vtbl			as IR_VTBL
	options			as IR_OPT
end type

''
''
''
declare sub irTAC_ctor()
declare sub irHLC_ctor()
declare sub irInit(byval backend as FB_BACKEND)
declare sub irEnd()

''
'' macros
''
#define irGetOption( op ) ((ir.options and op) <> 0)

#define irSetOption( op ) ir.options or= op

#define irGetOptionValue( opt ) ir.vtbl.getOptionValue( opt )

#define irAllocVreg(dtype, stype) ir.vtbl.allocVreg( dtype, stype )

#define irSetVregDataType(v, dtype, stype) ir.vtbl.setVregDataType( v, dtype, stype )

#define irAllocVrImm(dtype, stype, value) ir.vtbl.allocVrImm( dtype, stype, value )

#define irAllocVrImm64(dtype, stype, value) ir.vtbl.allocVrImm64( dtype, stype, value )

#define irAllocVrImmF(dtype, stype, value) ir.vtbl.allocVrImmF( dtype, stype, value )

#define irAllocVrVar(dtype, stype, sym, ofs) ir.vtbl.allocVrVar( dtype, stype, sym, ofs )

#define irAllocVrIdx(dtype, stype, sym, ofs, mult, vidx) ir.vtbl.allocVrIdx( dtype, stype, sym, ofs, mult, vidx )

#define irAllocVrPtr(dtype, stype, ofs, vidx) ir.vtbl.allocVrPtr( dtype, stype, ofs, vidx )

#define irAllocVrOfs(dtype, stype, sym, ofs) ir.vtbl.allocVrOfs( dtype, stype, sym, ofs )

#define irProcBegin(proc) ir.vtbl.procBegin( proc )

#define irProcEnd(proc) ir.vtbl.procEnd( proc )

#define irScopeBegin(s) ir.vtbl.scopeBegin( s )

#define irScopeEnd(s) ir.vtbl.scopeEnd( s )

#define irProcAllocArg(proc, s, lgt) ir.vtbl.procAllocArg( proc, s, lgt )

#define irProcAllocLocal(proc, s, lgt) ir.vtbl.procAllocLocal( proc, s, lgt )

#define irProcAllocStaticVars(head_sym) ir.vtbl.procAllocStaticVars( head_sym )

#define irProcGetFrameRegName() ir.vtbl.procGetFrameRegName( )

#define irEmitBegin() ir.vtbl.emitBegin( )

#define irEmitEnd(tottime) ir.vtbl.emitEnd( tottime )

#define irEmit(op, v1, v2, vr, ex1, ex2) ir.vtbl.emit( op, v1, v2, vr, ex1, ex2 )

#define irEmitPROCBEGIN(proc, initlabel) ir.vtbl.emitProcBegin( proc, initlabel )

#define irEmitPROCEND(proc, initlabel, exitlabel) ir.vtbl.emitProcEnd( proc, initlabel, exitlabel )

#define irEmitVARINIBEGIN(sym) ir.vtbl.emitVarIniBegin( sym )

#define irEmitVARINIEND(sym) ir.vtbl.emitVarIniEnd( sym )

#define irEmitVARINIi(dtype, value) ir.vtbl.emitVarIniI( dtype, value )

#define irEmitVARINIf(dtype, value) ir.vtbl.emitVarIniF( dtype, value )

#define irEmitVARINI64(dtype, value) ir.vtbl.emitVarIniI64( dtype, value )

#define irEmitVARINIOFS(sym, ofs) ir.vtbl.emitVarIniOfs( sym, ofs )

#define irEmitVARINISTR(totlgt, litstr, litlgt) ir.vtbl.emitVarIniStr( totlgt, litstr, litlgt )

#define irEmitVARINIWSTR(totlgt, litstr, litlgt) ir.vtbl.emitVarIniWstr( totlgt, litstr, litlgt )

#define irEmitVARINIPAD(bytes) ir.vtbl.emitVarIniPad( bytes )

#define irEmitVARINISCOPEBEGIN( ) ir.vtbl.emitVarIniScopeBegin( )

#define irEmitVARINISCOPEEND( ) ir.vtbl.emitVarIniScopeEnd( )

#define irEmitCONVERT(dtype, stype, v1, v2) ir.vtbl.emitConvert( dtype, stype, v1, v2 )

#define irEmitLABEL(label) ir.vtbl.emitLabel( label )

#define irEmitRETURN(bytestopop) ir.vtbl.emitReturn( bytestopop )

#define irEmitPUSHARG(vr, plen, level) ir.vtbl.emitPushArg( vr, plen, level )

#define irEmitASM(text) ir.vtbl.emitASM( text )

#define irEmitCOMMENT(text) ir.vtbl.emitComment( text )

#define irEmitJMPTB(op, dtype, label) ir.vtbl.emitJmpTb( op, dtype, label )

#define irFlush() ir.vtbl.flush( )

#define irGetDistance(vreg) ir.vtbl.getDistance( vreg )

#define irLoadVR(reg, vreg, doload) ir.vtbl.loadVR( reg, vreg, doload )

#define irStoreVR(vreg, reg) ir.vtbl.storeVR( vreg, reg )

#define irXchgTOS(reg) ir.vtbl.xchgTOS( reg )

#define irEmitBOP( op, v1, v2, vr, ex ) ir.vtbl.emitBop( op, v1, v2, vr, ex )

#define irEmitUOP(op, v1, vr) ir.vtbl.emitUop( op, v1, vr )

#define irEmitSTORE(v1, v2) ir.vtbl.emitStore( v1, v2 )

#define irEmitSPILLREGS() ir.vtbl.emitSpillRegs( )

#define irEmitLOAD(v1) ir.vtbl.emitLoad( v1 )

#define irEmitLOADRES(v1, vr) ir.vtbl.emitLoadRes( v1, vr )

#define irEmitSTACK(op, v1) ir.vtbl.emitStack( op, v1 )

#define irEmitPUSH(v1) ir.vtbl.emitStack( AST_OP_PUSH, v1 )

#define irEmitPOP(v1) ir.vtbl.emitStack( AST_OP_POP, v1 )

#define irEmitPUSHUDT(v1, lgt) ir.vtbl.emitPushUDT( v1, lgt )

#define irEmitADDR(op, v1, vr) ir.vtbl.emitAddr( op, v1, vr )

#define irEmitLABELNF(s) ir.vtbl.emitLabelNF( s )

#define irEmitCALLFUNCT(proc, bytestopop, vr, level) ir.vtbl.emitCall( proc, bytestopop, vr, level )

#define irEmitCALLPTR(v1, vr, bytestopop, level) ir.vtbl.emitCallPtr( v1, vr, bytestopop, level )

#define irEmitSTACKALIGN(bytes) ir.vtbl.emitStackAlign( bytes )

#define irEmitJUMPPTR(v1) ir.vtbl.emitJumpPtr( v1 )

#define irEmitBRANCH(op, label) ir.vtbl.emitBranch( op, label )

#define irEmitMEM(op, v1, v2, bytes) ir.vtbl.emitMem( op, v1, v2, bytes )

#define irEmitSCOPEBEGIN(s) ir.vtbl.emitScopeBegin( s )

#define irEmitSCOPEEND(s) ir.vtbl.emitScopeEnd( s )

#define irEmitDBG(op, proc, ex) ir.vtbl.emitDBG( op, proc, ex )


#define irIsREG(v) (v->typ = IR_VREGTYPE_REG)

#define irIsIMM(v) (v->typ = IR_VREGTYPE_IMM)

#define irIsVAR(v) (v->typ = IR_VREGTYPE_VAR)

#define irIsIDX(v) (v->typ = IR_VREGTYPE_IDX)

#define irIsPTR(v) (v->typ = IR_VREGTYPE_PTR)

#define irGetVRType(v) v->typ

#define irGetVRDataType(v) v->dtype

#define irGetVRSubType(v) v->subtype

#define irGetVROfs(v) v->ofs

#define irGetVRValueI(v) v->value.int

#define ISLONGINT(t) ((t = FB_DATATYPE_LONGINT) or (t = FB_DATATYPE_ULONGINT))

#define hMakeTmpStr( ) ir.vtbl.makeTmpStr( TRUE )

#define hMakeTmpStrNL( ) ir.vtbl.makeTmpStr( FALSE )


''
'' inter-module globals
''
extern ir as IRCTX


#endif '' __IR_BI__
