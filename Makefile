include inc/meta.mk

default:
	$(MAKE) -C tooling
	sleep 60
	$(MAKE) -C runtimes
	sleep 60
	$(MAKE) -C coding
	echo '✅ All toolbox images built and pushed to ghcr.io/grantmacken'
