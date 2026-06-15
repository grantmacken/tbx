include inc/meta.mk

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
