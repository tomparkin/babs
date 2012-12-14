EXEC_SRCDIR	:= src
EXEC_DESTDIR	:= /usr/local/bin
EXEC_SOURCE	+= $(EXEC_SRCDIR)/babs
EXEC_SOURCE	+= $(EXEC_SRCDIR)/jobrunner
EXEC_SOURCE	+= $(EXEC_SRCDIR)/libautobuilder.sh
EXEC_SOURCE	+= $(EXEC_SRCDIR)/libevent.sh
EXEC_SOURCE	+= $(EXEC_SRCDIR)/libini.sh
EXEC_SOURCE	+= $(EXEC_SRCDIR)/libjob.sh
EXEC_SOURCE	+= $(EXEC_SRCDIR)/liblist.sh
EXEC_SOURCE	+= $(EXEC_SRCDIR)/liblog.sh
EXEC_SOURCE	+= $(EXEC_SRCDIR)/libpmrpc.sh
EXEC_SOURCE	+= $(EXEC_SRCDIR)/libqueue.sh
EXEC_SOURCE	+= $(EXEC_SRCDIR)/libutil.sh
EXEC_TARGET	:= $(patsubst $(EXEC_SRCDIR)/%,$(EXEC_DESTDIR)/%,$(EXEC_SOURCE))

CONF_SRCDIR	:= conf
CONF_DESTDIR	:= /etc/babs
CONF_SOURCE	:= $(CONF_SRCDIR)/babs.ini
CONF_TARGET	:= $(patsubst $(CONF_SRCDIR)/%,$(CONF_DESTDIR)/%,$(CONF_SOURCE))

NETWORK_IF	:= $(shell ip addr | awk '/^[[:alnum:]].*,UP,/ && $$2 !~ /lo:/ { gsub(/:/, ""); print $$2; exit 0 }')

.PHONY: test clean install all default

default: all
install: all
all: $(EXEC_TARGET) $(CONF_TARGET)

clean:
	rm -f $(EXEC_TARGET) $(CONF_TARGET)
	-rmdir $(dir $(CONF_TARGET))

test:
	NETWORK_IF=$(NETWORK_IF) $(EXEC_SRCDIR)/testsuite.sh

$(EXEC_DESTDIR)/%: $(EXEC_SRCDIR)/%
	mkdir -p $(dir $@)
	cp $^ $@

$(CONF_DESTDIR)/%: $(CONF_SRCDIR)/%
	mkdir -p $(dir $@)
	cp $^ $@
