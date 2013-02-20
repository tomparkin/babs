#!/bin/bash
#
# Bash log library
#

# $1 -- level
# $2 -- message
_syslog() { logger -t babs -p $1 "$2"; }

# $1 -- level
# $2 -- message
_do_log() { test -n "$LOG_TO_STDOUT" && echo "$2" || _syslog $1 "$2"; }

say() { echo "$@"; }
log() { _do_log user.notice "$@"; }
dbg() { test -n "$DEBUG" && _do_log user.debug "$@" || true; }
err() { say "$@"; _do_log user.err "$@"; false; }
die() { err "$@"; exit 1; }
