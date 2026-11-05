include inc/meta.mk
WORKING_CONTAINER := fedora-toolbox-working-container
include inc/define.mk

TOOLS := make stow bat fd-find fzf host-spawn jq ripgrep wl-clipboard zoxide ledger sqlite # w3m
BUILD := gcc gcc-c++ pcre2 autoconf pkgconf
DEVEL := libicu gettext-devel glibc-devel libevent-devel ncurses-devel openssl-devel perl-devel readline-devel zlib-devel
# packages installed via dnf - these are listed in the README.md table
DNF_LIST := $(TOOLS) gh golang nodejs uv ShellCheck shfmt

# MD_LIST = google-cloud-cli
# OTP := erlang erlang-rebar3 elixir gleam

default: TBX-README.md
	# printf '✅ %s toolbox built from: %s\n' $@ $(WORKING_CONTAINER)
	# buildah commit $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx:latest
	# buildah push ghcr.io/grantmacken/tbx-$@:latest
	# printf '✅ Image pushed to ghcr.io/grantmacken/tbx-%s:latest\n' $@

.PHONY: tools_list # runtimes_list otp_list coding_list

TBX-README.md: init tools_list # runtimes_list otp_list coding_list
	echo '##[ $@ ]##'
	$(file >> $@,The following applications are included in this toolbox: )
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","-------", $@)
	for pkg in $(DNF_LIST)
	do
	$(call dnf_to_table_row,$${pkg},$@)
	done
	# for pkg in $(PKGS_LIST)
	# do
	# NAME=$$(cat info/$${pkg}.md | grep -oP '^Name:\s\K.+' || true)
	# VER=$$(cat info/$${pkg}.md | grep -oP '^Version:\s\K.+' || true)
	# SUM=$$(cat info/$${pkg}.md | grep -oP '^Summary:\s\K.+' || true)
	# $(call tr,$${NAME},$${VER},$${SUM},$@)
	done
	
latest/fedora-toolbox.json:
	mkdir -p $(dir $@)
	echo '##[ $@ ]##'
	skopeo inspect docker://registry.fedoraproject.org/fedora-toolbox:latest | jq '.' > $@

init: latest/fedora-toolbox.json
	FROM_REGISTRY=$$(cat $< | jq -r '.Name')
	buildah from "$${FROM_REGISTRY}:latest"
	buildah config \
	--label summary='a bespoke toolbox' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 \
	--env ELIXIR_ERL_OPTIONS="+fnu" $(WORKING_CONTAINER)
	# --env UV_TOOL_BIN_DIR=/usr/local/bin \
	# --env UV_TOOL_DIR=/var/lib/uv_tools 
	echo '✅ Base image pulled and working container created'
	mkdir -p info
	$(ADD) files/ $(DIR_BIN)/ &>/dev/null

tools_list:
	echo '##[ $@ ]##'
	$(RUN) dnf update -y
	$(INSTALL) $(DEVEL)
	$(INSTALL) $(BUILD)
	$(INSTALL) $(TOOLS)
	# $(RUN) dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo &> /dev/null
	# $(INSTALL) gh --repo gh-cli &> /dev/null

runtimes_list:
	echo '##[ $($@) ]##'
	$(INSTALL) golang nodejs uv &>/dev/null

coding_list: neovim
	echo '##[ $($@) ]##'
	$(INSTALL)  ShellCheck shfmt &>/dev/null

otp_list: erlang elixir erlang-rebar3 gleam

####################################################

neovim: info/neovim.md
info/neovim.md:
	echo '##[ $(basename $(notdir $@)) ]##'
	PKG=$(basename $(notdir $@))
	TARGET=files/$${PKG}/usr/local
	mkdir -p $${TARGET}
	SRC='https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz'
	$(WGET) $${SRC} -O- | $(TAR) $${TARGET} &> /dev/null
	$(ADD) files/$${PKG} &> /dev/null
	# success|failure check
	$(RUN) nvim --version &> /dev/null
	$(RUN) whereis nvim &> /dev/null
	$(RUN) which nvim &> /dev/null
	# get version from the binary
	VER=$$($(RUN) nvim -v | grep -oP 'NVIM v\K\d+\.\d+\.\d+' )
	$(call to_info,$${PKG},$${VER},Neovim text editor)

####################################################

erlang-rebar3: info/erlang-rebar3.md

latest/erlang-rebar3.json:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/erlang/rebar3/releases/latest -O $@

info/erlang-rebar3.md: latest/erlang-rebar3.json
	echo '##[ $(basename $(notdir $@)) ]##'
	SRC=$(shell $(call bduName,rebar3,$<))
	$(ADD) $${SRC} /usr/local/bin/rebar3 &>/dev/null
	# success|failure check
	$(RUN) rebar3 --version &>/dev/null
	$(INFO) erlang-rebar3 > $@

##[[ GLEAM ]]##
gleam: info/gleam.md

latest/gleam.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/gleam-lang/gleam/releases/latest -O- |
	jq -r '.assets[] | select(.name | endswith("x86_64-unknown-linux-musl.tar.gz"))' > $@

files/gleam/gleam: latest/gleam.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(RUN) rm -f /usr/local/bin/gleam
	SRC=$$(jq -r '.browser_download_url' $<)
	curl -L "$${SRC}" | tar xz -C $(dir $@) &>/dev/null
	test -f $@

####################################################

info/gleam.md: files/gleam/gleam
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(ADD) files/gleam/gleam /usr/local/bin/gleam &>/dev/null
	$(RUN) chmod +x /usr/local/bin/gleam
	$(RUN) gleam --version &>/dev/null
	VER=$$($(RUN) gleam --version | awk '{print $$2}')
	$(call to_info,gleam,$${VER},Gleam programming language)

