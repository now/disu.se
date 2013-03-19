JAVA = java
NMC = $(HOME)/opt/local/bin/nmc
MD5SUM = md5sum

XML_CATALOG_FILES = $(HOME)/opt/local/etc/xml/catalog
export XML_CATALOG_FILES
XSLTPROC = xsltproc

NML2HTML = data/templates/disuse.xsl

HTML = \
	www/about/contact/index.html \
	www/about/index.html \
	www/about/resume/index.html \
	www/index.html \
	www/software/index.html \
	www/software/lookout/index.html \
	$(patsubst %.nml,%.html,$(shell find www/software/lookout/api -type f -name '*.nml'))
#       $(patsubst %.nml,%.html,$(shell find www/software/u/api -type f -name '*.nml'))

JING = jing-20091111
RESOLVER = xml-commons-resolver-1.2

ROOT =

DEFAULT_VERBOSITY = 0

-include config.mk

V_at = $(_v_at_$(V))
_v_at_ = $(_v_at_$(DEFAULT_VERBOSITY))
_v_at_0 = @
_v_at_1 =

all: $(HTML)

tools/jing.jar tools/xercesImpl.jar:
	curl -s http://jing-trang.googlecode.com/files/$(JING).zip > $@.tmp
	unzip -p $@.tmp $(JING)/bin/$(notdir $@) > $@
	rm $@.tmp

tools/resolver.jar:
	curl -s http://www.apache.org/dist/xerces/xml-commons/binaries/$(RESOLVER).zip.md5 > $@.md5
	curl -s http://apache.mirrors.spacedump.net//xerces/xml-commons/binaries/$(RESOLVER).zip > $@.tmp
	$(MD5SUM) $@.tmp | cut -d ' ' -f 1 | cmp $@.md5
	unzip -p $@.tmp $(RESOLVER)/$(notdir $@) > $@
	rm $@.md5 $@.tmp

V_NMT2NML = $(V_NMT2NML_$(V))
V_NMT2NML_ = $(V_NMT2NML_$(DEFAULT_VERBOSITY))
V_NMT2NML_0 = @echo "  GEN-NML  " $@;

%.nml: %.nmc
	$(V_NMT2NML)rm -f $@ $@.tmp
	$(V_at)$(NMC) $< > $@.tmp
	$(V_at)chmod a-w $@.tmp
	$(V_at)mv $@.tmp $@

V_NML2HTML = $(V_NML2HTML_$(V))
V_NML2HTML_ = $(V_NML2HTML_$(DEFAULT_VERBOSITY))
V_NML2HTML_0 = @echo "  GEN-HTML " $@;

%.html: %.nml $(NML2HTML) tools/jing.jar tools/xercesImpl.jar tools/resolver.jar
	$(V_NML2HTML)$(JAVA) \
	  -Dorg.apache.xerces.xni.parser.XMLParserConfiguration=org.apache.xerces.parsers.XIncludeParserConfiguration \
	  -jar tools/jing.jar \
	  -C $(XML_CATALOG_FILES) \
	  -c data/nml.rnc $<
	$(V_at)stylesheet=$(ROOT)/www/style.css; \
	  local=$(basename $@).css; \
	  test -e "$$local" && stylesheet=$(ROOT)/$$local; \
	  $(XSLTPROC) \
	    --xinclude \
	    --stringparam root "$(ROOT)/www" \
	    --stringparam path "$(ROOT)/$<" \
	    --stringparam stylesheet "$$stylesheet" \
	    --output "$@" \
	    "$(NML2HTML)" "$<"

PROJECTS = $(HOME)/Projects

LOOKOUT = $(PROJECTS)/lookout

www/software/lookout/index.nmc: $(LOOKOUT)/README
	cp -p $< $@

YARD_TEMPLATE = $(PWD)/templates/now

apis: lookout-api u-api

LOOKOUT_API = $(PWD)/www/software/lookout/api

lookout-api:
	cd "$(LOOKOUT)" && rake html OPTIONS="--output $(LOOKOUT_API)"
	find "$(LOOKOUT_API)" -type f -name '*.html' -print0 | \
	  parallel -0 '$(XSLTPROC) \
	    --stringparam path "{}" \
	    --output "{.}.nml" \
	    templates/html2nml.xsl \
	    "{}" && \
	      rm "{}"'

U = $(HOME)/Projects/u
U_API = $(PWD)/www/software/u/api

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
