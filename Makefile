JAVA = java
NMC = $(HOME)/opt/local/bin/nmc
MD5SUM = md5sum

XML_CATALOG_FILES = $(HOME)/opt/local/etc/xml/catalog
export XML_CATALOG_FILES
XSLTPROC = xsltproc

NML2HTML = data/templates/disuse.xsl

HTML = \
	www/404.html \
	www/about/contact/index.html \
	www/about/index.html \
	www/about/resume/index.html \
	www/articles/piping-quickfix-lists-to-vim/index.html \
	www/index.html \
	www/licenses/gpl-3.0/index.html \
	www/licenses/lgpl-3.0/index.html \
	www/search/index.html \
	www/software/index.html \
	www/software/ame-1.0/index.html \
	www/software/ame-1.0/api/index.html \
	$(patsubst %.nml,%.html,$(shell find www/software/ame-1.0/api/developer -type f -name '*.nml')) \
	$(patsubst %.nml,%.html,$(shell find www/software/ame-1.0/api/user -type f -name '*.nml')) \
	www/software/inventory-1.0/index.html \
	$(patsubst %.nml,%.html,$(shell find www/software/inventory-1.0/api -type f -name '*.nml')) \
	www/software/inventory-rake-1.0/index.html \
	$(patsubst %.nml,%.html,$(shell find www/software/inventory-rake-1.0/api -type f -name '*.nml')) \
	www/software/inventory-rake-tasks-yard-1.0/index.html \
	$(patsubst %.nml,%.html,$(shell find www/software/inventory-rake-tasks-yard-1.0/api -type f -name '*.nml')) \
	www/software/lookout-3.0/index.html \
	$(patsubst %.nml,%.html,$(shell find www/software/lookout-3.0/api -type f -name '*.nml')) \
	www/software/lookout-rack-1.0/index.html \
	$(patsubst %.nml,%.html,$(shell find www/software/lookout-rack-1.0/api -type f -name '*.nml')) \
	www/software/lookout-rake-3.0/index.html \
	$(patsubst %.nml,%.html,$(shell find www/software/lookout-rake-3.0/api -type f -name '*.nml')) \
	www/software/u-1.0/index.html \
        $(patsubst %.nml,%.html,$(shell find www/software/u-1.0/api -type f -name '*.nml')) \
	www/software/value-1.0/index.html \
        $(patsubst %.nml,%.html,$(shell find www/software/value-1.0/api -type f -name '*.nml')) \
	www/software/yard-heuristics-1.0/index.html \
	www/software/yard-value-1.0/index.html

JING = jing-20091111
RESOLVER = xml-commons-resolver-1.2

REMOVABLE_ABSOLUTE = http://disu.se/

DEFAULT_VERBOSITY = 0

-include config.mk

V_at = $(_v_at_$(V))
_v_at_ = $(_v_at_$(DEFAULT_VERBOSITY))
_v_at_0 = @
_v_at_1 =

all: templates/now/default/fulldoc/html/css/style.css

all: $(HTML)

tools/jing.jar tools/xercesImpl.jar:
	mkdir -p tools
	curl -s http://jing-trang.googlecode.com/files/$(JING).zip > $@.tmp
	unzip -p $@.tmp $(JING)/bin/$(notdir $@) > $@
	rm $@.tmp

tools/resolver.jar:
	curl -s http://www.apache.org/dist/xerces/xml-commons/binaries/$(RESOLVER).zip.md5 > $@.md5
	curl -s http://apache.mirrors.spacedump.net//xerces/xml-commons/binaries/$(RESOLVER).zip > $@.tmp
	$(MD5SUM) $@.tmp | cut -d ' ' -f 1 | cmp $@.md5
	unzip -p $@.tmp $(RESOLVER)/$(notdir $@) > $@
	rm $@.md5 $@.tmp

V_CP = $(V_CP_$(V))
V_CP_ = $(V_CP_$(DEFAULT_VERBOSITY))
V_CP_0 = @echo "  CP       " $@;

