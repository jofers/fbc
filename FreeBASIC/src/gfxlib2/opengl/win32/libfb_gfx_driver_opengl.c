/*
 *  libgfx2 - FreeBASIC's alternative gfx library
 *	Copyright (C) 2005 Angelo Mottola (a.mottola@libero.it)
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
*/

/*
 * opengl.c -- OpenGL gfx driver
 *
 * chng: feb/2005 written [lillo]
 *
 */

#include "fb_gfx.h"
#include "fb_gfx_win32.h"
#include <GL/GL.h>

#ifndef WGL_ARB_pixel_format
#define WGL_ARB_pixel_format

#define WGL_NUMBER_PIXEL_FORMATS_ARB    0x2000
#define WGL_DRAW_TO_WINDOW_ARB          0x2001
#define WGL_DRAW_TO_BITMAP_ARB          0x2002
#define WGL_ACCELERATION_ARB            0x2003
#define WGL_NEED_PALETTE_ARB            0x2004
#define WGL_NEED_SYSTEM_PALETTE_ARB     0x2005
#define WGL_SWAP_LAYER_BUFFERS_ARB      0x2006
#define WGL_SWAP_METHOD_ARB             0x2007
#define WGL_NUMBER_OVERLAYS_ARB         0x2008
#define WGL_NUMBER_UNDERLAYS_ARB        0x2009
#define WGL_TRANSPARENT_ARB             0x200A
#define WGL_TRANSPARENT_RED_VALUE_ARB   0x2037
#define WGL_TRANSPARENT_GREEN_VALUE_ARB 0x2038
#define WGL_TRANSPARENT_BLUE_VALUE_ARB  0x2039
#define WGL_TRANSPARENT_ALPHA_VALUE_ARB 0x203A
#define WGL_TRANSPARENT_INDEX_VALUE_ARB 0x203B
#define WGL_SHARE_DEPTH_ARB             0x200C
#define WGL_SHARE_STENCIL_ARB           0x200D
#define WGL_SHARE_ACCUM_ARB             0x200E
#define WGL_SUPPORT_GDI_ARB             0x200F
#define WGL_SUPPORT_OPENGL_ARB          0x2010
#define WGL_DOUBLE_BUFFER_ARB           0x2011
#define WGL_STEREO_ARB                  0x2012
#define WGL_PIXEL_TYPE_ARB              0x2013
#define WGL_COLOR_BITS_ARB              0x2014
#define WGL_RED_BITS_ARB                0x2015
#define WGL_RED_SHIFT_ARB               0x2016
#define WGL_GREEN_BITS_ARB              0x2017
#define WGL_GREEN_SHIFT_ARB             0x2018
#define WGL_BLUE_BITS_ARB               0x2019
#define WGL_BLUE_SHIFT_ARB              0x201A
#define WGL_ALPHA_BITS_ARB              0x201B
#define WGL_ALPHA_SHIFT_ARB             0x201C
#define WGL_ACCUM_BITS_ARB              0x201D
#define WGL_ACCUM_RED_BITS_ARB          0x201E
#define WGL_ACCUM_GREEN_BITS_ARB        0x201F
#define WGL_ACCUM_BLUE_BITS_ARB         0x2020
#define WGL_ACCUM_ALPHA_BITS_ARB        0x2021
#define WGL_DEPTH_BITS_ARB              0x2022
#define WGL_STENCIL_BITS_ARB            0x2023
#define WGL_AUX_BUFFERS_ARB             0x2024
#define WGL_NO_ACCELERATION_ARB         0x2025
#define WGL_GENERIC_ACCELERATION_ARB    0x2026
#define WGL_FULL_ACCELERATION_ARB       0x2027
#define WGL_SWAP_EXCHANGE_ARB           0x2028
#define WGL_SWAP_COPY_ARB               0x2029
#define WGL_SWAP_UNDEFINED_ARB          0x202A
#define WGL_TYPE_RGBA_ARB               0x202B
#define WGL_TYPE_COLORINDEX_ARB         0x202C
#define WGL_SAMPLE_BUFFERS_ARB          0x2041
#define WGL_SAMPLES_ARB                 0x2042

#endif


static int driver_init(char *title, int w, int h, int depth, int refresh_rate, int flags);
static void driver_exit(void);
static void driver_lock(void);
static void driver_unlock(void);
static void driver_set_palette(int index, int r, int g, int b);
static void driver_flip(void);
static int *driver_fetch_modes(int depth, int *size);
static int opengl_init(void);
static void opengl_exit(void);

