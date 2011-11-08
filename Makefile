ifdef IGNOREDIRTY
CHECKTREE	:=
TGZ_SUFFIX	:= -dirty
else
CHECKTREE	:= tree_is_clean
TGZ_SUFFIX  :=
endif
REVISION		:= $(shell git rev-parse HEAD | cut -c-8)
TARGETS		:= autobuilder-$(REVISION)$(TGZ_SUFFIX).tgz 
TARGETS		+= jobrunner-$(REVISION)$(TGZ_SUFFIX).tgz
COMMONLIBS	:= libini.sh
COMMONLIBS  += libjob.sh
COMMONLIBS  += liblog.sh
COMMONLIBS  += libpmrpc.sh
COMMONLIBS  += libqueue.sh
COMMONLIBS  += libevent.sh

QUIET			:= @

.PHONY: release tree_is_clean clean
release: $(CHECKTREE) $(TARGETS)

tree_is_clean:
	$(QUIET) git diff-index --quiet HEAD --

clean:
	rm -f autobuilder-*.tgz jobrunner-*.tgz

autobuilder-%.tgz: autobuilder $(COMMONLIBS)
	$(QUIET) mkdir -p .staging/opt/autobuilder/bin
	$(QUIET) cp $^ .staging/opt/autobuilder/bin
	$(QUIET) tar -czf $@ -C .staging opt
	$(QUIET) rm -rf .staging

jobrunner-%.tgz: jobrunner $(COMMONLIBS)
	$(QUIET) mkdir -p .staging/opt/jobrunner/bin
	$(QUIET) cp $^ .staging/opt/jobrunner/bin
	$(QUIET) tar -czf $@ -C .staging opt
	$(QUIET) rm -rf .staging
