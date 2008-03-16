#ifndef __FB_BFD_BRIDGE_BI__
#define __FB_BFD_BRIDGE_BI__

''	FreeBASIC - 32-bit BASIC Compiler.
''	Copyright (C) 2004-2007 The FreeBASIC development team.
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

#if defined(USE_FB_BFD_HEADER)

#include once "bfd.bi"

#else

'' NOTE: these are the types that fb
'' uses to interface to the bfd wrapper.
'' the wrapper (which includes bfd.h)
'' may use types of other (smaller) sizes
'' and/or different values for enumerations.
'' The FB ones defined here are mapped to
'' the "real" ones in c-objinfo.c

'' must match declarations in c-objinfo.c

'' PTR types
Type bfd As bfd_
Type asection As asection_

'' numeric types
Type bfd_boolean As Integer
Type bfd_size_type As Long
Type file_ptr As Longint
Type flagword As Uinteger

'' must match c-objinfo.c flags
#define SEC_HAS_CONTENTS &h100

'' must match c-objinfo.c::FB_bfd_format
enum fb_bfd_format
        bfd_unknown = 0
        bfd_object
        bfd_archive
        bfd_core
        bfd_type_end
End enum

'' must match c-objinfo.c::FB_bfd_architecture
enum fb_bfd_architecture
        bfd_arch_i386
End enum

Extern "c"
        Declare Sub fb_bfd_init( )
        Declare Function fb_bfd_openr (Byval filename As Zstring Ptr, Byval target As Zstring Ptr) As bfd Ptr
        Declare Function fb_bfd_close (Byval abfd As bfd Ptr) As bfd_boolean
        Declare Function fb_bfd_check_format (Byval abfd As bfd Ptr, Byval format As fb_bfd_format) As bfd_boolean
        Declare Function fb_bfd_openr_next_archived_file (Byval archive As bfd Ptr, Byval previous As bfd Ptr) As bfd Ptr
        Declare Function fb_bfd_openw (Byval filename As Zstring Ptr, Byval target As Zstring Ptr) As bfd Ptr
        Declare Function fb_bfd_set_format (Byval abfd As bfd Ptr, Byval format As fb_bfd_format) As bfd_boolean
        Declare Function fb_bfd_get_section_by_name (Byval abfd As bfd Ptr, Byval Name As Zstring Ptr) As asection Ptr
        Declare Function fb_bfd_get_section_size (Byval section As asection Ptr) As bfd_size_type
        Declare Function fb_bfd_set_section_size (Byval abfd As bfd Ptr, Byval sec As asection Ptr, Byval Val As bfd_size_type) As bfd_boolean
        Declare Function fb_bfd_get_filename (Byval abfd As bfd Ptr) As Zstring Ptr
        Declare Function fb_bfd_make_section (Byval As bfd Ptr, Byval Name As Zstring Ptr) As asection Ptr
        Declare Function fb_bfd_check_format_matches (Byval abfd As bfd Ptr, Byval format As fb_bfd_format, Byval matching As Byte Ptr ptr Ptr) As bfd_boolean
        Declare Function fb_bfd_set_section_flags (Byval abfd As bfd Ptr, Byval sec As asection Ptr, Byval flags As flagword) As bfd_boolean
        Declare Function fb_bfd_get_section_contents (Byval abfd As bfd Ptr, Byval section As asection Ptr, Byval location As Any Ptr, Byval offset As file_ptr, Byval count As bfd_size_type) As bfd_boolean
        Declare Function fb_bfd_set_section_contents (Byval abfd As bfd Ptr, Byval section As asection Ptr, Byval Data As Any Ptr, Byval offset As file_ptr, Byval count As bfd_size_type) As bfd_boolean
        Declare Function fb_bfd_set_arch_mach (Byval abfd As bfd Ptr, Byval arch As fb_bfd_architecture, Byval mach As Uinteger) As bfd_boolean
End Extern

#define bfd_init fb_bfd_init
#define bfd_openr fb_bfd_openr
#define bfd_close fb_bfd_close
#define bfd_check_format fb_bfd_check_format
#define bfd_openr_next_archived_file fb_bfd_openr_next_archived_file
#define bfd_openw fb_bfd_openw
#define bfd_set_format fb_bfd_set_format
#define bfd_get_section_by_name fb_bfd_get_section_by_name
#define bfd_get_section_size fb_bfd_get_section_size
#define bfd_set_section_size fb_bfd_set_section_size
#define bfd_get_filename fb_bfd_get_filename
#define bfd_make_section fb_bfd_make_section
#define bfd_check_format_matches fb_bfd_check_format_matches
#define bfd_set_section_flags fb_bfd_set_section_flags
#define bfd_get_section_contents fb_bfd_get_section_contents
#define bfd_set_section_contents fb_bfd_set_section_contents
#define bfd_set_arch_mach fb_bfd_set_arch_mach

#endif '' defined(USE_FB_BFD_HEADER)

#endif '' __FB_BFD_BRIDGE_BI__
