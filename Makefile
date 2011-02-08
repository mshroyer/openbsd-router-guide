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
xhtml : out/xhtml/index.html
xhtml-web : out/xhtml-web/index.html
all : xhtml xhtml-web

out/xhtml/index.html : $(XMLSRC) src/manual.css
	$(XSLTPROC) --xinclude -o out/xhtml/ xsl/xhtml.xsl src/manual.xml
	cp -f src/manual.css out/xhtml/
	cp -prf src/images out/xhtml/images

out/xhtml-web/index.html : $(XMLSRC) src/manual.css
	$(XSLTPROC) --xinclude -o out/xhtml-web/ xsl/xhtml-web.xsl src/manual.xml
	cp -f src/manual.css out/xhtml-web/
	cp -prf src/images out/xhtml-web/images

files :
	perl getfiles.pl

upload : xhtml-web
	scp -pr out/xhtml-web/* frodo.paleogene.net:www/markshroyer.com/guides/router/

clean :
	rm -rf out/xhtml/*
	rm -rf out/xhtml-web/*
