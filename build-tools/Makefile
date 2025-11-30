SHELL=/usr/bin/bash
.SHELLFLAGS := -euo pipefail -c
# -e Exit immediately if a pipeline fails
# -u Error if there are unset variables and parameters
# -o option-name Set the option corresponding to option-name
.ONESHELL:
.DELETE_ON_ERROR:
.SECONDARY:

MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent
unexport MAKEFLAGS

HEADING1 := \#
HEADING2 := $(HEADING1)$(HEADING1)
HEADING3 := $(HEADING2)$(HEADING1)

include .env
WORKING_CONTAINER ?= fedora-toolbox-working-container
FED_IMAGE := registry.fedoraproject.org/fedora-toolbox
TBX_NAME := tbx-build-tools
TBX_SUMMARY := A Fedora Toolbox image with CLI tools and build tools
TBX_IMAGE := ghcr.io/grantmacken/$(TBX_NAME)

RUN := buildah run $(WORKING_CONTAINER)
ADD := buildah add --chmod 755 $(WORKING_CONTAINER)
INSTALL := $(RUN) dnf install --allowerasing --skip-unavailable --skip-broken --no-allow-downgrade -y
WGET := wget -q --no-check-certificate --timeout=10 --tries=3
TOOLS :=  bat eza fd-find fzf host-spawn jq ripgrep wl-clipboard zoxide stow
BUILD := make gcc gcc-c++ pcre2 autoconf pkgconf
DEVEL := libicu gettext-devel glibc-devel libevent-devel ncurses-devel openssl-devel perl-devel readline-devel zlib-devel

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2

## Helper to write info files in a consistent format
define to_info
    printf "Name: %s\n"    "$(1)" > $@
	printf "Version: %s\n" "$(2)" >> $@
	printf "Summary: %s\n" "$(3)" >> $@
	printf "✅ %s installed \n" "$(1)"
endef

define dnf_installed_info
  	LINES=$$($(RUN) dnf info --installed $(1))
	# extract 'name', 'version', 'summary'
	VER=$$(echo "$${LINES}" | grep -oP '^Version\s+:\s+\K.+' || true)
	SUM=$$(echo "$${LINES}" | grep -oP '^Summary\s+:\s+\K.+' || true)
	# consistent write to file format
	$(call to_info,$(1),$${VER},$${SUM})
endef

default: README.md
	echo '##[ $@ ]##'
	buildah commit $(WORKING_CONTAINER) $(TBX_IMAGE)
	buildah push $(TBX_IMAGE):latest
	echo '✅ Image pushed to $(TBX_IMAGE):latest'

init: .env
	echo '##[ $@ ]##'

.env: latest/fedora-toolbox.json
	echo '##[ $@ ]##'
	FROM_REGISTRY=$$(cat $< | jq -r '.Name')
	FROM_VERSION=$$(cat $< | jq -r '.Labels.version')
	FROM_NAME=$$(cat $< | jq -r '.Labels.name')
	printf "FROM_NAME=%s\n" "$$FROM_NAME" | tee $@
	printf "FROM_REGISTRY=%s\n" "$$FROM_REGISTRY" | tee -a $@
	printf "FROM_VERSION=%s\n" "$$FROM_VERSION" | tee -a $@
	buildah pull "$$FROM_REGISTRY:$$FROM_VERSION" &> /dev/null
	echo -n "WORKING_CONTAINER=" | tee -a .env
	buildah from "$${FROM_REGISTRY}:$${FROM_VERSION}" | tee -a $@
	buildah config \
	--label summary='a toolbox with cli tools, neovim' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 $(WORKING_CONTAINER)
	echo '✅ Base image pulled and working container created'

latest/fedora-toolbox.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	skopeo inspect docker://${FED_IMAGE}:latest | jq '.' > $@

info/build-tools.md:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(RUN) dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo &> /dev/null
	$(INSTALL) gh --repo gh-cli &>  /dev/null
	$(INSTALL) $(TOOLS) &>/dev/null
	$(INSTALL) $(DEVEL) &>/dev/null
	$(INSTALL) $(BUILD) &>/dev/null
	echo '✅ Build tools installed' | tee $@

README.md: info/build-tools.md
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	touch $@
	printf "\n$(HEADING1) %s toolbox \n" "$(TBX_NAME)" | tee -a $@
	printf "%s \n\n" "$(TBX_SUMMARY) " | tee -a $@
	printf "Built From: %s" "$(FROM_NAME)" | tee -a $@
	printf "Version:    %s" "$(FROM_VERSION)" | tee -a $@
	printf "Registry:   %s" "$(FROM_REGISTRY)" | tee -a $@
	# description
	cat << EOF | tee -a $@
	This toolbox contains a selection of CLI tools and build tools to help with
	development and building software from source. 
	It is the foundation for other toolboxes I use for development.
	It is the first toolbox I create when setting up a new system.
	EOF
	printf "# %s\n\n" "The toolbox contains ... " | tee -a $@
	printf "\n$(HEADING2) %s\n\n" "Selected CLI Tools" | tee -a $@
	$(call tr,"Name","Version","Summary",$@)
	$(call tr,"----","-------","----------------------------",$@)
	$(RUN) sh -c  'dnf info -q --installed $(TOOLS) | \
	grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
	paste  - - -  | sort -u ' | \
	awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | \
	tee -a $@
	printf "\n$(HEADING2) %s\n\n" "Selected Build Tooling for Make Installs" | tee -a $@
	$(call tr,"Name","Version","Summary",$@)
	$(call tr,"----","-------","----------------------------",$@)
	$(RUN) sh -c  'dnf info -q --installed $(BUILD) | \
	grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
	paste  - - -  | sort -u ' | \
	awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | \
	tee -a $@
	printf "\n$(HEADING2) %s\n\n" "Selected Development files for BUILD" | tee -a $@
	$(call tr,"Name","Version","Summary",$@)
	$(call tr,"----","-------","----------------------------",$@)
	$(RUN) sh -c  'dnf info -q --installed $(DEVEL) | \
	grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
	paste  - - -  | sort -u ' | \
	awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | \
	tee -a $@
