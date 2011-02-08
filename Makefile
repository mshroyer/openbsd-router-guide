# Root makefile for the Docbook-based Midgard manual

XML = manual.xml \
	ch-introduction.xml \
	ch-alix-board-setup.xml \
	ch-openbsd-installation.xml \
	ch-basic-configuration.xml \
	ch-security-updates.xml \
	ch-ports-packages.xml \
	ch-gateway.xml \
	ap-license.xml \
	ap-todo.xml

XMLSRC = $(XML:%=src/%)

XSLTPROC = xsltproc --nonet

### Easy target names
xhtml : xhtml/index.html
web : web/index.html
xhtml-single : xhtml-single/manual.html

xhtml/index.html : $(XMLSRC) src/manual.css
	$(XSLTPROC) --xinclude -o xhtml/ xsl/xhtml-chunk.xsl src/manual.xml
	cp -f src/manual.css xhtml/
	cp -prf src/images xhtml/images

web/index.html : $(XMLSRC) src/manual.css
	$(XSLTPROC) --xinclude -o web/ xsl/xhtml-chunk.xsl src/manual.xml
	cp -f src/manual.css web/
	cp -prf src/images web/images

xhtml-single/manual.html : $(XMLSRC)
	$(XSLTPROC) --xinclude -o xhtml-single/manual.html xsl/xhtml-single.xsl src/manual.xml

files :
	perl getfiles.pl

clean :
	rm -rf xhtml/*
	rm -rf web/*
