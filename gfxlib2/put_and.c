/* AND drawing method for PUT statement */

#include "fb_gfx.h"


#if defined(HOST_X86)

#include "fb_gfx_mmx.h"

extern void fb_hPutAndMMX(unsigned char *src, unsigned char *dest, int w, int h, int src_pitch, int dest_pitch, int alpha, BLENDER *blender, void *param);

#endif


/*:::::*/
static void fb_hPutAndC(unsigned char *src, unsigned char *dest, int w, int h, int src_pitch, int dest_pitch, int alpha, BLENDER *blender, void *param)
{
	int x;
	FB_GFXCTX *context = fb_hGetContext();
	
	w <<= (context->target_bpp >> 1);
	src_pitch -= w;
	dest_pitch -= w;
	for (; h; h--) {
		if (w & 1)
			*dest++ &= *src++;
		if (w & 2) {
			*(unsigned short *)dest &= *(unsigned short *)src;
			dest += 2;
			src += 2;
		}
		for (x = w >> 2; x; x--) {
			*(unsigned int *)dest &= *(unsigned int *)src;
			dest += 4;
			src += 4;
		}
		src += src_pitch;
		dest += dest_pitch;
	}
}


/*:::::*/
void fb_hPutAnd(unsigned char *src, unsigned char *dest, int w, int h, int src_pitch, int dest_pitch, int alpha, BLENDER *blender, void *param)
{
	static PUTTER *all_putters[] = {
		fb_hPutAndC, fb_hPutAndC, NULL, fb_hPutAndC,
#if defined(HOST_X86)
		fb_hPutAndMMX, fb_hPutAndMMX, NULL, fb_hPutAndMMX,
#endif
	};
	PUTTER *putter;
	FB_GFXCTX *context = fb_hGetContext();
	
	if (!context->putter[PUT_MODE_AND]) {
#if defined(HOST_X86)
		if (__fb_gfx->flags & HAS_MMX)
			context->putter[PUT_MODE_AND] = &all_putters[4];
		else
#endif
			context->putter[PUT_MODE_AND] = &all_putters[0];
	}
	putter = context->putter[PUT_MODE_AND][context->target_bpp - 1];
	
	putter(src, dest, w, h, src_pitch, dest_pitch, alpha, blender, param);
}
