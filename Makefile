include inc/meta.mk
WORKING_CONTAINER := fedora-toolbox-working-container
include ../inc/define.mk

default:
	pushd tooling
	$(MAKE)
	popd
	sleep 60
	pushd runtimes
	$(MAKE)
	popd
	sleep 60
	pushd coding
	$(MAKE)
	popd
