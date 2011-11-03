#!/bin/bash
#
# Bash library for "poor man's RPC" (i.e. ssh wrappers...)
#

__is_dotted_quad() { echo "$1" | grep -q "[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+"; }

# $1 -- username
# $2 -- ip address
# $3 -- command
pmrpc_run_command() {
   test "x$1" = "x" && return 1
   __is_dotted_quad "$2" || return 1
   test "x$3" = "x" && return 1
   ssh ${1}@${2} "$3"
}
