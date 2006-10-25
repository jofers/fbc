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
 * win32.c -- common win32 routines and drivers list
 *
 * chng: jan/2005 written [lillo]
 *
 */

#include "fb_gfx.h"
#include "fb_gfx_win32.h"
#include <process.h>
#include <stdio.h>


WIN32DRIVER fb_win32;

const GFXDRIVER *fb_gfx_driver_list[] = {
#ifndef TARGET_CYGWIN
    &fb_gfxDriverDirectDraw,
#endif
	&fb_gfxDriverGDI,
	&fb_gfxDriverOpenGL,
	NULL
};


static CRITICAL_SECTION update_lock;
static HANDLE handle;
static BOOL screensaver_active, cursor_shown, has_focus = FALSE;
static UINT msg_cursor;
static int mouse_buttons, mouse_wheel, mouse_x, mouse_y;
static BOOL (WINAPI *_TrackMouseEvent)(TRACKMOUSEEVENT *) = NULL;
static POINT last_mouse_pos;


/*:::::*/
static void ToggleFullScreen( void )
{
    if (fb_win32.flags & DRIVER_NO_SWITCH)
        return;
    
    fb_win32.exit();
    fb_win32.flags ^= DRIVER_FULLSCREEN;
    if (fb_win32.init()) {
        fb_win32.exit();
        fb_win32.flags ^= DRIVER_FULLSCREEN;
        fb_win32.init();
    }
    fb_hRestorePalette();
    fb_hMemSet(fb_mode->dirty, TRUE, fb_win32.h);
    fb_win32.is_active = TRUE;
    has_focus = FALSE;
}


/*:::::*/
static VOID CALLBACK fb_hTrackMouseTimerProc(HWND hWnd, UINT uMsg, UINT idEvent, DWORD dwTime)
{
	RECT rect;
	POINT pt;

	GetClientRect(fb_win32.wnd, &rect);
	MapWindowPoints(fb_win32.wnd, NULL, (LPPOINT)&rect, 2);
	GetCursorPos(&pt);
	if ((!PtInRect(&rect, pt)) || (WindowFromPoint(pt) != fb_win32.wnd)) {
		KillTimer(fb_win32.wnd, idEvent);
		PostMessage(fb_win32.wnd, WM_MOUSELEAVE, 0, 0);
	}
}


/*:::::*/
static BOOL WINAPI fb_hTrackMouseEvent(TRACKMOUSEEVENT *e)
{
	if (e->dwFlags == TME_LEAVE)
		return SetTimer(e->hwndTrack, e->dwFlags, 100, (TIMERPROC)fb_hTrackMouseTimerProc);
	return FALSE;
}


