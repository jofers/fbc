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


'' fbdoc_buildtoc
''
''
'' chng: sep/2006 written [coderJeff]
''

#include once "fbdoc_buildtoc.bi"
#include once "fbdoc_loader.bi"
#include once "CWiki.bi"

dim shared as CWiki ptr wiki

'' --------------------------------------------------------------------------
'' Content Scanning
'' --------------------------------------------------------------------------

'':::::
function _LoadAndScanPageLinks _
	( _	
		byval page as CPage ptr, _
		byval paglist as CPageList ptr, _
		byval bFollowLinks as integer _
	) as integer

	dim as TLIST ptr lst

	dim as CPage ptr newpage, prevpage
	dim as string sPageName, sBody, sTitle

	if( page = NULL ) then
		return FALSE
	end if

	if( CPage_GetScanned( page ) = TRUE ) then
		return TRUE
	end if

	CPage_SetScanned( page, TRUE )

	sPageName = CPage_GetName(page)
	if( len(sPageName) = 0 ) then
		? "Warning: Page with no key name should never happen."
		return FALSE
	end if

	? "Scanning: " + sPageName
	sBody = LoadPage( sPageName )
	if( len( sBody ) = 0 ) then
		return FALSE
	end if

	CWiki_Parse( wiki, CPage_GetName(page), sBody ) 

	sTitle = CWiki_GetPageTitle( wiki )
	if( len(sTitle) > 0 ) then
		CPage_SetPageTitle( page, sTitle )
	end if
	
	'' Get a list of all the links on the currently loaded page
	lst = CWiki_GetDocTocLinks( wiki, (lcase(sPageName) = "catpgfunctindex") )

	dim as WikiPageLink ptr pagelink

	CPage_FreePageLinks( page )

	pagelink = cast( WikiPageLink ptr, listGetHead( lst ) )

	do while( pagelink <> NULL )

		''? "   " + space(pagelink->level * 3) + pagelink->text + " - " + pagelink->link.url
		CPage_AddPageLink( page, pagelink->text, pagelink->link.url, pagelink->level )
	
		if( len(pagelink->link.url) > 0 ) then
			if( instr(pagelink->link.url, ":") = 0 ) then
				if( instr(pagelink->link.url, "/") = 0 ) then
					prevpage = CPageList_Find( paglist, pagelink->link.url )
					if( prevpage = NULL ) then
						if( bFollowLinks ) then
							newpage = CPageList_AddNewPage( paglist, pagelink->link.url, pagelink->text, NULL, 0, FALSE )
						end if
					end if
				end if
			end if
		end if

		pagelink = cast( WikiPageLink ptr, listGetNext( pagelink ) )
		
	loop
	
end function

'':::::
private sub _BuildTOCFromPage _
	( _
		byval page as CPage ptr, _
		byval startlevel as integer, _
		byval toclist as CPageList ptr, _
		byval paglist as CPageList ptr _
	)

	dim as CPage ptr newpage, prevpage
	dim as string sBody, sPageName, sTitle
	dim as TLIST ptr lst
	dim as PageLinkItem ptr pagelink

	if( page = NULL ) then
		exit sub
	end if

	sPageName = CPage_GetName(page)
	if( len(sPageName) = 0 ) then
		exit sub
	end if

	prevpage = CPageList_Find( paglist, sPageName )
	if( prevpage = NULL ) then
		exit sub
	end if

	lst = CPage_GetPageLinks( prevpage )
	if( listGetHead( lst ) = NULL ) then
		exit sub
	end if

	? "Building Toc: " + sPageName
	
	sTitle = CPage_GetTitle( page )

	'' Loop through each link.  Record the page and search for more sections
	pagelink = cast( PageLinkItem ptr, listGetHead( lst ) )
	do while( pagelink <> NULL )

		if( ( lcase(sPageName) = "doctoc" ) or ( lcase(Left(sPageName, 5)) = "catpg") ) then

			newpage = CPageList_AddNewPage( toclist, _
				pagelink->url, _
				pagelink->text, _
				NULL, startlevel + pagelink->level, TRUE )

			if( len(pagelink->url) > 0 ) then
				if( instr(pagelink->url, ":") = 0 ) then
					if( instr(pagelink->url, "/") = 0 ) then
						if (left(pagelink->url, 5) = "CatPg") _
							or (left(pagelink->url, 3) = "CVS") then

								prevpage = CPageList_Find( paglist, pagelink->url )
								if( prevpage ) then
									if( len(pagelink->text) > 0 ) then
										CPage_SetLinkTitle( prevpage, pagelink->text )
									end if

									_BuildTOCFromPage( prevpage, startlevel + pagelink->level + 1, toclist, paglist )

								end if

						else

							prevpage = CPageList_Find( paglist, pagelink->url )
							if( prevpage ) then
								if( len(pagelink->text) > 0 ) then
									CPage_SetLinkTitle( prevpage, pagelink->text )
								end if
							end if

						end if
					end if
				end if
			end if

		end if

		pagelink = cast( PageLinkItem ptr, listGetNext( pagelink ) )

	loop

