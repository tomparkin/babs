#!/bin/bash
#
# libreport.sh
#
# Functions for assembling a build report
#
readonly REPORT_ERR_WORKROOT_EXISTS="WORKROOT already exists"
readonly REPORT_ERR_CANNOT_CREATE_WORKROOT="Failed to create WORKROOT directory"
readonly REPORT_ERR_CHECKOUT_FAILED="Checkout from SCM failed"
readonly REPORT_ERR_BUILD_FAILED="Product build failed"

# $1 -- modules file path
__modules_file_is_svn() {
   test -f "$1" || return 1
   ( cd $(dirname $1) && svn status $(basename $1) &> /dev/null )
}

# $1 -- modules file path
__modules_file_is_cvs() {
   test -f "$1" || return 1
   ( cd $(dirname $1) && cvs status $(basename $1) &> /dev/null )
}

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

# Parse errors from a build log
# $1 -- build log file
# $2 -- (optional) context line count
report_extract_build_errors() {
   test -f "$1" || return 1
   local ctx=5
   test "x${2}" != "x" && ctx="${2}"

   awk -v contextlinecount=$ctx '
      function logerror(estr) {
         printf("### Extracted build error no. %i:\n%s\n\n", ++error_count, estr);
      }

      /No rule to make/ || /cannot create directory/ || /changing ownership of/ {
         logerror($0);
      }

      # On a make error print the previous contextlinecount lines for context
      /\] Error / && ! /ignored/ {
         s = "";
         for (i=0; i<contextlinecount;i++) s = sprintf("%s\n%s", s, prev[i]);
         s = sprintf("%s\n%s", s, $0);
         logerror(s);
      }

      # Store previous contextlinecount lines for reference
      {
         for (i=contextlinecount;i>=0;i--) prev[i+1] = prev[i];
         prev[0] = $0;
      }' "$1"
}

# Obtain revision of current stable tag
# $1 -- modules file
# $2 -- stable tag
report_get_modules_file_stable_tag_revision() {
   test -f "$1" || return 1
   test "x${2}" = "x" && return 1

   if __modules_file_is_cvs "$1"
   then
      if ( cd $(dirname $1) && cvs log -N -r$2 $(basename $1) 2>&1 | grep -q "nothing known about" )
      then
         echo "Unknown tag $2"
         return 1
      else
         ( cd $(dirname $1) && cvs log -N -r$2 $(basename $1) 2>&1 | grep "This is revision" | cut -d' ' -f4 )
      fi
   elif __modules_file_is_svn "$1"
   then
      (
         cd $(dirname $1)
         local url=$(svnurl)
         url=${url%/*}/tags/$2
         if svn info ${url}/$(basename $1) &> /dev/null
         then
            svn info ${url}/$(basename $1) | grep "Last Changed Rev" | cut -d" " -f4
         else
            echo "Unknown tag $2"
            false
         fi
      )
   else
      echo "Unrecognised SCM, cannot extract stable tag revision"
      return 1
   fi
}

# Obtain changelog between two modules file revisions
# $1 -- modules file
# $2 -- from revision
# $3 -- to revision
report_get_modules_file_changelog() {
   test -f "$1" || return 1
   test "x${2}" = "x" && return 1
   test "x${3}" = "x" && return 1

   if __modules_file_is_cvs "$1"
   then
      ( cd $(dirname $1) && cvs log -N -r$2:$3 2>&1 | awk '/^revision/ { grab=1; print; next; } /^This is revision/ { print ""; grab=0; next; } grab && !/^$/ { print "   " $0; }' )
   elif __modules_file_is_svn "$1"
   then
      ( cd $(dirname $1) && svn log -r${3}:${2} $(basename $1) 2>&1 | awk '/^$/ {next} /^----/ {print ""; next;} /^r.*\|.*\|.*\|/ {print; next;} {print "   " $0; }' )
   else
      echo "Unrecognised SCM, cannot extract stable tag revision"
      return 1
   fi
}

# Obtain all the IP addresses held by a host
report_get_my_ip_addresses() { ifconfig | awk '/inet addr/ { split($2,a,/:/); print a[2]; }' | grep -v 127.0.0.1; }

# Generate a report
# $1 -- status string (one of REPORT_ERR_*)
report_generate() {
   test "x$1" = "x" && return 1

   local ipaddr=$(report_get_my_ip_addresses | tr "\n" "/")
   local finish_time=$(date)
   local runtime=$(report_seconds_to_time_string $(( $(date -d "$finish_time" +%s) - $(date -d "$AUTOBUILDER_START_TIME" +%s) )))
   local stable_rev=

# Print report header
cat << _EOF_
######################################################################
#
# Build summary
#
######################################################################

Build:                              $AUTOBUILDER_BUILD_TITLE
Revision:                           $AUTOBUILDER_REVISION
Build host:                         ${ipaddr%/}
Build directory:                    $AUTOBUILDER_WORKROOT
Build log:                          $AUTOBUILDER_BUILD_LOGFILE
Start time:                         $AUTOBUILDER_START_TIME
Finish time:                        $finish_time
Build runtime:                      $runtime
Status:                             $1

_EOF_

# If we determined the last stable tag, print the changeset since then
if test "x$AUTOBUILDER_STABLE_TAG" != "x"
then
   if stable_rev=$(report_get_modules_file_stable_tag_revision "$AUTOBUILDER_MODULES_FILE" "$AUTOBUILDER_STABLE_TAG")
   then
cat << __EOF__
######################################################################
#
# SCM changelog
#
######################################################################

Last stable rev:                    $stable_rev
Changeset since last stable rev:
$(report_get_modules_file_changelog "$AUTOBUILDER_MODULES_FILE" "$stable_rev" "$AUTOBUILDER_REVISION")

__EOF__
   fi
fi

if test "$1" = "$REPORT_ERR_BUILD_FAILED"
then
cat << _EOF_
######################################################################
#
# Extracted build errors
#
######################################################################

Build errors:
$(report_extract_build_errors "$AUTOBUILDER_BUILD_LOGFILE")
_EOF_
fi
}