/*:::::*/
LRESULT CALLBACK fb_hWin32WinProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	BYTE key_state[256];
	TRACKMOUSEEVENT track_e;
	POINT mouse_pos;
	EVENT e;
	
	e.type = 0;
	
	if (message == msg_cursor) {
		ShowCursor(wParam);
		return FALSE;
	}

	switch (message)
	{
		case WM_ACTIVATEAPP:
			fb_win32.is_active = (int)wParam;
			fb_hMemSet(fb_mode->key, FALSE, 128);
			mouse_buttons = 0;
			fb_hMemSet(fb_mode->dirty, TRUE, fb_win32.h);
			if ((has_focus) && (!wParam))
				PostMessage(fb_win32.wnd, WM_MOUSELEAVE, 0, 0);
			e.type = wParam ? EVENT_WINDOW_GOT_FOCUS : EVENT_WINDOW_LOST_FOCUS;
			break;
		
		case WM_MOUSEMOVE:
			GetCursorPos(&mouse_pos);
			e.type = EVENT_MOUSE_MOVE;
			mouse_x = e.x = lParam & 0xFFFF;
			mouse_y = e.y = (lParam >> 16) & 0xFFFF;
			if (last_mouse_pos.x == 0xFFFF) {
				e.dx = e.dy = 0;
			}
			else {
				e.dx = mouse_pos.x - last_mouse_pos.x;
				e.dy = mouse_pos.y - last_mouse_pos.y;
			}
			last_mouse_pos = mouse_pos;
			if ((!e.dx) && (!e.dy))
				e.type = 0;
			if (!has_focus) {
				track_e.cbSize = sizeof(TRACKMOUSEEVENT);
				track_e.dwFlags = TME_LEAVE;
				track_e.hwndTrack = hWnd;
				_TrackMouseEvent(&track_e);
				has_focus = TRUE;
				e.type = EVENT_MOUSE_ENTER;
			}
			break;

		case WM_MOUSELEAVE:
			e.type = EVENT_MOUSE_EXIT;
			fb_hPostEvent(&e);
			has_focus = FALSE;
			return 0;
		
		case WM_LBUTTONDOWN:
			SetCapture( hWnd );
			mouse_buttons |= 0x1;
			e.type = EVENT_MOUSE_BUTTON_PRESS;
			e.button = 0x1;
			break;

		case WM_LBUTTONUP:
			mouse_buttons &= ~0x1;
			if(!mouse_buttons && GetCapture() == hWnd)
				ReleaseCapture();
			e.type = EVENT_MOUSE_BUTTON_RELEASE;
			e.button = 0x1;
			break;

		case WM_RBUTTONDOWN:
			SetCapture( hWnd );
			mouse_buttons |= 0x2;
			e.type = EVENT_MOUSE_BUTTON_PRESS;
			e.button = 0x2;
			break;

		case WM_RBUTTONUP:
			mouse_buttons &= ~0x2;
			if(!mouse_buttons && GetCapture() == hWnd)
				ReleaseCapture();
			e.type = EVENT_MOUSE_BUTTON_RELEASE;
			e.button = 0x2;
			break;

		case WM_MBUTTONDOWN:
			SetCapture( hWnd );
			mouse_buttons |= 0x4;
			e.type = EVENT_MOUSE_BUTTON_PRESS;
			e.button = 0x4;
			break;

		case WM_MBUTTONUP:
			mouse_buttons &= ~0x4;
			if(!mouse_buttons && GetCapture() == hWnd)
				ReleaseCapture();
			e.type = EVENT_MOUSE_BUTTON_RELEASE;
			e.button = 0x4;
			break;

		case WM_MOUSEWHEEL:
			if (fb_win32.version < 0x40A)
				break;
			if ((signed)wParam > 0)
				mouse_wheel++;
			else
				mouse_wheel--;
			e.type = EVENT_MOUSE_WHEEL;
			e.z = mouse_wheel;
			break;
		
		case WM_SIZE:
        case WM_SYSKEYDOWN:
            if (!fb_win32.is_active)
                break;
            {
                int is_alt_enter = ((message == WM_SYSKEYDOWN) && (wParam == VK_RETURN) && (lParam & 0x20000000));
                int is_maximize = ((message == WM_SIZE) && (wParam == SIZE_MAXIMIZED));
                if ( is_maximize || is_alt_enter) {
                	if (has_focus) {
						e.type = EVENT_MOUSE_EXIT;
	                	fb_hPostEvent(&e);
	                }
                    ToggleFullScreen();
                    return FALSE;
                }
                if( message!=WM_SYSKEYDOWN )
                    break;
            }

        case WM_KEYDOWN:
		case WM_KEYUP:
            {
                WORD wVkCode = (WORD) wParam;
                WORD wVsCode = (WORD) (( lParam & 0xFF0000 ) >> 16);
                int is_ext_keycode = ( lParam & 0x1000000 )!=0;
                size_t repeat_count = ( lParam & 0xFFFF );
                DWORD dwControlKeyState = 0;
                char chAsciiChar;
                int is_dead_key;
                int key;

                GetKeyboardState(key_state);

                if( (key_state[VK_SHIFT] | key_state[VK_LSHIFT] | key_state[VK_RSHIFT]) & 0x80 )
                    dwControlKeyState ^= SHIFT_PRESSED;
                if( (key_state[VK_LCONTROL] | key_state[VK_CONTROL]) & 0x80 )
                    dwControlKeyState ^= LEFT_CTRL_PRESSED;
                if( key_state[VK_RCONTROL] & 0x80 )
                    dwControlKeyState ^= RIGHT_CTRL_PRESSED;
                if( (key_state[VK_LMENU] | key_state[VK_MENU]) & 0x80 )
                    dwControlKeyState ^= LEFT_ALT_PRESSED;
                if( key_state[VK_RMENU] & 0x80 )
                    dwControlKeyState ^= RIGHT_ALT_PRESSED;
                if( is_ext_keycode )
                    dwControlKeyState |= ENHANCED_KEY;

                is_dead_key = (MapVirtualKey( wVkCode, 2 ) & 0x80000000)!=0;
                if( !is_dead_key ) {
                    WORD wKey = 0;
                    if( ToAscii( wVkCode, wVsCode, key_state, &wKey, 0 )==1 ) {
                        chAsciiChar = (char) wKey;
                    } else {
                        chAsciiChar = 0;
                    }
                } else {
                    /* Never use ToAscii when a dead key is used - otherwise
                     * we don't get the combined character (for accents) */
                    chAsciiChar = 0;
                }
                key =
                    fb_hConsoleTranslateKey( chAsciiChar,
                                             wVsCode,
                                             wVkCode,
                                             dwControlKeyState,
                                             FALSE );
                if (message == WM_KEYDOWN) {
					if (key > 0xFF) {
	   	                while( repeat_count-- ) {
    	   	                fb_hPostKey(key);
        	   	        }
        	   	    }
        	   	    e.type = EVENT_KEY_PRESS;
                }
                else
                	e.type = EVENT_KEY_RELEASE;
                e.scancode = fb_hVirtualToScancode(wVkCode);
                e.ascii = key < 0 ? 0 : key;

                /* We don't want to enter the menu ... */
                if( wVkCode==VK_F10 || wVkCode==VK_MENU || key==0x6BFF )
                    return FALSE;
            }
            break;
			
        case WM_CHAR:
            {
                size_t repeat_count = ( lParam & 0xFFFF );
                int key = (int) wParam;
                if( key < 256 ) {
                    int target_cp = FB_GFX_GET_CODEPAGE();
                    if( target_cp!=-1 ) {
                        char ch[2] = {
                            (char) key,
                            0
                        };
                        FBSTRING *result =
                            fb_StrAllocTempDescF( ch, 2 );
                        result = fb_hIntlConvertString( result,
                                                        CP_ACP,
                                                        target_cp );
                        key = (unsigned) (unsigned char) result->data[0];
                        fb_hStrDelTemp( result );
                    }

                    while( repeat_count-- ) {
                        fb_hPostKey(key);
                    }
                }
            }

            break;

		case WM_CLOSE:
			fb_hPostKey(0x6BFF); /* ALT + F4 */
			e.type = EVENT_WINDOW_CLOSE;
			fb_hPostEvent(&e);
			return FALSE;

		case WM_PAINT:
			fb_win32.paint();
			break;
	}
	
	if (e.type)
		fb_hPostEvent(&e);

	return DefWindowProc(hWnd, message, wParam, lParam);
}


