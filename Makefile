JAVA = java

XSLTPROC = xsltproc

NML2HTML = data/templates/disuse.xsl

HTML = \
       www/about/contact/index.html \
       www/about/index.html \
       www/about/resume/index.html \
       www/index.html \
       www/software/index.html \
       www/software/lookout/index.html

JING = jing-20091111

ROOT =

-include config.mk

all: $(HTML)

tools/jing.jar tools/xercesImpl.jar:
	curl http://jing-trang.googlecode.com/files/$(JING).zip > $@.tmp
	unzip -p $@.tmp $(JING)/bin/$(notdir $@) > $@
	rm $@.tmp

%.nml: %.nmc
	rm -f $@ $@.tmp
	nmc $< > $@.tmp
	chmod a-w $@.tmp
	mv $@.tmp $@

%.html: %.nml $(NML2HTML) tools/jing.jar tools/xercesImpl.jar
	root=`nmc --templates-root`; \
	stylesheet=$(ROOT)/www/style.css; \
	local=$(basename $@).css; \
	test -e "$$local" && stylesheet=$(ROOT)/$$local; \
	$(JAVA) \
	  -Dorg.apache.xerces.xni.parser.XMLParserConfiguration=org.apache.xerces.parsers.XIncludeParserConfiguration \
	  -jar tools/jing.jar \
	  -c $$root/../nml/nml.rnc $< && \
	    $(XSLTPROC) \
	      --path $$root/html \
	      --xinclude \
	      --stringparam root "$(ROOT)/www" \
	      --stringparam path "$(ROOT)/$<" \
	      --stringparam stylesheet "$$stylesheet" \
	      --output $@ \
	      $(NML2HTML) $<
