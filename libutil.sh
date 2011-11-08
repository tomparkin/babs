#!/bin/bash
#
# libutil.sh
#
# Bash library of utility functions
#

# Make sure supplied string looks like a good path
# $1 -- path string
util_check_abspath_string() {
   # Must be an absolute path
   test "${1:0:1}" = "/" || return 1

   # No spaces...
   if echo "$1" | grep -q [[:space:]]; then return 1; fi

   return 0
}

# Make sure supplied string is a dotted quad ip address
# $1 -- ip address
util_check_dotted_quad() { echo "$1" | grep -q "[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+"; }

# Trim leading and trailing whitespace from string
# $1 -- string
util_trim_string() { echo "$@" | sed 's=^ \+==g;s= \+$==g'; }

# Obtain IP address for given interface
# $1 -- interface name
util_get_ip_for_interface() {
   test "x$1" = "x" && return 1
   local ip=
   ip=$(ifconfig $1 | awk '/inet addr/ { split($2,a,/:/); print a[2]; }')
   test "x$ip" != "x" && echo "$ip"
}

# Select local machine ip on the same network as a remote ip
# $1 -- remote machine ip
util_find_interface_on_network() {
   # If a machine has multiple interfaces we need to guess
   # which interface to use.  This is a kludge but it works
   # OK assuming Pace corporate v.s. Cora VLAN addresses.
   # Really we should look at route to figure it out.

   util_check_dotted_quad "$1" || return 1

   local ip=

   for ip in $(ifconfig | awk '/inet addr/ { split($2,a,/:/); print a[2]; }')
   do
      # FIXME: use route...
      if test "${ip%%.*}" = ${1%%.*}
      then
         echo $ip
         return 0
      fi
   done
   return 1
}