/*:::::*/
void fb_hHandleMessages(void)
{
	MSG message;

	while (PeekMessage(&message, fb_win32.wnd, 0, 0, PM_REMOVE)) {
		TranslateMessage(&message);
		DispatchMessage(&message);
	}
}


/*:::::*/
int fb_hWin32Init(char *title, int w, int h, int depth, int refresh_rate, int flags)
{
	OSVERSIONINFO info;
	HMODULE module;
	HANDLE events[2];
	long result;

	info.dwOSVersionInfoSize = sizeof(info);
	GetVersionEx(&info);
	fb_win32.version = (info.dwMajorVersion << 8) | info.dwMinorVersion;

	msg_cursor = RegisterWindowMessage("FB mouse cursor");
	cursor_shown = TRUE;
	last_mouse_pos.x = 0xFFFF;
	
	if (!_TrackMouseEvent) {
		module = GetModuleHandle("user32.dll");
		if (module)
			_TrackMouseEvent = (BOOL (WINAPI *)(TRACKMOUSEEVENT *))GetProcAddress(module, "TrackMouseEvent");
		if (!_TrackMouseEvent)
			_TrackMouseEvent = fb_hTrackMouseEvent;
	}

	SystemParametersInfo(SPI_GETSCREENSAVEACTIVE, 0, &screensaver_active, 0);
	SystemParametersInfo(SPI_SETSCREENSAVEACTIVE, FALSE, NULL, 0);

	fb_win32.hinstance = (HINSTANCE)GetModuleHandle(NULL);
	fb_win32.window_title = title;
	strcpy( fb_win32.window_class, WINDOW_CLASS_PREFIX );
	strncat( fb_win32.window_class, fb_win32.window_title, WINDOW_TITLE_SIZE + sizeof(WINDOW_CLASS_PREFIX) - 1 );
	fb_win32.w = w;
	fb_win32.h = h;
	fb_win32.depth = depth;
	fb_win32.flags = flags;
	fb_win32.refresh_rate = refresh_rate;
	fb_win32.wndclass.lpfnWndProc = fb_hWin32WinProc;
	fb_win32.wndclass.lpszClassName = fb_win32.window_class;
	fb_win32.wndclass.hInstance = fb_win32.hinstance;
	fb_win32.wndclass.hCursor = LoadCursor(0, IDC_ARROW);
	fb_win32.wndclass.hIcon = LoadIcon(fb_win32.hinstance, "FB_PROGRAM_ICON");
	if (!fb_win32.wndclass.hIcon)
		fb_win32.wndclass.hIcon = LoadIcon(NULL, IDI_APPLICATION);
	fb_win32.wndclass.style = CS_VREDRAW | CS_HREDRAW | (flags & DRIVER_OPENGL ? CS_OWNDC : 0);
	RegisterClass(&fb_win32.wndclass);

	mouse_buttons = mouse_wheel = 0;
	fb_win32.is_running = TRUE;

	if (!(flags & DRIVER_OPENGL)) {
		InitializeCriticalSection(&update_lock);
        events[0] = CreateEvent(NULL, FALSE, FALSE, NULL);
#ifdef TARGET_WIN32
        events[1] = (HANDLE)_beginthread(fb_win32.thread, 0, events[0]);
#else
        {
            DWORD dwThreadId;
            events[1] = CreateThread( NULL,
                                      0,
                                      (LPTHREAD_START_ROUTINE) fb_win32.thread,
                                      events[0],
                                      0,
                                      &dwThreadId );
            DBG_ASSERT( events[1]!=INVALID_HANDLE_VALUE );
        }
#endif
		result = WaitForMultipleObjects(2, events, FALSE, INFINITE);
		CloseHandle(events[0]);
		handle = events[1];
		if (result != WAIT_OBJECT_0)
			return -1;

		SetThreadPriority(handle, THREAD_PRIORITY_ABOVE_NORMAL);
	}
	else
		handle = NULL;

	return 0;
}


