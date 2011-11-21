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
   util_string_is_blank "$1" && return 1
   util_check_dotted_quad "$2" || return 1
   util_string_is_blank "$3" && return 1
   ssh ${1}@${2} "$3"
}

# $1 -- username
# $2 -- ip address
# $3 -- remote filename
# $4 -- local filename
pmrpc_pull_remote_file() {
   util_string_is_blank "$1" && return 1
   util_check_dotted_quad "$2" || return 1
   util_string_is_blank "$3" && return 1
   util_string_is_blank "$4" && return 1
   scp ${1}@${2}:${3} ${4}
}

# $1 -- username
# $2 -- ip address
# $3 -- local filename
# $4 -- remote filename
pmrpc_push_local_file() {
   util_string_is_blank "$1" && return 1
   util_check_dotted_quad "$2" || return 1
   util_string_is_blank "$3" && return 1
   util_string_is_blank "$4" && return 1
   scp ${3} ${1}@${2}:${4}
}
