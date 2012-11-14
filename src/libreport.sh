#!/bin/bash
#
# libreport.sh
#
# Functions for assembling a build report
#

# Convert a number of seconds into nice time string
# $1 -- number of seconds
report_seconds_to_time_string() {
   test "x$1" = "x" && return 1
   local h=0
   local m=0
   local s="$1"
   while test $s -ge 60
   do
      s=$((s-60))
      m=$((m+1))
      test $m -ge 60 && m=0 && h=$((h+1))
   done
   echo "${h}h${m}m${s}s"
}

# Obtain all the IP addresses held by a host
report_get_my_ip_addresses() { ifconfig | awk '/inet addr/ { split($2,a,/:/); print a[2]; }' | grep -v 127.0.0.1; }

# Generate a report
# $1 -- status string (one of REPORT_ERR_*)
REPORT_IS_GENERATED=0
report_generate() {
   test "x$1" = "x" && return 1

   test $REPORT_IS_GENERATED -eq 0 || return 0

   local ipaddr=$(report_get_my_ip_addresses | tr "\n" "/")
   local finish_time=$(date)
   local runtime=$(report_seconds_to_time_string $(( $(date -d "$finish_time" +%s) - $(date -d "$BABS_START_TIME" +%s) )))
   local stable_rev=

# Print report header
cat << _EOF_
######################################################################
#
# Build summary
#
######################################################################

Build:                              $BABS_BUILD_TITLE
Revision:                           $BABS_REVISION
Build host:                         ${ipaddr%/}
Build directory:                    $BABS_WORKROOT
Build log:                          $BABS_BUILD_LOGFILE
Start time:                         $BABS_START_TIME
Finish time:                        $finish_time
Build runtime:                      $runtime
Status:                             $1

_EOF_
    REPORT_IS_GENERATED=1
}
