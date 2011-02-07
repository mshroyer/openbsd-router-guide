# Root makefile for the Docbook-based Midgard manual

XML = manual.xml \
	ch-introduction.xml \
	ch-alix-board-setup.xml \
	ch-openbsd-installation.xml \
	ch-basic-configuration.xml \
	ch-security-updates.xml \
	ch-ports-packages.xml \
	ch-gateway.xml \
	ap-license.xml

XMLSRC = $(XML:%=src/%)

XSLTPROC = xsltproc --nonet

### Easy target names
xhtml : xhtml/index.html
xhtml-single : xhtml-single/manual.html

xhtml/index.html : $(XMLSRC) src/manual.css
	$(XSLTPROC) --xinclude -o xhtml/ xsl/xhtml-chunk.xsl src/manual.xml
	cp -f src/manual.css xhtml/

xhtml-single/manual.html : $(XMLSRC)
	$(XSLTPROC) --xinclude -o xhtml-single/manual.html xsl/xhtml-single.xsl src/manual.xml

files :
	perl getfiles.pl

clean :
	rm -f xhtml/*
