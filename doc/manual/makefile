HHC := hhc
FBDOC := ../fbdoc/fbdoc
MAKEFBHELP := ../makefbhelp/makefbhelp

# Nice names for the resulting .zip's and the important files
FB_VERSION  = 0.24.0
TITLE       = FB-manual-$(FB_VERSION)
CHM         = $(TITLE).chm
CHMZIP      = $(TITLE)-chm.zip
FBHELP      = fbhelp.daz
FBHELPZIP   = $(TITLE)-fbhelp.zip
HTMLZIP     = $(TITLE)-html.zip
TXT         = $(TITLE).txt
TXTZIP      = $(TITLE)-txt.zip
WAKKAZIP    = $(TITLE)-wakka.zip

################################################################################

all: $(CHMZIP) $(FBHELPZIP) $(HTMLZIP) $(TXTZIP) $(WAKKAZIP)

################################################################################
# chm

html/fbdoc.hhp:
	$(FBDOC) -chm

html/fbdoc.chm: html/fbdoc.hhp
	-$(HHC) $<

$(CHM): html/fbdoc.chm
	cp $< $@

$(CHMZIP): $(CHM)
	zip -q -9 $@ $<

################################################################################
# fbhelp

fbhelp/DocToc.txt:
	$(FBDOC) -fbhelp

fbhelp/fbhelp.dat: fbhelp/DocToc.txt
	$(MAKEFBHELP)

$(FBHELP): fbhelp/fbhelp.dat
	gzip -c $< > $@

$(FBHELPZIP): $(FBHELP)
	zip -q -9 $@ $<

################################################################################
# html

html/DocToc.html:
	$(FBDOC) -chm

html/00index.html: html/DocToc.html
	cp $< $@

$(HTMLZIP): html/00index.html
	cd html && zip -q -r -9 ../$@ *.html style.css images

################################################################################
# txt

txt/fbdoc.txt:
	$(FBDOC) -txt

$(TXT): txt/fbdoc.txt
	cp $< $@

$(TXTZIP): $(TXT)
	zip -q -9 $@ $<

################################################################################
# wakka

$(WAKKAZIP):
	cd cache && zip -q -9 ../$@ *.wakka

################################################################################

refresh:
	$(FBDOC) -refresh -useweb

clean:
	-rm -f html/*.html
	-rm -f html/fbdoc.hhc html/fbdoc.hhk html/fbdoc.hhp html/fbdoc.chm $(CHM)
	-rm -f fbhelp/*.txt fbhelp/fbhelp.dat $(FBHELP)
	-rm -f txt/*.txt $(TXT)
	-rm -f $(CHMZIP) $(FBHELPZIP) $(HTMLZIP) $(TXTZIP) $(WAKKAZIP)

.PHONY: clean
