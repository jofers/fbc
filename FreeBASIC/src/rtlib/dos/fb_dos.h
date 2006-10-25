/*
 *  libfb - FreeBASIC's runtime library
 *	Copyright (C) 2004-2005 Andre Victor T. Vicentini (av1ctor@yahoo.com.br)
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *  As a special exception, the copyright holders of this library give
 *  you permission to link this library with independent modules to
 *  produce an executable, regardless of the license terms of these
 *  independent modules, and to copy and distribute the resulting
 *  executable under terms of your choice, provided that you also meet,
 *  for each linked independent module, the terms and conditions of the
 *  license of that module. An independent module is a module which is
 *  not derived from or based on this library. If you modify this library,
 *  you may extend this exception to your version of the library, but
 *  you are not obligated to do so. If you do not wish to do so, delete
 *  this exception statement from your version.
 */

/*
 * fb_dos.h -- common DOS definitions.
 *
 * chng: jul/2005 written [DrV]
 *
 */

#ifndef __FB_DOS_H__
#define __FB_DOS_H__

#define FB_DOS_USE_CONIO

#include <dpmi.h>
#include <dos.h>
#include <go32.h>
#include <pc.h>
#include <sys/farptr.h>

#include <stdio.h>
#include <stdarg.h>

#ifdef FB_DOS_USE_CONIO
# include <conio.h>
#endif

#define FB_NEWLINE "\r\n"
#define FB_NEWLINE_WSTR _LC("\r\n")

typedef int FB_DIRCTX; /* dummy to make fb.h happy */

typedef long fb_off_t;

typedef struct {
    unsigned long edi;
    unsigned long esi;
    unsigned long ebp;
    unsigned long res;
    unsigned long ebx;
    unsigned long edx;
    unsigned long ecx;
    unsigned long eax;
} __dpmi_regs_d;

typedef struct _FB_DOS_TXTMODE {
	int w;
	int h;
	unsigned long phys_addr;
} FB_DOS_TXTMODE;

extern FB_DOS_TXTMODE __fb_dos_txtmode;

typedef int (*FnIntHandler)(unsigned irq_number);

extern int __fb_ScrollWasOff;
extern int __fb_force_input_buffer_changed;

int fb_ConsoleLocate_BIOS( int row, int col, int cursor );
void fb_ConsoleGetXY_BIOS( int *col, int *row );
unsigned int fb_ConsoleReadXY_BIOS( int col, int row, int colorflag );

void fb_ConsoleScroll_BIOS( int x1, int y1, int x2, int y2, int nrows );
void fb_ConsoleScrollEx( int x1, int y1, int x2, int y2, int nrows );

void fb_ConsoleMultikeyInit( void );
int fb_hConsoleInputBufferChanged( void );

int fb_isr_set( unsigned irq_number,
                FnIntHandler pfnIntHandler,
                size_t fn_size,
                size_t stack_size );

int fb_isr_reset( unsigned irq_number );

FnIntHandler fb_isr_get( unsigned irq_number );

/* To allow recursive CLI/STI */
int fb_dos_cli( void );
int fb_dos_sti( void );

int fb_dos_lock_data(const void *address, size_t size);
int fb_dos_lock_code(const void *address, size_t size);
int fb_dos_unlock_data(const void *address, size_t size);
int fb_dos_unlock_code(const void *address, size_t size);

/**************************************************************************************************
 * VB-compatible functions
 **************************************************************************************************/

    /** Locale information not provided by DOS but that are useful too.
     */
typedef struct _FB_LOCALE_INFOS {
	int country_code;
    const char *apszNamesMonthLong[12];
    const char *apszNamesMonthShort[12];
    const char *apszNamesWeekdayLong[7];
    const char *apszNamesWeekdayShort[7];
} FB_LOCALE_INFOS;

/** Array of locale informations.
 *
 * The last entry contains a country_code of -1.
 */
extern const FB_LOCALE_INFOS __fb_locale_infos[];
extern const size_t          __fb_locale_info_count;

struct _DOS_COUNTRY_INFO_GENERAL {
	unsigned char   info_id;
	unsigned short  size_data;
	unsigned short  country_id;
	unsigned short  code_page;
	unsigned short  date_format;
	char            curr_symbol_string[5];
	char            thousands_sep[2];
	char            decimal_sep[2];
	char            date_sep[2];
	char            time_sep[2];
	unsigned char   currency_format;
	unsigned char   curr_frac_digits;
	unsigned char   time_format;
	unsigned long   far_ptr_case_map_routine;
	char            data_list_sep[2];
	char            reserved[10];
} __attribute__((packed));

typedef struct _DOS_COUNTRY_INFO_GENERAL DOS_COUNTRY_INFO_GENERAL;

int fb_hIntlGetInfo( DOS_COUNTRY_INFO_GENERAL *pInfo );

#endif