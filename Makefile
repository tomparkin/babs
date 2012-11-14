ifdef IGNOREDIRTY
CHECKTREE	:=
TGZ_SUFFIX	:= -dirty
else
CHECKTREE	:= tree_is_clean
TGZ_SUFFIX  :=
endif
REVISION		:= $(shell git rev-parse HEAD | cut -c-8)
TARGETS		:= babs-server-$(REVISION)$(TGZ_SUFFIX).tgz 
TARGETS		+= jobrunner-$(REVISION)$(TGZ_SUFFIX).tgz
COMMONLIBS	:= src/libini.sh
COMMONLIBS	+= src/libjob.sh
COMMONLIBS	+= src/liblog.sh
COMMONLIBS	+= src/libpmrpc.sh
COMMONLIBS	+= src/libqueue.sh
COMMONLIBS	+= src/libevent.sh
COMMONLIBS	+= src/libutil.sh
COMMONLIBS	+= src/liblist.sh
COMMONLIBS	+= src/libautobuilder.sh

QUIET			:= @

.PHONY: release tree_is_clean clean
release: $(CHECKTREE) $(TARGETS)

tree_is_clean:
	$(QUIET) git diff-index --quiet HEAD --

clean:
	rm -f babs-server-*.tgz jobrunner-*.tgz

babs-server-%.tgz: src/babs conf/babs.ini $(COMMONLIBS)
	$(QUIET) mkdir -p .staging/usr/local/bin .staging/etc/babs
	$(QUIET) cp src/babs $(COMMONLIBS) .staging/usr/local/bin
	$(QUIET) cp conf/babs.ini .staging/etc/babs
	$(QUIET) tar -czf $@ -C .staging usr etc
	$(QUIET) rm -rf .staging

jobrunner-%.tgz: src/jobrunner $(COMMONLIBS)
	$(QUIET) mkdir -p .staging/usr/local/bin
	$(QUIET) cp src/jobrunner $(COMMONLIBS) .staging/usr/local/bin
	$(QUIET) tar -czf $@ -C .staging usr
	$(QUIET) rm -rf .staging
