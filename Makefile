JAVA = java

XSLTPROC = xsltproc

NML2HTML = data/templates/disuse.xsl
NML_TEMPLATES = $(shell nmc --templates-root)

HTML = \
       www/about/contact/index.html \
       www/about/index.html \
       www/about/resume/index.html \
       www/index.html \
       www/software/index.html \
       www/software/lookout/index.html \
       $(patsubst %.nml,%.html,$(shell find www/software/u/api -type f -name '*.nml'))

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

# TODO: This stylesheet test can’t possible be right.  Where’s the parent
# directory?
%.html: %.nml $(NML2HTML) tools/jing.jar tools/xercesImpl.jar
	stylesheet=$(ROOT)/www/style.css; \
	local=`basename "$@"`.css; \
	test -e "$$local" && stylesheet=$(ROOT)/$$local; \
	$(JAVA) \
	  -Dorg.apache.xerces.xni.parser.XMLParserConfiguration=org.apache.xerces.parsers.XIncludeParserConfiguration \
	  -jar tools/jing.jar \
	  -c "$(NML_TEMPLATES)/../nml/nml.rnc" $< && \
	    $(XSLTPROC) \
	      --path "$(NML_TEMPLATES)/html" \
	      --xinclude \
	      --stringparam root "$(ROOT)/www" \
	      --stringparam path "$(ROOT)/$<" \
	      --stringparam stylesheet "$$stylesheet" \
	      --output "$@" \
	      "$(NML2HTML)" "$<"

U = $(HOME)/Projects/u
YARD_TEMPLATE = $(PWD)/templates/now
U_API = $(PWD)/www/software/u/api

apis: u-api

# TODO: Might want to use --template instead of --template-path.
u-api:
	cd "$(U)" && rake yard \
	  OPTS="--template-path $(YARD_TEMPLATE) \
                --output $(U_API)"
	rm -f "$(U_API)/file.README.html"
	find "$(U_API)" -type f -name '*.html' -print0 | \
	  parallel -0 '$(XSLTPROC) \
	    --stringparam path "{}" \
	    --output "{.}.nml" \
	    templates/html2nml.xsl \
	    "{}" && rm "{}"'
