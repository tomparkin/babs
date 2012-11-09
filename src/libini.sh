#!/bin/bash
#
# libini.sh
#
# Bash library for ini file reading
#

# $1 -- file
# $2 -- section
__get_section() {
   awk -v s="$2" '/^#/ { next; } /^\[/ { grab=0; } $1 ~ s { grab=1; } grab { print; }' "$1"
}

# $1 -- ini file path
ini_get_section_list() {
   test -f "$1" || return 1
   grep "^\[" "$1" | sed 's=\[==g;s=\]==g;s=#.*$==g' | tr '\n' ' '
}

# $1 -- ini file path
# $2 -- section name
ini_get_section() {
   test -f "$1" || return 1
   test "x${2}" = "x" && return 1
   __get_section "$1" "$2" | sed 's=#.*$==g'
}

# $1 -- ini file path
# $2 -- section name
ini_get_values_in_section() {
   test -f "$1" || return 1
   test "x${2}" = "x" && return 1
   ini_get_section "$1" "$2" | sed 's/^\[.*$//g;s/^.*=//g'
}

# $1 -- ini file path
# $2 -- section name
# $3 -- property name
ini_get_value() {
   test -f "$1" || return 1
   test "x${2}" = "x" && return 1
   test "x${3}" = "x" && return 1

   # Extract property from the section
   local p=$(__get_section $1 $2 | grep "${3}.*=")
   test "x${p}" = "x" && return 1

   # Ditch the property name, comments, and leading/trailing whitespace
   p=${p#*=}
   p=$(echo "$p" | sed 's=#.*$==g') # Can't use bash as "#" has special meaning...
   p=${p# *}
   p=${p% *}
   test "x${p}" = "x" && return 1

   echo "$p"
}