GFXDRIVER fb_gfxDriverOpenGL =
{
	"OpenGL",		/* char *name; */
	driver_init,		/* int (*init)(int w, int h, char *title, int fullscreen); */
	driver_exit,		/* void (*exit)(void); */
	driver_lock,		/* void (*lock)(void); */
	driver_unlock,		/* void (*unlock)(void); */
	driver_set_palette,	/* void (*set_palette)(int index, int r, int g, int b); */
	fb_hWin32WaitVSync,	/* void (*wait_vsync)(void); */
	fb_hWin32GetMouse,	/* int (*get_mouse)(int *x, int *y, int *z, int *buttons); */
	fb_hWin32SetMouse,	/* void (*set_mouse)(int x, int y, int cursor); */
	fb_hWin32SetWindowTitle,/* void (*set_window_title)(char *title); */
	fb_hWin32SetWindowPos,	/* int (*set_window_pos)(int x, int y); */
	driver_fetch_modes,	/* int *(*fetch_modes)(int depth, int *size); */
	driver_flip		/* void (*flip)(void); */
};


typedef HGLRC (APIENTRY *WGLCREATECONTEXT)(HDC);
typedef BOOL (APIENTRY *WGLMAKECURRENT)(HDC, HGLRC);
typedef BOOL (APIENTRY *WGLDELETECONTEXT)(HGLRC);
typedef PROC (APIENTRY *WGLGETPROCADDRESS)(LPCSTR);
typedef PCHAR (APIENTRY *WGLGETEXTENSIONSTRINGARB)(HDC);
typedef BOOL (APIENTRY *WGLCHOOSEPIXELFORMATARB)(HDC, const int *, const FLOAT *, int, int *, int *);

typedef struct FB_WGL {
	WGLCREATECONTEXT CreateContext;
	WGLMAKECURRENT MakeCurrent;
	WGLDELETECONTEXT DeleteContext;
	WGLGETPROCADDRESS GetProcAddress;
	WGLGETEXTENSIONSTRINGARB GetExtensionStringARB;
	WGLCHOOSEPIXELFORMATARB ChoosePixelFormatARB;
} FB_WGL;

static FB_DYLIB library;
static FB_WGL fb_wgl;
static char *wgl_extensions;
static HGLRC hglrc;
static HDC hdc;


/*:::::*/
int fb_hGL_ExtensionSupported(const char *extension)
{
	int len, i;
	char *string, *what[2] = { wgl_extensions, __fb_gl.extensions };
	
	for (i = 0; i < 2; i++) {
		string = what[i];
		if (string) {
			len = strlen(extension);
			while ((string = strstr(string, extension)) != NULL) {
				string += len;
				if ((*string == ' ') || (*string == '\0'))
					return TRUE;
			}
		}
	}
	
	return FALSE;
}


/*:::::*/
static int GL_init(PIXELFORMATDESCRIPTOR *pfd)
{
	HWND wnd;
	HDC hdc;
	HGLRC hglrc;
	int pf, res = 0;
	
	wgl_extensions = NULL;
	
	wnd = CreateWindow(fb_win32.window_class, "OpenGL setup", WS_POPUP | WS_CLIPCHILDREN | WS_CLIPSIBLINGS,
					   0, 0, 8, 8, HWND_DESKTOP, NULL, fb_win32.hinstance, NULL);
	if (!wnd)
		return -1;
	
	hdc = GetDC(wnd);
	pf = ChoosePixelFormat(hdc, pfd);
	SetPixelFormat(hdc, pf, pfd);

	hglrc = fb_wgl.CreateContext(hdc);
	fb_wgl.MakeCurrent(hdc, hglrc);
	
	fb_wgl.GetProcAddress = (WGLGETPROCADDRESS)GetProcAddress(library, "wglGetProcAddress");
	fb_wgl.GetExtensionStringARB = (WGLGETEXTENSIONSTRINGARB)fb_wgl.GetProcAddress("wglGetExtensionsStringARB");
	if (!fb_wgl.GetExtensionStringARB)
		fb_wgl.GetExtensionStringARB = (WGLGETEXTENSIONSTRINGARB)fb_wgl.GetProcAddress("wglGetExtensionsStringEXT");
	if (fb_wgl.GetExtensionStringARB)
		wgl_extensions = fb_wgl.GetExtensionStringARB(hdc);
	
	res = fb_hGL_Init(library);
	if (res == 0) {
		if (fb_hGL_ExtensionSupported("WGL_ARB_pixel_format"))
			fb_wgl.ChoosePixelFormatARB = (WGLCHOOSEPIXELFORMATARB)fb_wgl.GetProcAddress("wglChoosePixelFormatARB");
	}
	
	fb_wgl.MakeCurrent(NULL, NULL);
	fb_wgl.DeleteContext(hglrc);
	ReleaseDC(wnd, hdc);
	
	DestroyWindow(wnd);
	
	return res;
}