end sub

'':::::
function FBDoc_BuildTOC _
	( _
		byval toc_pagename as zstring ptr, _
		byval toc_pagetitle as zstring ptr, _
		byval paglist as CPageList ptr ptr, _
		byval toclist as CPageList ptr ptr _
	) as integer

	dim as CPage ptr page
	dim as any ptr page_i

	if( paglist = NULL ) then
		return FALSE
	end if

	if( toclist = NULL ) then
		return FALSE
	end if

	*paglist = CPageList_New( )

	if( *paglist = NULL ) then
		return FALSE
	end if

	*toclist = CPageList_New( )

	if( *toclist = NULL ) then
		CPageList_Delete( *paglist )
		*paglist = NULL
		return FALSE
	end if

	wiki = CWiki_New(  )

	page = CPageList_AddNewPage( *paglist, toc_pagename, toc_pagetitle, NULL, 0, TRUE )
	page = CPageList_NewEnum( *paglist, @page_i )
	while( page )
		if( len(CPage_GetName( page )) > 0 ) then
			_LoadAndScanPageLinks( page, *paglist, TRUE )
		end if
		page = CPageList_NextEnum( @page_i )
	wend

	page = CPageList_AddNewPage( *toclist, toc_pagename, toc_pagetitle, NULL, 0, TRUE )
	_BuildTOCFromPage( page, 1, *toclist, *paglist )

	CWiki_Delete( wiki )
	wiki = NULL

	return TRUE

end function


'':::::
function FBDoc_BuildSinglePage _
	( _
		byval toc_pagename as zstring ptr, _
		byval toc_pagetitle as zstring ptr, _
		byval paglist as CPageList ptr ptr, _
		byval toclist as CPageList ptr ptr _
	) as integer

	dim as CPage ptr page
	dim as any ptr page_i
	dim as integer bFirstTime = TRUE

	if( paglist = NULL ) then
		return FALSE
	end if

	if( toclist = NULL ) then
		return FALSE
	end if

	*paglist = CPageList_New( )

	if( *paglist = NULL ) then
		return FALSE
	end if

	*toclist = CPageList_New( )

	if( *toclist = NULL ) then
		CPageList_Delete( *paglist )
		*paglist = NULL
		return FALSE
	end if

	wiki = CWiki_New(  )

	page = CPageList_AddNewPage( *paglist, toc_pagename, toc_pagetitle, NULL, 0, TRUE )
	page = CPageList_NewEnum( *paglist, @page_i )
	while( page )
		if( len(CPage_GetName( page )) > 0 ) then
			_LoadAndScanPageLinks( page, *paglist, bFirstTime )
			bFirstTime = FALSE
		end if
		page = CPageList_NextEnum( @page_i )
	wend

	''page = CPageList_AddNewPage( *toclist, toc_pagename, toc_pagetitle, NULL, 0, TRUE )
	''_BuildTOCFromPage( page, 1, *toclist, *paglist )

	CWiki_Delete( wiki )
	wiki = NULL

	return TRUE

end function
