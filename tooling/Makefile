include ../inc/meta.mk
WORKING_CONTAINER := fedora-toolbox-working-container
include ../inc/define.mk
TOOLS := make stow bat fd-find fzf host-spawn jq ripgrep wl-clipboard zoxide ledger w3m
# atuin
BUILD := gcc gcc-c++ pcre2 autoconf pkgconf
DEVEL := libicu gettext-devel glibc-devel libevent-devel ncurses-devel openssl-devel perl-devel readline-devel zlib-devel
DNF_LIST := gh  $(TOOLS)
MD_LIST = google-cloud-cli

README.md: build-tools
	echo '##[ $@ ]##'
	cat preamble.md > $@
	$(file >> $@,The following applications are included in this toolbox: )
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","-------", $@)
	for pkg in $(DNF_LIST)
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
	echo '✅ README.md created'

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
	--env lang=C.UTF-8 $(WORKING_CONTAINER)
	echo '✅ Base image pulled and working container created'

build-tools: init lists gh google-cloud-cli
	# verify that the container is working and has the expected tools
	$(RUN) which ledger &>/dev/null
	printf '✅ %s toolbox built from: %s\n'  $@ $(WORKING_CONTAINER)
	buildah commit $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx-$@:latest
	buildah push ghcr.io/grantmacken/tbx-$@:latest
	printf '✅ Image pushed to ghcr.io/grantmacken/tbx-%s:latest\n' $@

lists:
	$(INSTALL) $(DEVEL) &>/dev/null
	$(INSTALL) $(BUILD) &>/dev/null
	$(INSTALL) $(TOOLS) &>/dev/null

gh:
	$(RUN) dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo &> /dev/null
	$(INSTALL) gh --repo gh-cli &>  /dev/null

# NOTE: install from toolbox container. 
google-cloud-cli: info/google-cloud-cli.md
info/google-cloud-cli.md: files/google-cloud-cli.tar.gz
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
