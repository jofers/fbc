/* OR drawing method for PUT statement */

#include "fb_gfx.h"


#if defined(HOST_X86)

#include "fb_gfx_mmx.h"

extern void fb_hPutOrMMX(unsigned char *src, unsigned char *dest, int w, int h, int src_pitch, int dest_pitch, int alpha, BLENDER *blender, void *param);

#endif


/*:::::*/
void fb_hPutOrC(unsigned char *src, unsigned char *dest, int w, int h, int src_pitch, int dest_pitch, int alpha, BLENDER *blender, void *param)
{
	int x;
	FB_GFXCTX *context = fb_hGetContext();
	
	w <<= (context->target_bpp >> 1);
	src_pitch -= w;
	dest_pitch -= w;
	for (; h; h--) {
		if (w & 1)
			*dest++ |= *src++;
		if (w & 2) {
			*(unsigned short *)dest |= *(unsigned short *)src;
			dest += 2;
			src += 2;
		}
		for (x = w >> 2; x; x--) {
			*(unsigned int *)dest |= *(unsigned int *)src;
			dest += 4;
			src += 4;
		}
		src += src_pitch;
		dest += dest_pitch;
	}
}


/*:::::*/
void fb_hPutOr(unsigned char *src, unsigned char *dest, int w, int h, int src_pitch, int dest_pitch, int alpha, BLENDER *blender, void *param)
{
	static PUTTER *all_putters[] = {
		fb_hPutOrC, fb_hPutOrC, NULL, fb_hPutOrC,
#if defined(HOST_X86)
		fb_hPutOrMMX, fb_hPutOrMMX, NULL, fb_hPutOrMMX,
#endif
	};
	PUTTER *putter;
	FB_GFXCTX *context = fb_hGetContext();
	
	if (!context->putter[PUT_MODE_OR]) {
#if defined(HOST_X86)
		if (__fb_gfx->flags & HAS_MMX)
			context->putter[PUT_MODE_OR] = &all_putters[4];
		else
#endif
			context->putter[PUT_MODE_OR] = &all_putters[0];
	}
	putter = context->putter[PUT_MODE_OR][context->target_bpp - 1];
	
	putter(src, dest, w, h, src_pitch, dest_pitch, alpha, blender, param);
}
