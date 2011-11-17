#!/bin/bash
#
# liblist.sh
#
# Library of list management functions
#
# Requires libqueue.sh and libutil.sh
#

_list_delim="@"

_genid() { uuidgen; }

# $1 -- line
# $2 -- parameter position
_get_param_from_line() {
   local l="$1"
   local p="$2"
   local i=

   # Step along to the parameter of interest
   for ((i=0;i<$p;i++)); do
      test $(expr index "$l" "$_list_delim") -eq 0 && return 1
      l=${l#*$_list_delim}
   done

   # Drop any trailing parameters
   l=${l%%$_list_delim*}

   # Sanity check
   util_string_is_blank "$l" && return 1
   echo "$l"
}

# $1 -- file
# $2 -- parameter position
# $3 -- search term
_lookup_line_in_file() {
   local line=
   local p=
   local ret=1
   queue_lock "$1"
   while read line
   do
      util_string_is_blank "$line" && break
      p=$(_get_param_from_line "$line" "$2")
      test "$p" = "$3" && echo "$line" && ret=0
   done < "$1"
   queue_unlock "$1"
   return $ret
}

# $1 -- list file
# $2 -- number of parameters
# $...  parameters
list_add_entry() {
   util_string_is_blank "$1" && return 1
   util_string_is_blank "$2" && return 1
   util_string_is_blank "$3" && return 1

   local lf="$1"
   local np="$2"
   local id=""
   local e=
   local i=

   shift 2

   # Sanity check
   test $# -eq $np || return 2

   # Generate unique id
   id=$(_genid)

   # Assemble entry
   e="$id"
   for ((i=1;i<=$np;i++)); do
      e="$e@$1"
      shift
   done

   if queue_lock "$lf"
   then
      queue_add "$lf" "$e"
      queue_unlock "$lf"
      echo "$id"
   else
      return 1
   fi
}

# $1 -- list file
# $2 -- list entry id
list_remove_entry() {
   test -f "$1" || return 1
   util_string_is_blank "$2" && return 1

   if grep -q "$2" "$1"
   then
      queue_lock "$1" && grep -v "$2" "$1" > ${1}.new && mv ${1}.new ${1} && queue_unlock "$1"
   else
      # Entry not present
      return 2
   fi
}

# $1 -- list file
# $2 -- parameter position
# $3 -- search term
list_lookup_by_parameter() {
   test -f "$1" || return 1
   util_string_is_blank "$2" && return 1
   util_string_is_blank "$3" && return 1

   local line=
   local id=

   line=$(_lookup_line_in_file "$1" "$2" "$3")
   util_string_is_blank "$line" && return 1
   id=$(_get_param_from_line "$line" "0")
   util_string_is_blank "$id" && return 1
   echo "$id"
}

# $1 -- list file
# $2 -- list entry id
# $3 -- parameter position
list_parameter_parse() {
   test -f "$1" || return 1
   util_string_is_blank "$2" && return 1
   util_string_is_blank "$3" && return 1

   local line=$(_lookup_line_in_file "$1" 0 "$2")
   local p=$(_get_param_from_line "$line" "$3")
   util_string_is_blank "$p" && return 1
   echo "$p"
}