/*:::::*/
static void opengl_paint(void)
{
}


/*:::::*/
static int opengl_init(void)
{
	DEVMODE mode;
	DWORD style;
	RECT rect;
	HWND root;
	UINT flags;
	int x, y;

	style = GetWindowLong(fb_win32.wnd, GWL_STYLE);
	flags = SWP_FRAMECHANGED;
	if (fb_win32.flags & DRIVER_FULLSCREEN) {
		fb_hMemSet(&mode, 0, sizeof(mode));
		mode.dmSize = sizeof(mode);
		mode.dmPelsWidth = fb_win32.w;
		mode.dmPelsHeight = fb_win32.h;
		mode.dmBitsPerPel = fb_win32.depth;
		mode.dmDisplayFrequency = fb_win32.refresh_rate;
		mode.dmFields = DM_BITSPERPEL | DM_PELSWIDTH | DM_PELSHEIGHT;
		if (ChangeDisplaySettings(&mode, CDS_FULLSCREEN) != DISP_CHANGE_SUCCESSFUL)
			return -1;
		style &= ~WS_OVERLAPPEDWINDOW;
		style |= WS_POPUP;
		root = HWND_TOPMOST;
	}
	else {
		if (fb_win32.flags & DRIVER_NO_FRAME) {
			style &= ~WS_OVERLAPPEDWINDOW;
			style |= WS_POPUP;
		}
		else {
			style |= WS_OVERLAPPEDWINDOW;
			style &= ~(WS_POPUP | WS_THICKFRAME);
			if (fb_win32.flags & DRIVER_NO_SWITCH)
				style &= ~WS_MAXIMIZEBOX;
		}
		root = HWND_TOP;
		flags |= SWP_NOACTIVATE | SWP_NOOWNERZORDER | SWP_NOSENDCHANGING | SWP_NOZORDER;
	}
	SetWindowLong(fb_win32.wnd, GWL_STYLE, style);
	rect.left = rect.top = x = y = 0;
	rect.right = fb_win32.w;
	rect.bottom = fb_win32.h;
	if (!(fb_win32.flags & DRIVER_FULLSCREEN)) {
		AdjustWindowRect(&rect, style, FALSE);
		x = (GetSystemMetrics(SM_CXSCREEN) - rect.right) >> 1;
		y = (GetSystemMetrics(SM_CYSCREEN) - rect.bottom) >> 1;
	}
	SetWindowPos(fb_win32.wnd, 0, x, y, rect.right - rect.left, rect.bottom - rect.top, flags);
	ShowWindow(fb_win32.wnd, SW_SHOW);
	SetForegroundWindow(fb_win32.wnd);
	fb_win32.is_active = TRUE;
	__fb_gfx->refresh_rate = GetDeviceCaps(hdc, VREFRESH);

	return 0;
}


/*:::::*/
static void opengl_exit(void)
{
	if (fb_win32.flags & DRIVER_FULLSCREEN)
		ChangeDisplaySettings(NULL, 0);
	ShowWindow(fb_win32.wnd, SW_HIDE);
}


