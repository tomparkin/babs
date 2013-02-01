#!/bin/bash
#
# Bash log library
#
log() { echo "$@"; logger -p user.notice -t babs "$@"; }
logts() { log "[$(date)] $@"; logger -p user.notice -t babs "$@"; }
dbg() { test -n "$DEBUG" && log "$@" 1>&2 && logger -p user.debug -t babs "$@" || true; }
err() { log "ERROR: $@" 1>&2; logger -p user.err -t babs "$@"; false; }
die() { err "$@"; exit 1; }