templates/now/default/fulldoc/html/css/style.css: www/style.css
	$(V_CP)rm -f $@ $@.tmp
	$(V_at)cp $< $@.tmp
	$(V_at)chmod a-w $@.tmp
	$(V_at)mv $@.tmp $@

V_NMT2NML = $(V_NMT2NML_$(V))
V_NMT2NML_ = $(V_NMT2NML_$(DEFAULT_VERBOSITY))
V_NMT2NML_0 = @echo "  GEN-NML  " $@;

%.nml: %.nmt
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
	$(V_at)rm -f $@.tmp $@
	$(V_at)stylesheet=/style.css; \
	  local=$(basename $@).css; \
	  test -e "$$local" && stylesheet=/`expr "$$local" : '[^/]*/\(.*\)'`; \
          xstylesheet="$(NML2HTML)"; \
	  local=$(basename $@).xsl; \
	  test -e "$$local" && xstylesheet=$$local; \
	  $(XSLTPROC) \
	    --xinclude \
	    --stringparam removable-absolute "$(REMOVABLE_ABSOLUTE)" \
	    --stringparam root "/www" \
	    --stringparam path "/$<" \
	    --stringparam stylesheet "$$stylesheet" \
	    --output "$@.tmp" \
	    "$$xstylesheet" "$<"
	$(V_at)chmod a-w $@.tmp
	$(V_at)mv $@.tmp $@

PROJECTS = $(HOME)/Projects

V_README = $(V_README_$(V))
V_README_ = $(V_README_$(DEFAULT_VERBOSITY))
V_README_0 = @echo "  README   " $@;

define PROJECT_README_template
www/software/$(1)/index.nmt: $$(PROJECTS)/$(1)/README
	$$(V_README)rm -f $$@.tmp $$@
	$$(V_at)mkdir -p $$(dir $$@)
	$$(V_at)cp -p $$< $$@.tmp
	$$(V_at)chmod a-w $$@.tmp
	$$(V_at)mv $$@.tmp $$@

endef

define PROJECT_README
$(eval $(call PROJECT_README_template,$(1)))
endef

V_API = $(V_API_$(V))
V_API_ = $(V_API_$(DEFAULT_VERBOSITY))
V_API_0 = @echo "  API      " $@;

define PROJECT_API_template
apis: $(1)$(if $(2),-$(2))-api
$(1)$(if $(2),-$(2))-api:
	$$(V_API)rm -rf "$$(PWD)/www/software/$(1)/api$(if $(2),/$(2))"
	$$(V_at)cd "$$(PROJECTS)/$(1)" && rake html OPTIONS="--output $$(PWD)/www/software/$(1)/api$(if $(2),/$(2))$(if $(3), $(3))"
	$$(V_at)find "$$(PWD)/www/software/$(1)/api$(if $(2),/$(2))" -type f -name '*.html' -print0 | \
	  parallel -0 '$$(XSLTPROC) \
	    --stringparam path "{}" \
	    --output "{.}.nml" \
	    templates/html2nml.xsl \
	    "{}" && \
	      rm "{}"'

endef

define PROJECT_API
$(eval $(call PROJECT_API_template,$(1),$(2),$(3)))
endef

define PROJECT_template
$(call PROJECT_README,$(1))
$(call PROJECT_API,$(1))
endef

define PROJECT
$(eval $(call PROJECT_template,$(1)))
endef

$(call PROJECT_README,ame-1.0)
$(call PROJECT_API,ame-1.0,developer,--api developer/user --api developer --no-api)
$(call PROJECT_API,ame-1.0,user,--api developer/user --api user --no-api)
$(call PROJECT,inventory-1.0)
$(call PROJECT,inventory-rake-1.0)
$(call PROJECT,inventory-rake-tasks-yard-1.0)
$(call PROJECT,lookout-3.0)
$(call PROJECT,lookout-rack-1.0)
$(call PROJECT,lookout-rake-3.0)
$(call PROJECT,u-1.0)
$(call PROJECT,value-1.0)
$(call PROJECT_README,yard-heuristics-1.0)
$(call PROJECT_README,yard-value-1.0)

push:
	rsync -avz --delete www/. disu.se:/var/www/disu.se/
