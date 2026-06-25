include ../inc/meta.mk
WORKING_CONTAINER := fedora-toolbox-working-container
include ../inc/define.mk
TOOLS := make stow bat fd-find fzf host-spawn jq ripgrep wl-clipboard zoxide ledger w3m
BUILD := gcc gcc-c++ pcre2 autoconf pkgconf
DEVEL := libicu gettext-devel glibc-devel libevent-devel ncurses-devel openssl-devel perl-devel readline-devel zlib-devel
PKGS_LIST := gh $(TOOLS)

README.md: build-tools
	echo '##[ $@ ]##'
	cat preamble.md > $@
	$(file >> $@,The following applications are included in this toolbox: )
	$(call tr,"Name","Version","Summary", $@)
	$(call tr,"----","-------","-------", $@)
	for pkg in $(PKGS_LIST)
	do
	$(call dnf_to_table_row,$${pkg},$@)
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

build-tools: init lists
	# verify that the container is working and has the expected tools
	$(RUN) which ledger &>/dev/null
	printf '✅ %s toolbox built from: %s\n'  $@ $(WORKING_CONTAINER)
	buildah commit $(WORKING_CONTAINER) ghcr.io/grantmacken/tbx-$@:latest
	buildah push ghcr.io/grantmacken/tbx-$@:latest
	printf '✅ Image pushed to ghcr.io/grantmacken/tbx-%s:latest\n' $@

lists:
	$(RUN) dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo &> /dev/null
	$(INSTALL) gh --repo gh-cli &>  /dev/null
	$(INSTALL) $(DEVEL) &>/dev/null
	$(INSTALL) $(BUILD) &>/dev/null
	$(INSTALL) $(TOOLS) &>/dev/null

