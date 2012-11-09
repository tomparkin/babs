#!/bin/bash
#
# libjob.sh
#
# Bash library of job manipulation functions
#
# Requires liblog.sh and libutil.sh
#
_job_delimiter="@"

__check_path() {
   local ip=$(echo "$1" | cut -d: -f1)
   local path=$(echo "$1" | cut -d: -f2)

   # We expect ip:path
   util_check_dotted_quad "$ip" || return 1

   # Make sure the path looks OK
   util_check_abspath_string "$path" || return 1

   return 0
}

__check_pickle() {
   local tmp="$1"

   # String isn't blank
   test "x$tmp" = "x" && return 1

   # String contains first delimiter
   test $(expr index "$tmp" "$_job_delimiter") -gt 0 || return 1

   # String has content beyond first delimiter
   tmp=${tmp#*$_job_delimiter}
   test "x$tmp" = "x" && return 1

   # String contains second delimiter
   test $(expr index "$tmp" "$_job_delimiter") -gt 0 || return 1

   # String has content beyond second delimter
   tmp=${tmp#*$_job_delimiter}
   test "x$tmp" = "x" && return 1

   return 0
}


# Munge a job specification into a string for queuing
# $1 -- job id
# $2 -- job script ip:path
# $3 -- job report script ip:path
job_pickle() {
   
   # Some sanity checking
   __check_path "$2" || return 1
   __check_path "$3" || return 1
   
   # Looks ok...
   echo "${1}${_job_delimiter}${2}${_job_delimiter}${3}"
}

# Unmunge job id from a pickled string
# $1 -- job string
job_unpickle_id() {
   __check_pickle "$1" || return 1
   echo "${1}" | cut -d${_job_delimiter} -f1;
}

# Unmunge job script ip:path from a pickled string
# $1 -- job string
job_unpickle_scriptpath() {
   local path=
   __check_pickle "$1" || return 1
   path=$(echo "${1}" | cut -d${_job_delimiter} -f2)
   __check_path "$path" || return 1
   echo "$path"
}

# Unmunge job script ip:path from a pickled string
# $1 -- job string
job_unpickle_reportpath() {
   local path=
   __check_pickle "$1" || return 1
   path=$(echo "${1}" | cut -d${_job_delimiter} -f3)
   __check_path "$path" || return 1
   echo "$path"
}
