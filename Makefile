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


FROM_IMAGE := ghcr.io/grantmacken/tbx-build-tools
NAME := tbx-runtimes
WORKING_CONTAINER ?= $(NAME)-working-container
TBX_IMAGE :=  ghcr.io/grantmacken/$(NAME)

RUN := buildah run $(WORKING_CONTAINER)
ADD := buildah add --chmod 755 $(WORKING_CONTAINER)
INSTALL := $(RUN) dnf install --allowerasing --skip-unavailable --skip-broken --no-allow-downgrade -y

WGET := wget -q --no-check-certificate --timeout=10 --tries=3
TAR  := tar xz --strip-components=1 -C
TAR_NO_STRIP := tar xz -C

tr = printf "| %-14s | %-8s | %-83s |\n" "$(1)" "$(2)" "$(3)" | tee -a $(4)
bdu = jq -r ".assets[] | select(.browser_download_url | contains(\"$1\")) | .browser_download_url" $2
tarball = jq -r '.tarball_url' $1

OTP := otp rebar3 elixir
LUA := luajit luarocks

HEADING1 := \#
HEADING2 := $(HEADING1)$(HEADING1)

default: init nodejs # $(LUA) $(OTP)
	echo '##[ $@ ]##'
	buildah config \
	--label summary='a toolbox with cli tools, neovim' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 $(WORKING_CONTAINER)
	buildah commit $(WORKING_CONTAINER) $(TBX_IMAGE)
	buildah push $(TBX_IMAGE):latest

init:
	buildah pull $(FROM_IMAGE)  &> /dev/null
	buildah from $(FROM_IMAGE)

##[[ RUNTIMES ]]##
runtimes: info/runtimes.md
info/runtimes.md: nodejs $(LUA) $(OTP)
	mkdir -p $(dir $@)
	printf "\n$(HEADING2) %s\n\n" "Runtimes and associated languages" | tee $@
	# cat << EOF | tee -a $@
	# Included in this toolbox are the latest releases of the Erlang, Elixir and Gleam programming languages.
	# The Erlang programming language is a general-purpose, concurrent, functional programming language
	# and **runtime** system. It is used to build massively scalable soft real-time systems with high availability.
	# The BEAM is the virtual machine at the core of the Erlang Open Telecom Platform (OTP).
	# The included Elixir and Gleam programming languages also run on the BEAM.
	# BEAM tooling included is the latest versions of the Rebar3 and the Mix build tools.
	# The latest nodejs **runtime** is also installed, as Gleam can compile to javascript as well a Erlang.
	# EOF
	# $(call tr,"Name","Version","Summary",$@)
	# $(call tr,"----","-------","----------------------------",$@)
	# cat info/otp.md    | tee -a $@
	# cat info/rebar3.md | tee -a $@
	# cat info/elixir.md | tee -a $@
	# cat info/gleam.md  | tee -a $@
	# cat info/nodejs.md | tee -a $@

##[[ NODEJS ]]##
nodejs: info/nodejs.md
	echo '✅ latest nodejs added'

latest/nodejs.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) 'https://api.github.com/repos/nodejs/node/releases/latest' -O $@

info/nodejs.md: latest/nodejs.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	VER=$$(jq -r '.tag_name' $< )
	mkdir -p files/nodejs/usr/local
	$(WGET) https://nodejs.org/download/release/$${VER}/node-$${VER}-linux-x64.tar.gz -O- | 
	$(TAR) files/nodejs/usr/local
	$(ADD) files/nodejs &>/dev/null
	echo -n 'checking node version...'
	NODE_VER=$$($(RUN) node --version | tee)
	$(call tr,node,$${NODE_VER},Nodejs runtime, $@)
	echo -n 'checking npm version...'
	NPM_VER=$$($(RUN) npm --version | tee)
	$(call tr,npm,$${NPM_VER},Node Package Manager, $@)

luajit: info/luajit.md
	echo '✅ latest $@ installed'

info/luajit.md:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(INSTALL) luajit-devel luajit 
	echo -n 'checking luajit version...'
	$(RUN) luajit -v | tee $@
	# VERSION=$$($(RUN) luajit -v | grep -oP 'LuaJIT \K\d+\.\d+\.\d{1,3}')
	# $(call tr,luajit,$${VERSION},The LuaJIT compiler,$@)

luarocks: info/luarocks.md
	echo '✅ latest luarocks installed'

latest/luarocks.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/luarocks/luarocks/tags -O- | jq '.[0]' > $@

info/luarocks.md: latest/luarocks.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	mkdir -p files/luarocks
	SRC=$$(jq -r '.tarball_url' $<)
	$(RUN) mkdir -p 	/tmp/luarocks /etc/xdg/luarocks
	$(WGET) $${SRC} -O- | tar xz --strip-components=1 -C files/luarocks &>/dev/null
	$(ADD) files/luarocks /tmp/luarocks &>/dev/null
	$(RUN) sh -c 'cd /tmp/luarocks && ./configure \
		--lua-version=5.1 \
		--with-lua-interpreter=luajit \
		--sysconfdir=/etc/xdg \
		--force-config \
		--with-lua-include=/usr/include/luajit-2.1' &>/dev/null
	# $(RUN) sh -c 'cd /tmp && make bootstrap' &>/dev/null
	$(RUN) sh -c 'cd /tmp/luarocks && make && make install' &>/dev/null
	echo -n 'checking luarocks version...'
	$(RUN) luarocks --version
	# $(RUN) luarocks config --json | jq '.' &>/dev/null
	LINE=$$($(RUN) luarocks | grep -oP '^Lua.+')
	NAME=$$(echo $$LINE | grep -oP '^Lua\w+')
	VER=$$(echo $$LINE | grep -oP '^Lua\w+\s\K.+' | cut -d, -f1)
	SUM=$$(echo $$LINE | grep -oP '^Lua\w+\s\K.+' | cut -d, -f2)
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	$(RUN) rm -fR tmp/luarocks

