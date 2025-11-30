include ../inc/meta.mk
WORKING_CONTAINER ?= fedora-toolbox-working-container
TBX_NAME := tbx-build-tools
TBX_SUMMARY := A Fedora Toolbox image with CLI tools and build tools
TBX_IMAGE := ghcr.io/grantmacken/$(TBX_NAME)
include ../inc/define.mk

TOOLS := make bat eza fd-find fzf host-spawn jq ripgrep wl-clipboard zoxide stow
BUILD := gcc gcc-c++ pcre2 autoconf pkgconf
DEVEL := libicu gettext-devel glibc-devel libevent-devel ncurses-devel openssl-devel perl-devel readline-devel zlib-devel
PKGS_LIST := gh # $(TOOLS)

README.md: build-tools
	echo '##[ $@ ]##'
	$(file >> $@,the following applications are included in this toolbox: )
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","-------", $@)
	for pkg in $(PKGS_LIST)
	do
	echo "Processing package: $${pkg}"
	$(call dnf_to_table_row,$${pkg},$@)
	done
	cat $@
	echo '✅ README.md created'
	# buildah commit $(WORKING_CONTAINER) $(TBX_IMAGE)
	# buildah push $(TBX_IMAGE):latest
	# echo '✅ Image pushed to $(TBX_IMAGE):latest'

latest/fedora-toolbox.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	skopeo inspect docker://registry.fedoraproject.org/fedora-toolbox:latest | jq '.' > $@

init: latest/fedora-toolbox.json
	FROM_REGISTRY=$$(cat $< | jq -r '.Name')
	FROM_VERSION=$$(cat $< | jq -r '.Labels.version')
	FROM_NAME=$$(cat $< | jq -r '.Labels.name')
	buildah from "$${FROM_REGISTRY}:$${FROM_VERSION}"
	buildah config \
	--label summary='a toolbox with cli tools, neovim' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 $(WORKING_CONTAINER)
	echo '✅ Base image pulled and working container created'


build-tools: init
	$(RUN) dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo &> /dev/null
	$(INSTALL) gh --repo gh-cli &>  /dev/null
	# $(INSTALL) $(TOOLS) &>/dev/null
	# $(INSTALL) $(DEVEL) &>/dev/null
	# $(INSTALL) $(BUILD) &>/dev/null
	echo '✅ Build tools and CLI tools installed'



# README.md: info/build-tools.md
# 	echo '##[ $@ ]##'
# 	mkdir -p $(dir $@)
# 	touch $@
# 	printf "\n$(HEADING1) %s toolbox \n" "$(TBX_NAME)" | tee -a $@
# 	printf "%s \n\n" "$(TBX_SUMMARY) " | tee -a $@
# 	printf "Built From: %s" "$(FROM_NAME)" | tee -a $@
# 	printf "Version:    %s" "$(FROM_VERSION)" | tee -a $@
# 	printf "Registry:   %s" "$(FROM_REGISTRY)" | tee -a $@
# 	# description
# 	cat << EOF | tee -a $@
# 	This toolbox contains a selection of CLI tools and build tools to help with
# 	development and building software from source. 
# 	It is the foundation for other toolboxes I use for development.
# 	It is the first toolbox I create when setting up a new system.
# 	EOF
# 	printf "# %s\n\n" "The toolbox contains ... " | tee -a $@
# 	printf "\n$(HEADING2) %s\n\n" "Selected CLI Tools" | tee -a $@
# 	$(call tr,"Name","Version","Summary",$@)
# 	$(call tr,"----","-------","----------------------------",$@)
# 	$(RUN) sh -c  'dnf info -q --installed $(TOOLS) | \
# 	grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
# 	paste  - - -  | sort -u ' | \
# 	awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | \
# 	tee -a $@
# 	printf "\n$(HEADING2) %s\n\n" "Selected Build Tooling for Make Installs" | tee -a $@
# 	$(call tr,"Name","Version","Summary",$@)
# 	$(call tr,"----","-------","----------------------------",$@)
# 	$(RUN) sh -c  'dnf info -q --installed $(BUILD) | \
# 	grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
# 	paste  - - -  | sort -u ' | \
# 	awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | \
# 	tee -a $@
# 	printf "\n$(HEADING2) %s\n\n" "Selected Development files for BUILD" | tee -a $@
# 	$(call tr,"Name","Version","Summary",$@)
# 	$(call tr,"----","-------","----------------------------",$@)
# 	$(RUN) sh -c  'dnf info -q --installed $(DEVEL) | \
# 	grep -oP "(Name.+:\s\K.+)|(Ver.+:\s\K.+)|(Sum.+:\s\K.+)" | \
# 	paste  - - -  | sort -u ' | \
# 	awk -F'\t' '{printf "| %-14s | %-8s | %-83s |\n", $$1, $$2, $$3}' | \
# 	tee -a $@
