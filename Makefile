include inc/meta.mk
WORKING_CONTAINER := fedora-toolbox-working-container
include inc/define.mk

TOOLS := bat fd-find fzf gh host-spawn jq ledger ripgrep stow wl-clipboard zoxide ShellCheck 
BUILD := gcc gcc-c++ pcre2 make autoconf pkgconf
DEVEL := libicu gettext-devel glibc-devel libevent-devel ncurses-devel openssl-devel perl-devel readline-devel zlib-devel
RUNTIMES := golang nodejs uv
DB := sqlite

# packages installed via dnf - these are listed in the README.md table
DNF_LIST := $(TOOLS) gh golang nodejs uv ShellCheck

.PHONY: init install neovim # runtimes_list otp_list coding_list

default: init
	# printf '✅ %s toolbox built from: %s\n' $@ $(WORKING_CONTAINER)
	# buildah commit $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx:latest
	# buildah push ghcr.io/grantmacken/tbx-$@:latest
	# printf '✅ Image pushed to ghcr.io/grantmacken/tbx-%s:latest\n' $@


TBX-README.md: # init tools_list # runtimes_list otp_list coding_list
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
	# mkdir -p info
	# $(ADD) files/ $(DIR_BIN)/ &>/dev/null

install:
	echo '##[ $@ ]##'
	$(RUN) dnf update -y &>/dev/null
	$(INSTALL) $(DEVEL) &>/dev/null
	$(INSTALL) $(BUILD) &>/dev/null
	$(INSTALL) $(TOOLS) &>/dev/null
	$(INSTALL) $(RUNTIMES) $(DB) &>/dev/null

####################################################

neovim: info/neovim.md

info/neovim.md:
	mkdir -p $(dir $@)
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

otp: erlang elixir erlang-rebar3 gleam

erlang: info/erlang.md

latest/erlang.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	# select tags that start with OTP- and sort by version, then take the first one
	#otp_src_29.1.2.tar.gz OTP-29.1.2" 
	$(WGET) https://api.github.com/repos/erlang/otp/releases/latest -O $@
	# curl -fsSL 'https://api.github.com/repos/erlang/otp/tags?per_page=100' | jq -r '[.[] | select(.name | startswith("OTP-"))][0]' > $@

info/erlang.md: latest/erlang.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	mkdir -p files/otp
	TAG_NAME=$$(jq -r '.tag_name' $<)
	VER=$$(echo $${TAG_NAME} | cut -d'-' -f2)
	# NAME="otp_src_$${VER}.tar.gz"
	# SRC=$(shell $(call bduName,$${NAME},$<))
	SRC="https://github.com/erlang/otp/releases/download/$${TAG_NAME}/otp_src_$${VER}.tar.gz"
	echo "Erlang/OTP Version: $${VER}"
	echo "Source URL: $${SRC}"
	$(WGET) $${SRC} -O- | $(TAR) files/otp &>/dev/null
	$(ADD) files/otp /tmp/otp &>/dev/null
	$(RUN) sh -c 'cd /tmp/otp && ./configure \
		--prefix=/usr/local \
		--enable-threads \
		--enable-shared-zlib \
		--enable-ssl=dynamic-ssl-lib \
		--enable-jit \
		--enable-kernel-poll \
		--without-debugger \
		--without-observer \
		--without-wx \
		--without-et \
		--without-megaco \
		--without-cosEvent \
		--without-odbc' &>/dev/null
	$(RUN) sh -c 'cd /tmp/otp && make && make install' &>/dev/null
	# success|failure check
	$(RUN) erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'  -noshell &>/dev/null
	$(RUN) rm -fR /tmp/otp
	$(INFO) erlang > $@
	# extract name, version, summary

##[[ ELIXIR ]]##
elixir: info/elixir.md
latest/elixir.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/elixir-lang/elixir/releases/latest -O $@

info/elixir.md: latest/elixir.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	TAGNAME=$$(jq -r '.tag_name' $<)
	TARBALL_URL=$$(jq -r '.tarball_url' $<)
	# SRC=https://github.com/elixir-lang/elixir/archive/$${TAGNAME}.tar.gz
	mkdir -p files/elixir && $(WGET) $${TARBALL_URL} -O- | $(TAR) files/elixir &>/dev/null
	$(RUN) mkdir -p /tmp/elixir
	$(ADD) files/elixir /tmp/elixir &>/dev/null
	$(RUN) sh -c 'cd /tmp/elixir && make && make install' &>/dev/null
	$(RUN) rm -fR /tmp/elixir
	# success|failure check
	$(RUN) elixir --version
	$(RUN) mix --version
	$(INFO) elixir > $@

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

