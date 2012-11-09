#!/bin/bash
#
# Bash log library
#
log() { echo "$@"; }
logts() { log "[$(date)] $@"; }
dbg() { test -n "$DEBUG" && log "$@" 1>&2 || true; }
err() { log "ERROR: $@" 1>&2; false; }
die() { err "$@"; exit 1; }
