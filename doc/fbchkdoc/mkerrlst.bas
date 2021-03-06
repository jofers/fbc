''  fbchkdoc - FreeBASIC Wiki Management Tools
''	Copyright (C) 2008 Jeffery R. Marshall (coder[at]execulink[dot]com)
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

'' mkerrlist.bas - capture warnings/errors from FreeBASIC sources

'' chng: written [jeffm]

''
sub WriteHeaderCode( byval h as integer )
	print #h, !"type FBWARNING"
	print #h, !"level as integer"
	print #h, !"text as zstring ptr"
	print #h, !"end type"
	print #h,
end sub

''
sub WriteFooterCode( byval h as integer )
	print #h, !"print"
	print #h, !"for i as integer = 1 to FB_WARNINGMSGS-1"
	print #h, !"print chr(9) + \"- //\" + ltrim(str(i)) + \" \" + *warningMsgs(i).text + \"//\""
	print #h, !"next"
	print #h, !"print: print: print"
	print #h, !"for i as integer = 1 to FB_ERRMSGS-1"
	print #h, !"print chr(9) + \"- //\" + ltrim(str(i)) + \" \" + *errorMsgs(i) + \"//\""
	print #h, !"next"
end sub

''
sub ReadWriteErrorBi( byval hin as integer, byval hout as integer )
	dim as integer b = 0
	dim as string x
	while eof(hin) = 0	
		line input #hin, x
		if( b = 0 ) then
			if( instr( ucase(x), "ENUM FB_ERRMSG" ) > 0 ) then
				b = 1
			elseif( instr( ucase(x), "ENUM FB_WARNINGMSG" ) > 0 ) then
				b = 1
			end if
		end if
		if( b = 1 ) then
			print #hout, x
			if ucase(trim(x, any " " + chr(9) )) = "END ENUM" then
				b = 0
				print #hout, 
			end if
		end if
	wend
end sub

''
sub ReadWriteErrorBas( byval hin as integer, byval hout as integer )
	dim as integer b = 0
	dim as string x
	while eof(hin) = 0	
		line input #hin, x
		if( b = 0 ) then
			if( instr( ucase(x), "DIM SHARED WARNINGMSGS" ) > 0 ) then
				b = 1
			elseif( instr( ucase(x), "DIM SHARED ERRORMSGS" ) > 0 ) then
				b = 1
			end if
		end if
		if( b = 1 ) then
			print #hout, x
			if trim(x, any " " + chr(9) ) = "}" then
				b = 0
				print #hout,
			end if
		end if
	wend
end sub


'' --------------------------------------------------------
'' MAIN
'' --------------------------------------------------------

dim as string f1, f2, fout, p
dim as integer hin1, hin2, hout, i = 1

if( command(i) = "" ) then
	print "mkerrlst -p path"
	print
	print "Example:"
	print "    ./mkerrlst -p /FreeBASIC/src/compiler/"
	print
	print "Then:"
	print "    fbc mkerrtxt.bas"
	print "    ./mkerrtxt"
	print 
	end 0
end if

while( command(i) > "" )
	if( left( command(i), 1 ) = "-" ) then
		select case lcase(command(i))
		case "-p"
			i += 1
			p = command(i)
		case else
			print "Unrecognized option '" + command(i) + "'"
			end 1
		end select
	else
		print "Unexpected option '" + command(i) + "'"
		end 1
	end if
	i += 1
wend

if( p = "" ) then
	print "no path"
	end 1
end if

f1 = p & "inc\error.bi"
f2 = p & "error.bas"
fout = "mkerrtxt.bas"

hin1 = freefile
print "Reading '" + f1 + "' ..."
if( open( f1 for input access read as #hin1 ) <> 0 ) then
	print "unable to open '" & f1 & "'"
	end 1
end if

hin2 = freefile
print "Reading '" + f2 + "' ..."
if( open( f2 for input access read as #hin2 ) <> 0 ) then
	print "unable to open '" & f2 & "'"
	end 1
end if

hout = freefile
print "Writing '" + fout + "' ..."
if( open( fout for output as #hout ) <> 0 ) then
	print "unable to open '" & fout & "'"
	end 1
end if

WriteHeaderCode( hout )
ReadWriteErrorBi( hin1, hout )
ReadWriteErrorBas( hin2, hout )
WriteFooterCode( hout )

close #hout
close #hin1
close #hin2

print "Done."