cargo:
	echo '##[ $@ ]##'
	$(RUN) mkdir -p /usr/local/cargo
	$(RUN) cargo install cargo-binstall --root /usr/local/cargo
	$(RUN) ls /usr/local/cargo/bin/
	$(RUN) ln -sf /usr/local/cargo/bin/cargo-binstall /usr/local/bin/cargo-binstall
	$(RUN) cargo-binstall --help
	# $(RUN) cargo-binstall --no-confirm --no-symlinks --root /usr/local/cargo lux-cli
	# $(RUN) ls /usr/local/cargo/bin/
	# $(RUN) ln -sf /usr/local/cargo/bin/* /usr/local/bin/
	# $(RUN) lx --help

latest/otp.json: 
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/erlang/otp/releases/latest -O $@

otp: info/otp.md
info/otp.md: latest/otp.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(RUN) mkdir -p /tmp/otp
	TAGNAME=$$(jq -r '.tag_name' $<)
	$(eval ver := $(shell jq -r '.name' $< | cut -d' ' -f2))
	ASSET=$$(jq -r '.assets[] | select(.name=="otp_src_$(ver).tar.gz") ' $<)
	SRC=$$(echo $${ASSET} | jq -r '.browser_download_url')
	mkdir -p files/otp && $(WGET) $${SRC} -O- |
	$(TAR) files/otp &>/dev/null
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
	echo -n 'checking otp version...'
	$(RUN) erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'  -noshell
	$(call tr ,Erlang/OTP,$(ver),the Erlang Open Telecom Platform OTP,$@)
	$(RUN) rm -fR /tmp/otp

latest/elixir.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/elixir-lang/elixir/releases/latest -O $@

elixir: info/elixir.md
info/elixir.md: latest/elixir.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	TAGNAME=$$(jq -r '.tag_name' $<)
	SRC=https://github.com/elixir-lang/elixir/archive/$${TAGNAME}.tar.gz
	mkdir -p files/elixir && $(WGET) $${SRC} -O- |
	$(TAR) files/elixir &>/dev/null
	$(RUN) mkdir -p /tmp/elixir
	$(ADD) files/elixir /tmp/elixir &>/dev/null
	$(RUN) sh -c 'cd /tmp/elixir && make && make install' &>/dev/null
	echo -n 'checking elixir version...'
	# buildah run $(WORKING_CONTAINER) erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'  -noshell
	$(RUN) elixir --version
	LINE=$$(buildah run $(WORKING_CONTAINER) elixir --version | grep -oP '^Elixir.+')
	VER=$$(echo "$${LINE}" | grep -oP 'Elixir\s\K.+' | cut -d' ' -f1)
	$(call tr,Elixir,$${VER},Elixir programming language, $@)
	VER=$$(buildah run $(WORKING_CONTAINER) mix --version | grep -oP 'Mix \K.+' | cut -d' ' -f1)
	$(call tr,Mix,$${VER},Elixir build tool, $@)
	$(RUN) rm -fR /tmp/elixir

##[[ rebar3 ]]##
rebar3: info/rebar3.md

latest/rebar3.json:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/erlang/rebar3/releases/latest -O $@

info/rebar3.md: latest/rebar3.json
	# echo '##[ $@ ]##'
	VER=$$(jq -r '.tag_name' $<)
	SRC=$(shell $(call bdu,rebar3,$<))
	$(ADD) $${SRC} /usr/local/bin/rebar3 &>/dev/null
	$(call tr,Rebar3,$${VER},the erlang build tool,$@)

##[[ GLEAM ]]##
gleam: info/gleam.md

latest/gleam.json:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	 $(WGET) https://api.github.com/repos/gleam-lang/gleam/releases/latest -O- |
	jq -r '.assets[] | select(.name | endswith("x86_64-unknown-linux-musl.tar.gz"))' > $@

files/gleam.tar: latest/gleam.json
	mkdir -p $(dir $@)
	$(RUN) rm -f /usr/local/bin/gleam
	SRC=$$(jq -r '.browser_download_url' $<)
	$(WGET) $${SRC} -O- | gzip -d > $@

info/gleam.md: files/gleam.tar
	echo '##[ $@ ]##'
	$(ADD) $(WORKING_CONTAINER) $< /usr/local/bin/  &>/dev/null
	echo -n 'checking gleam version...'
	$(RUN) gleam --version
	VER=$$(buildah run $(WORKING_CONTAINER) gleam --version | cut -d' ' -f2)
	$(call tr,Gleam,$${VER},Gleam programming language,$@)

pull:
	echo '##[ $@ ]##'
	podman pull ghcr.io/grantmacken/tbx-runtimes:latest

