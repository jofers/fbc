''
'' anti-aliased line example
''
'' to compile, build fbgl.bas first (fbc fbgl.bas -lib)
''

#include once "fbgl.bi" 

const XRES = 640
const YRES = 480

	'' import the fbgl symbols
	using fbgl
	
	'' create a window 
	init XRES, YRES
	
	'' change to anti-aliased mode
	setBlend BLEND_ANTIALISED
	setLineSmooth TRUE
	
	do 
		dim i as integer
		
		'' clear the working page
		cls
		
		'' draw the contents
		for i = 1 to 1000
			'' use 255 (100%) for alpha 
			color rgba(rnd * 255, rnd * 255, rnd * 255, 255) 
	   		
	   		'' line x1, y2, x2, y2
	   		line rnd * XRES, rnd * YRES, rnd * XRES, rnd * YRES
		next
	   	
	   '' copy the working page to the visible one
	   flip
	   
	loop while len( inkey ) = 0