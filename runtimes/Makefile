
include ../inc/meta.mk
## hardcoded working container
WORKING_CONTAINER = tbx-build-tools-working-container
include ../inc/define.mk

PKGS_LIST := golang nodejs uv
OTP := erlang erlang-rebar3 elixir gleam
LUA := luajit luarocks

README.md: runtimes
	echo '##[ $@ ]##'
	cat preamble.md > $@
	$(file >> $@,The following programming language runtimes and associated languages are included in this toolbox: )
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","-------", $@)
	NAME=$$(cat info/erlang.md | grep -oP '^Name\s+:\s+\K.+')
	VER=$$(jq -r '.name' latest/erlang.json | cut -d' ' -f2)
	SUM=$$(cat info/erlang.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	NAME=rebar3
	VER=$$(jq -r '.tag_name' latest/erlang-rebar3.json | cut -d'v' -f2)
	SUM=$$(cat info/erlang-rebar3.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	# elixir
	NAME=$$(cat info/elixir.md | grep -oP '^Name\s+:\s+\K.+')
	VER=$$(jq -r '.tag_name' latest/elixir.json | cut -d'v' -f2)
	SUM=$$(cat info/elixir.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	# gleam
	LINE=$$($(RUN) gleam --version)
	NAME=$$(echo $$LINE | cut -d' ' -f1)
	VER=$$(echo $$LINE | cut -d' ' -f2)
	SUM="Gleam programming language"
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	for pkg in $(PKGS_LIST)
	do
	$(call dnf_to_table_row,$${pkg},$@)
	done
	echo '✅ README.md created'

xxx:
	# luarocks
	LINE=$$($(RUN) luarocks | grep -oP '^Lua.+')
	NAME=$$(cat info/luarocks.md | grep -oP '^Name\s+:\s+\K.+')
	VER=$$($(RUN) luarocks --version | head -1 | cut -d' ' -f2)
	SUM=$$(cat info/luarocks.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	echo '✅ README.md created'


init:
	echo '##[ $@ ]##'
	echo $(WORKING_CONTAINER)
	# pull the base image and create a working container
	buildah from ghcr.io/grantmacken/tbx-build-tools:latest &>/dev/null
	buildah config \
	--label summary='a toolbox with programming language runtimes' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 \
	--env ELIXIR_ERL_OPTIONS="+fnu" $(WORKING_CONTAINER)
	mkdir -p info
	# verify that the container is working and has the expected tools
	$(RUN) which ledger
	echo '✅ Buildah Working Container initialized and verified'

runtimes: init lists
	# verify that the container is working and has the expected tools
	$(RUN) which ledger
	$(RUN) which gleam
	printf '✅ %s toolbox built from: %s\n'  $@ $(WORKING_CONTAINER)
	buildah commit $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx-runtimes
	buildah push ghcr.io/grantmacken/tbx-runtimes:latest
	echo '✅ ghcr.io/grantmacken/tbx-runtimes:latest built and pushed'printf '✅ Coding toolbox built from: %s\n' $(WORKING_CONTAINER)

lists: pkgs_list otp_list # lua_list

pkgs_list: init
	echo '##[ $@ ]##'
	## check for updates and install packages, suppressing output
	$(RUN) dnf update -y &>/dev/null
	$(INSTALL) $(PKGS_LIST)  &>/dev/null

otp_list: erlang elixir erlang-rebar3 gleam

erlang: info/erlang.md

latest/erlang.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	# select tags that start with OTP- and sort by version, then take the first one
	curl -fsSL 'https://api.github.com/repos/erlang/otp/tags?per_page=100' | jq -r '[.[] | select(.name | startswith("OTP-"))][0]' > $@

info/erlang.md: latest/erlang.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	mkdir -p files/otp
	TAG=$$(jq -r '.name' $<)
	VER=$$(echo $${TAG} | cut -d'-' -f2)
	SRC="https://github.com/erlang/otp/releases/download/$${TAG}/otp_src_$${VER}.tar.gz"
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
	SRC=https://github.com/elixir-lang/elixir/archive/$${TAGNAME}.tar.gz
	mkdir -p files/elixir && $(WGET) $${SRC} -O- | $(TAR) files/elixir &>/dev/null
	$(RUN) mkdir -p /tmp/elixir
	$(ADD) files/elixir /tmp/elixir &>/dev/null
	$(RUN) sh -c 'cd /tmp/elixir && make && make install' &>/dev/null
	$(RUN) rm -fR /tmp/elixir
	# success|failure check
	$(RUN) elixir --version
	$(RUN) mix --version
	$(INFO) elixir > $@

##[[ rebar3 ]]##
erlang-rebar3: info/erlang-rebar3.md

latest/erlang-rebar3.json:
	# echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/erlang/rebar3/releases/latest -O $@

info/erlang-rebar3.md: latest/erlang-rebar3.json
	echo '##[ $(basename $(notdir $@)) ]##'
	SRC=$(shell $(call bdu,rebar3,$<))
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

info/gleam.md: files/gleam/gleam
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(ADD) files/gleam/gleam /usr/local/bin/gleam &>/dev/null
	$(RUN) chmod +x /usr/local/bin/gleam
	$(RUN) gleam --version &>/dev/null
	VER=$$($(RUN) gleam --version | awk '{print $$2}')
	$(call to_info,gleam,$${VER},Gleam programming language)

golang: info/golang.md
info/golang.md:
	echo '##[ $@ ]##'
	$(RUN) dnf copr enable -y @go-sig/golang-rawhide &>/dev/null
	$(INSTALL) golang &>/dev/null
	# verify installation
	$(RUN) go version &> /dev/null
	$(INFO) --installed golang > $@

lua_list: luajit luarocks

luajit: info/luajit.md
info/luajit.md:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(INSTALL) luajit-devel luajit &>/dev/null
	# success|failure check
	$(RUN) luajit -v &>/dev/null
	$(INFO) --installed luajit > $@

##[[ LUAROCKS ]]##
luarocks: info/luarocks.md
latest/luarocks.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/luarocks/luarocks/tags -o- | jq '.[0]' > $@

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
	$(RUN) rm -fR tmp/luarocks
	# success|failure check
	$(RUN) luarocks --version &>/dev/null
	$(INFO) luarocks > $@

# rust:
# 	echo '##[ $@ ]##'
# 	curl https://sh.rustup.rs -sSf | sh -s -- -y
# 	export PATH="$HOME/.cargo/bin:$PATH"
# 	$(RUN) dnf copr enable @rust-sig/rust-nightly
# 	$(INSTALL) rust
# 	$(RUN) mkdir -p /usr/local/cargo
# 	$(RUN) cargo install cargo-binstall --root /usr/local/cargo
# 	$(RUN) ls /usr/local/cargo/bin/
# 	$(RUN) ln -sf /usr/local/cargo/bin/cargo-binstall /usr/local/bin/cargo-binstall
# 	$(RUN) cargo-binstall --help
	# $(RUN) cargo-binstall --no-confirm --no-symlinks --root /usr/local/cargo lux-cli
	# $(RUN) ls /usr/local/cargo/bin/
	# $(RUN) ln -sf /usr/local/cargo/bin/* /usr/local/bin/
	# $(RUN) lx --help

pull:
	podman pull ghcr.io/grantmacken/tbx-runtimes:latest

