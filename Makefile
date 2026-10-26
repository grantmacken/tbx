include inc/meta.mk

WORKING_CONTAINER := fedora-toolbox-working-container
include inc/define.mk

TOOLS := make stow bat fd-find fzf host-spawn jq ripgrep wl-clipboard zoxide ledger sqlite # w3m
# atuin
BUILD := gcc gcc-c++ pcre2 autoconf pkgconf
DEVEL := libicu gettext-devel glibc-devel libevent-devel ncurses-devel openssl-devel perl-devel readline-devel zlib-devel
DNF_LIST := gh $(TOOLS)
MD_LIST = google-cloud-cli
PKGS_LIST := golang nodejs uv
OTP := erlang erlang-rebar3 elixir gleam

default: build-tools runtimes tooling-README.md
	cat tooling-README.md
	# printf '✅ %s toolbox built from: %s\n' $@ $(WORKING_CONTAINER)
	# buildah commit $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx:latest
	# buildah push ghcr.io/grantmacken/tbx-$@:latest
	# printf '✅ Image pushed to ghcr.io/grantmacken/tbx-%s:latest\n' $@
	#

tooling-README.md: build-tools runtimes
	echo '##[ $@ ]##'
	cat tooling-preable.md > $@
	$(file >> $@,The following applications are included in this toolbox: )
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","-------", $@)
	for pkg in $(DNF_LIST)
	do
	$(call dnf_to_table_row,$${pkg},$@)
	done
	for pkg in $(PKGS_LIST)
	do
	$(call dnf_to_table_row,$${pkg},$@)
	done
	for app in $(MD_LIST)
	do
	NAME=$$(cat info/$${app}.md | grep -oP '^Name:\s\K.+' || true)
	VER=$$(cat info/$${app}.md | grep -oP '^Version:\s\K.+' || true)
	SUM=$$(cat info/$${app}.md | grep -oP '^Summary:\s\K.+' || true)
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	done
	NAME=$$(cat info/erlang.md | grep -oP '^Name\s+:\s+\K.+')
	VER=$$(jq -r '.name' latest/erlang.json | cut -d' ' -f2)
	SUM=$$(cat info/erlang.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	NAME=rebar3
	VER=$$(jq -r '.tag_name' latest/erlang-rebar3.json | cut -d'v' -f2)
	SUM=$$(cat info/erlang-rebar3.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	NAME=$$(cat info/elixir.md | grep -oP '^Name\s+:\s+\K.+')
	VER=$$(jq -r '.tag_name' latest/elixir.json | cut -d'v' -f2)
	SUM=$$(cat info/elixir.md | grep -oP '^Summary\s+:\s+\K.+')
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	LINE=$$($(RUN) gleam --version)
	NAME=$$(echo $$LINE | cut -d' ' -f1)
	VER=$$(echo $$LINE | cut -d' ' -f2)
	SUM="Gleam programming language"
	$(call tr,$${NAME},$${VER},$${SUM},$@)
	echo '✅ tooling-README.md created'

latest/fedora-toolbox.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	skopeo inspect docker://registry.fedoraproject.org/fedora-toolbox:latest | jq '.' > $@

init: latest/fedora-toolbox.json
	FROM_REGISTRY=$$(cat $< | jq -r '.Name')
	buildah from "$${FROM_REGISTRY}:latest"
	buildah config \
	--label summary='a bespoke toolbox' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' \
	--env lang=C.UTF-8 \
	--env ELIXIR_ERL_OPTIONS="+fnu" $(WORKING_CONTAINER)
	echo '✅ Base image pulled and working container created'

build-tools: init lists gh google-cloud-cli


lists:
	$(INSTALL) $(DEVEL) &>/dev/null
	$(INSTALL) $(BUILD) &>/dev/null
	$(INSTALL) $(TOOLS) &>/dev/null

gh:
	$(RUN) dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo &> /dev/null
	$(INSTALL) gh --repo gh-cli &> /dev/null

# NOTE: install from toolbox container.
google-cloud-cli: info/google-cloud-cli.md
info/google-cloud-cli.md: files/google-cloud-cli.tar.gz
	mkdir -p $(dir $@)
	mkdir -p files/google-cloud-cli
	$(TAR) files/google-cloud-cli -f $<
	rm -f $<
	$(ADD) files/google-cloud-cli /usr/local/share/google-cloud-cli
	$(RUN) ls -al /usr/local/share/google-cloud-cli
	NAME=google-cloud-cli
	VER=$$($(RUN) cat /usr/local/share/google-cloud-cli/VERSION)
	SUM='gcloud command line interface'
	echo "Name: $${NAME}, Version: $${VER}, Summary: $${SUM}"
	$(call to_info,$${NAME},$${VER},$${SUM})

files/google-cloud-cli.tar.gz:
	mkdir -p $(dir $@)
	SRC="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz"
	echo "Source URL: $${SRC}"
	# wget the file and save it to the specified location. use progress bar and retry on failure. suppress output except for errors.
	$(WGET) $${SRC} -O $@


runtimes: build-tools pkgs_list otp_list
	# These runtime tools are installed into the same working container.
	$(RUN) which ledger
	$(RUN) which gleam
	$(RUN) elixir --version

pkgs_list: init
	echo '##[ $@ ]##'
	$(RUN) dnf update -y &>/dev/null
	$(INSTALL) $(PKGS_LIST) &>/dev/null

otp_list: erlang elixir erlang-rebar3 gleam

erlang: info/erlang.md

latest/erlang.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/erlang/otp/releases/latest -O $@

info/erlang.md: latest/erlang.json
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	mkdir -p files/otp
	TAG_NAME=$$(jq -r '.tag_name' $<)
	VER=$$(echo $${TAG_NAME} | cut -d'-' -f2)
	NAME="otp_src_$${VER}.tar.gz"
	SRC=$(shell $(call bduName,$${NAME},$<))
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
	$(RUN) erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell &>/dev/null
	$(RUN) rm -fR /tmp/otp
	$(INFO) erlang > $@

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
	mkdir -p files/elixir && $(WGET) $${TARBALL_URL} -O- | $(TAR) files/elixir &>/dev/null
	$(RUN) mkdir -p /tmp/elixir
	$(ADD) files/elixir /tmp/elixir &>/dev/null
	$(RUN) sh -c 'cd /tmp/elixir && make && make install' &>/dev/null
	$(RUN) rm -fR /tmp/elixir
	$(RUN) elixir --version
	$(RUN) mix --version
	$(INFO) elixir > $@

erlang-rebar3: info/erlang-rebar3.md

latest/erlang-rebar3.json:
	echo '##[ $@ ]##'
	mkdir -p $(dir $@)
	$(WGET) https://api.github.com/repos/erlang/rebar3/releases/latest -O $@

info/erlang-rebar3.md: latest/erlang-rebar3.json
	echo '##[ $(basename $(notdir $@)) ]##'
	mkdir -p $(dir $@)
	SRC=$(shell $(call bduName,rebar3,$<))
	$(ADD) $${SRC} /usr/local/bin/rebar3 &>/dev/null
	$(RUN) rebar3 --version &>/dev/null
	$(INFO) erlang-rebar3 > $@

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
	mkdir -p $(dir $@)
	$(RUN) dnf copr enable -y @go-sig/golang-rawhide &>/dev/null
	$(INSTALL) golang &>/dev/null
	$(RUN) go version &>/dev/null
	$(INFO) --installed golang > $@
