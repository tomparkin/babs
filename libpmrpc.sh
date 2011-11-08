#!/bin/bash
#
# Bash library for "poor man's RPC" (i.e. ssh wrappers...)
#
# Requires libutil.sh
#

# $1 -- username
# $2 -- ip address
# $3 -- command
pmrpc_run_command() {
   test "x$1" = "x" && return 1
   util_check_dotted_quad "$2" || return 1
   test "x$3" = "x" && return 1
   ssh ${1}@${2} "$3"
}