/*:::::*/
void fb_hWin32Exit(void)
{
	if (!fb_win32.is_running)
		return;
	fb_win32.is_running = FALSE;
	if (handle) {
		WaitForSingleObject(handle, INFINITE);
		DeleteCriticalSection(&update_lock);
	}
	SystemParametersInfo(SPI_SETSCREENSAVEACTIVE, screensaver_active, NULL, 0);
	UnregisterClass(fb_win32.window_class, fb_win32.hinstance);
}


/*:::::*/
void fb_hWin32Lock(void)
{
	EnterCriticalSection(&update_lock);
}


/*:::::*/
void fb_hWin32Unlock(void)
{
	LeaveCriticalSection(&update_lock);
}


/*:::::*/
void fb_hWin32SetPalette(int index, int r, int g, int b)
{
	fb_win32.palette[index].peRed = r;
	fb_win32.palette[index].peGreen = g;
	fb_win32.palette[index].peBlue = b;
	fb_win32.palette[index].peFlags = PC_NOCOLLAPSE;
	fb_win32.is_palette_changed = TRUE;
}


/*:::::*/
void fb_hWin32WaitVSync(void)
{
	Sleep(1000 / (fb_mode->refresh_rate ? fb_mode->refresh_rate : 60));
}


/*:::::*/
int fb_hWin32GetMouse(int *x, int *y, int *z, int *buttons)
{
	POINT point;

	if (!fb_win32.is_active)
		return -1;
	
	*x = mouse_x;
	*y = mouse_y;
	*z = mouse_wheel;
	*buttons = mouse_buttons;

	return 0;
}


