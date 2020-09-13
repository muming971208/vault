# ***
# WARNING: Do not EDIT or MERGE this file, it is generated by packagespec.
# ***
# packagespec.mk should be included at the end of your main Makefile,
# it provides hooks into packagespec targets, so you can run them
# from the root of your product repository.
#
# All packagespec-generated make targets assume they are invoked by
# targets in this file, which provides the necessary context for those
# other targets. Therefore, this file is not just for conveninence but
# is currently necessary to the correct functioning of Packagespec.

SHELL := /usr/bin/env bash -euo pipefail -c

# This can be overridden by the calling Makefile to write config to a different path.
PACKAGESPEC_CIRCLECI_CONFIG ?= .circleci/config.yml

SPEC_FILE_PATTERN := packages*.yml
# SPEC is the human-managed description of which packages we are able to build.
SPEC := $(shell find . -mindepth 1 -maxdepth 1 -name '$(SPEC_FILE_PATTERN)')
ifneq ($(words $(SPEC)),1)
$(error Found $(words $(SPEC)) $(SPEC_FILE_PATTERN) files, need exactly 1: $(SPEC))
endif
SPEC_FILENAME := $(notdir $(SPEC))
SPEC_MODIFIER := $(SPEC_FILENAME:packages%.yml=%)
# LOCKDIR contains the lockfile and layer files.
LOCKDIR  := packages$(SPEC_MODIFIER).lock
LOCKFILE := $(LOCKDIR)/pkgs.yml

export PACKAGE_SPEC_ID LAYER_SPEC_ID PRODUCT_REVISION PRODUCT_VERSION

# PACKAGESPEC_TARGETS are convenience aliases for targets defined in $(LOCKDIR)/Makefile
PACKAGESPEC_TARGETS := \
	build package-contents copy-package-contents build-all \
	aliases meta package package-meta \
	build-ci watch-ci \
	stage-config stage \
	list-staged-builds \
	publish-config publish

.PHONY: $(PACKAGESPEC_TARGETS)

$(PACKAGESPEC_TARGETS):
	@PRODUCT_REPO_ROOT="$(shell git rev-parse --show-toplevel)" $(MAKE) -C $(LOCKDIR) $@

# packages regenerates $(LOCKDIR) from $(SPEC) using packagespec. This is only for
# internal HashiCorp use, as it has dependencies not available externally.
.PHONY: packages
packages:
	@command -v packagespec > /dev/null 2>&1 || { \
		echo "Please install packagespec."; \
		echo "Note: packagespec is only available to HashiCorp employees at present."; \
		exit 1; \
	}
	@packagespec lock -specfile $(SPEC) -lockdir $(LOCKDIR)
	@$(MAKE) $(PACKAGESPEC_CIRCLECI_CONFIG)

CIRCLECI_PRIMARY_TPL := .packagespec/templates/circleci-primary.yml.tpl

$(PACKAGESPEC_CIRCLECI_CONFIG): $(LOCKFILE) $(CIRCLECI_PRIMARY_TPL)
	@\
		echo "==> Updating $(PACKAGESPEC_CIRCLECI_CONFIG)..."; \
		mkdir -p "$(dir $@)"; \
		cat $< | gomplate -f $(CIRCLECI_PRIMARY_TPL) -d 'lock-file=stdin://?type=application/yaml' > $@

# This target is needed by packagespec, do not remove.
packagespec-circleci-config: $(PACKAGESPEC_CIRCLECI_CONFIG)