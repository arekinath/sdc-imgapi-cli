#
# Copyright (c) 2012, Joyent, Inc. All rights reserved.
#
# Makefile for IMGAPI
#

#
# Vars, Tools, Files, Flags
#
NAME		:= imgapi-cli
DOC_FILES	 = index.restdown
JS_FILES	:= $(shell find lib test -name '*.js' | grep -v '/tmp/')
JSL_CONF_NODE	 = tools/jsl.node.conf
JSL_FILES_NODE	 = $(JS_FILES)
JSSTYLE_FILES	 = $(JS_FILES)
JSSTYLE_FLAGS	 = -f tools/jsstyle.conf
NODEUNIT	:= ./node_modules/.bin/nodeunit

# We're using the 'gz' prebuilt node here because we'll be placing these
# builds down in the SmartOS gz.
ifeq ($(shell uname -s),SunOS)
	NODE_PREBUILT_VERSION=v0.8.23
	NODE_PREBUILT_TAG=gz
endif


include ./tools/mk/Makefile.defs
ifeq ($(shell uname -s),SunOS)
	include ./tools/mk/Makefile.node_prebuilt.defs
else
	NPM_EXEC :=
	NPM = npm
endif
include ./tools/mk/Makefile.smf.defs

RELEASE_TARBALL	:= $(NAME)-pkg-$(STAMP).tar.bz2
TMPDIR          := /tmp/$(STAMP)



#
# Targets
#
.PHONY: all
all: | $(NODEUNIT)
	$(NPM) install

$(NODEUNIT): | $(NPM_EXEC)
	$(NPM) install

.PHONY: test
test: | $(NODEUNIT)
	$(NODEUNIT) test/*.test.js

.PHONY: release
release: all
	@echo "Building $(RELEASE_TARBALL)"
	mkdir -p $(TMPDIR)/$(NAME)
	cp -r \
		$(TOP)/bin \
		$(TOP)/build \
		$(TOP)/lib \
		$(TOP)/node_modules \
		$(TOP)/package.json \
		$(TOP)/README.md \
		$(TOP)/test \
		$(TMPDIR)/$(NAME)
	(cd $(TMPDIR) && $(TAR) -jcf $(TOP)/$(RELEASE_TARBALL) $(NAME))
	@rm -rf $(TMPDIR)

.PHONY: publish
publish: release
	@if [[ -z "$(BITS_DIR)" ]]; then \
		@echo "error: 'BITS_DIR' must be set for 'publish' target"; \
		exit 1; \
	fi
	mkdir -p $(BITS_DIR)/$(NAME)
	cp $(TOP)/$(RELEASE_TARBALL) $(BITS_DIR)/$(NAME)/$(RELEASE_TARBALL)


include ./tools/mk/Makefile.deps
ifeq ($(shell uname -s),SunOS)
	include ./tools/mk/Makefile.node_prebuilt.targ
endif
include ./tools/mk/Makefile.smf.targ
include ./tools/mk/Makefile.targ