/*:::::*/
void fb_hWin32SetMouse(int x, int y, int cursor)
{
	POINT point;

	if (x >= 0) {
		point.x = MID(0, x, fb_win32.w - 1);
		point.y = MID(0, y, fb_win32.h - 1);
		if (!(fb_win32.flags & DRIVER_FULLSCREEN))
			ClientToScreen(fb_win32.wnd, &point);
		SetCursorPos(point.x, point.y);
		mouse_x = x;
		mouse_y = y;
	}

	if ((cursor == 0) && (cursor_shown)) {
		PostMessage(fb_win32.wnd, msg_cursor, FALSE, 0);
		cursor_shown = FALSE;
	}
	else if ((cursor > 0) && (!cursor_shown)) {
		PostMessage(fb_win32.wnd, msg_cursor, TRUE, 0);
		cursor_shown = TRUE;
	}
}


/*:::::*/
void fb_hWin32SetWindowTitle(char *title)
{
	if (fb_mode->flags & SCREEN_LOCKED)
		LeaveCriticalSection(&update_lock);
	SetWindowText(fb_win32.wnd, title);
	if (fb_mode->flags & SCREEN_LOCKED)
		EnterCriticalSection(&update_lock);
}


/*:::::*/
int fb_hWin32SetWindowPos(int x, int y)
{
	RECT rect;
	
	if (fb_win32.flags & DRIVER_FULLSCREEN)
		return 0;
	
	GetWindowRect(fb_win32.wnd, &rect);
	if (x == 0x80000000)
		x = rect.left;
	if (y == 0x80000000)
		y = rect.top;
	SetWindowPos(fb_win32.wnd, HWND_TOP, x, y, rect.right - rect.left, rect.bottom - rect.top,
		SWP_ASYNCWINDOWPOS | SWP_NOOWNERZORDER | SWP_NOSIZE | SWP_NOZORDER);

	return (rect.left & 0xFFFF) | (rect.top << 16);
}


/*:::::*/
void fb_hScreenInfo(int *width, int *height, int *depth, int *refresh)
{
	HDC hdc;

	hdc = GetDC(NULL);
	*width = GetDeviceCaps(hdc, HORZRES);
	*height = GetDeviceCaps(hdc, VERTRES);
	*depth = GetDeviceCaps(hdc, BITSPIXEL);
	*refresh = GetDeviceCaps(hdc, VREFRESH);
	ReleaseDC(NULL, hdc);
}


/*:::::*/
int fb_hGetWindowHandle(void)
{
	return (int)fb_win32.wnd;
}