/*:::::*/
static int driver_init(char *title, int w, int h, int depth_arg, int refresh_rate, int flags)
{
	const char *wgl_funcs[] = { "wglCreateContext", "wglMakeCurrent", "wglDeleteContext", NULL };
	PIXELFORMATDESCRIPTOR pfd = {
        sizeof(PIXELFORMATDESCRIPTOR), 1,
		PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,
		PFD_TYPE_RGBA, fb_win32.depth,
		0, 0, 0, 0, 0, 0, 0, 0, (flags & HAS_ACCUMULATION_BUFFER) ? 32 : 0, 0, 0, 0, 0,
		32, (flags & HAS_STENCIL_BUFFER) ? 8 : 0,
		0, PFD_MAIN_PLANE, 0, 0, 0, 0
    };
	int attribs[] = {
		WGL_DRAW_TO_WINDOW_ARB, GL_TRUE,
		WGL_ACCELERATION_ARB,   WGL_FULL_ACCELERATION_ARB,
		WGL_DOUBLE_BUFFER_ARB,  GL_TRUE,
		WGL_COLOR_BITS_ARB,     fb_win32.depth,
		WGL_DEPTH_BITS_ARB,     24,
		WGL_STENCIL_BITS_ARB,   (flags & HAS_STENCIL_BUFFER) ? 8 : 0,
		WGL_ACCUM_BITS_ARB,     (flags & HAS_ACCUMULATION_BUFFER) ? 32 : 0,
		WGL_SAMPLE_BUFFERS_ARB, GL_TRUE,
		WGL_SAMPLES_ARB,		4,
		0
	};
    int depth = MAX(8, depth_arg);
	int pf = 0, num_formats, format;

	fb_hMemSet(&fb_win32, 0, sizeof(fb_win32));

	library	= NULL;
	hglrc = NULL;
	hdc = NULL;

	if (!(flags & DRIVER_OPENGL) || (flags & DRIVER_NO_FRAME))
		return -1;

	library = fb_hDynLoad("opengl32.dll", wgl_funcs, (void **)&fb_wgl);
	if (!library)
		return -1;

	fb_win32.init = opengl_init;
	fb_win32.exit = opengl_exit;
	fb_win32.paint = opengl_paint;

	if (fb_hWin32Init(title, w, h, depth, refresh_rate, flags))
		return -1;
	
	if (GL_init(&pfd))
		return -1;
	
	if (fb_hInitWindow((WS_CLIPSIBLINGS | WS_CLIPCHILDREN) & ~WS_THICKFRAME, 0, 0, 0, 8, 8))
		return -1;
	
	if (opengl_init())
		return -1;

	hdc = GetDC(fb_win32.wnd);
	if ((flags & HAS_MULTISAMPLE) && (fb_wgl.ChoosePixelFormatARB)) {
		for (attribs[17] = 4; attribs[17]; attribs[17] -= 2) {
			if ((fb_wgl.ChoosePixelFormatARB(hdc, attribs, NULL, 1, &format, &num_formats)) && (num_formats > 0)) {
				pf = format;
				break;
			}
		}
	}
	if (!pf) {
		flags &= ~HAS_MULTISAMPLE;
		pf = ChoosePixelFormat(hdc, &pfd);
	}
	
	if ((!pf) || (!SetPixelFormat(hdc, pf, &pfd)))
		return -1;
	hglrc = fb_wgl.CreateContext(hdc);
	if (!hglrc)
		return -1;
	fb_wgl.MakeCurrent(hdc, hglrc);

	if (flags & HAS_MULTISAMPLE)
		__fb_gl.Enable(GL_MULTISAMPLE_ARB);
	
	return 0;
}


/*:::::*/
static void driver_exit(void)
{
	if (library) {
		if (hglrc) {
			fb_wgl.MakeCurrent(NULL, NULL);
			fb_wgl.DeleteContext(hglrc);
		}
		if (hdc)
			ReleaseDC(fb_win32.wnd, hdc);
		if (fb_win32.flags & DRIVER_FULLSCREEN)
			ChangeDisplaySettings(NULL, 0);
		if (fb_win32.wnd)
			DestroyWindow(fb_win32.wnd);
		fb_hDynUnload(&library);
	}

	fb_hWin32Exit();
}


/*:::::*/
static void driver_lock(void)
{
}


/*:::::*/
static void driver_unlock(void)
{
}


/*:::::*/
static void driver_set_palette(int index, int r, int g, int b)
{
}


/*:::::*/
static void driver_flip(void)
{
    if( fb_win32.is_active ) {
        int i;
        unsigned char keystate[256];

        GetKeyboardState(keystate);
        for (i = 0; __fb_keytable[i][0]; i++) {
            if (__fb_keytable[i][2])
                __fb_gfx->key[__fb_keytable[i][0]] = ((keystate[__fb_keytable[i][1]] & 0x80) |
                                                   (keystate[__fb_keytable[i][2]] & 0x80)) ? TRUE : FALSE;
            else
                __fb_gfx->key[__fb_keytable[i][0]] = (keystate[__fb_keytable[i][1]] & 0x80) ? TRUE : FALSE;
        }
    }

	fb_hHandleMessages();

	SwapBuffers(hdc);
}


/*:::::*/
static int *driver_fetch_modes(int depth, int *size)
{
	DEVMODE devmode;
	int *modes = NULL, index = 0;

	*size = 0;

	for (;;) {
		if (!EnumDisplaySettings(NULL, index, &devmode))
			break;
		index++;
		if (devmode.dmBitsPerPel == depth) {
			(*size)++;
			modes = (int *)realloc(modes, *size * sizeof(int));
			modes[(*size) - 1] = (devmode.dmPelsWidth << 16) | devmode.dmPelsHeight;
		}
	}

	return modes;
}