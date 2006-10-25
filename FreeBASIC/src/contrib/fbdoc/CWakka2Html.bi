#ifndef __CWAKKA2HTML_BI__
#define __CWAKKA2HTML_BI__

''  fbdoc - FreeBASIC User's Manual Converter/Generator
''	Copyright (C) 2006 Jeffery R. Marshall (coder[at]execulink.com) and
''  the FreeBASIC development team.
''
''	This program is free software; you can redistribute it and/or modify
''	it under the terms of the GNU General Public License as published by
''	the Free Software Foundation; either version 2 of the License, or
''	(at your option) any later version.
''
''	This program is distributed in the hope that it will be useful,
''	but WITHOUT ANY WARRANTY; without even the implied warranty of
''	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
''	GNU General Public License for more details.
''
''	You should have received a copy of the GNU General Public License
''	along with this program; if not, write to the Free Software
''	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA.


#include once "common.bi"
#include once "CWiki.bi"
#include once "CPage.bi"
#include once "CPageList.bi"

type CWakka2Html as CWakka2Html_

declare function CWakka2Html_New _
	( _
		byval _this as CWakka2Html ptr = NULL _
	) as CWakka2Html ptr

declare sub CWakka2Html_Delete _
	( _
		byval _this as CWakka2Html ptr, _
		byval isstatic as integer = FALSE _
	)

declare sub CWakka2Html_setUrlBase( byval _this as CWakka2Html ptr, byval value as zstring ptr )
declare sub CWakka2Html_setIndentBase( byval _this as CWakka2Html ptr, byval value as integer )
declare sub CWakka2Html_setCssClass( byval _this as CWakka2Html ptr, byval token_id as integer, byval value as zstring ptr )
declare sub CWakka2Html_setTagDoGen( byval _this as CWakka2Html ptr, byval token_id as integer, byval value as integer )

declare function CWakka2Html_gen _
	( _
		byval _this as CWakka2Html ptr, _
		byval page as zstring ptr, _
		byval wiki as CWiki ptr _
	) as string


#endif