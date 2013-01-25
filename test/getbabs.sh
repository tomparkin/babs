#!/bin/bash
#
# Download and build babs package
#

log() { echo "$@"; }
err() { log "ERROR: $@" 1>&2; false; }
die() { err "$@" ; exit 1; }

if ! test -d babs
then
    git clone https://github.com/tomparkin/babs.git || die "Failed to download babs from github"
else
    ( cd babs && git pull ) || die "Failed to update babs from github"
fi
( cd babs && make package ) || die "Failed to build babs package"
