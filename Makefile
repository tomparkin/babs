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
COMMONLIBS  += libutil.sh
COMMONLIBS  += libreport.sh
COMMONLIBS	+= liblist.sh
COMMONLIBS	+= libautobuilder.sh

QUIET			:= @

.PHONY: release tree_is_clean clean
release: $(CHECKTREE) $(TARGETS)

tree_is_clean:
	$(QUIET) git diff-index --quiet HEAD --

clean:
	rm -f autobuilder-*.tgz jobrunner-*.tgz

autobuilder-%.tgz: autobuilder autobuilder.ini $(COMMONLIBS)
	$(QUIET) mkdir -p .staging/opt/autobuilder/bin .staging/etc
	$(QUIET) cp autobuilder $(COMMONLIBS) .staging/opt/autobuilder/bin
	$(QUIET) cp autobuilder.ini .staging/etc
	$(QUIET) tar -czf $@ -C .staging opt etc
	$(QUIET) rm -rf .staging

jobrunner-%.tgz: jobrunner jobrunner.ini $(COMMONLIBS)
	$(QUIET) mkdir -p .staging/opt/jobrunner/bin .staging/etc
	$(QUIET) cp jobrunner $(COMMONLIBS) .staging/opt/jobrunner/bin
	$(QUIET) cp jobrunner.ini .staging/etc
	$(QUIET) tar -czf $@ -C .staging opt etc
	$(QUIET) rm -rf .staging
