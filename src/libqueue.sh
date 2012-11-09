#!/bin/bash
#
# libqueue.sh
#
# Bash library of queue management functions
#
# Requires liblog.sh
#

# $1 -- queue file
queue_trylock() {
   test "x${1}" = "x" && return 1
   local lockfile=${1}.lock
   ( set -o noclobber; echo "$$" > $lockfile ) 2>/dev/null
}

# $1 -- queue file
queue_lock() {
   test "x${1}" = "x" && return 1
   while true
   do
      queue_trylock "$1" && break
      sleep 1
   done
}

# $1 -- queue file
queue_unlock() {
   test "x${1}" = "x" && return 1
   local lockfile=${1}.lock
   rm -f $lockfile
}

# $1 -- queue file
# $2 -- entry
queue_add() {
   test "x${1}" = "x" && return 1
   test "x${2}" = "x" && return 1
   echo "$2" >> $1;
   test -f "$1" || err "queue_add() no queue!!"
}

# $1 -- queue file
queue_length() {
   test "x${1}" = "x" && return 1
   if test -f $1
   then
      wc -l $1 | cut -d " " -f1
   else
      echo 0
   fi
}

# $1 -- queue file
queue_pop_eldest() {
   test "x${1}" = "x" && return 1
   if test $(queue_length $1) -gt 0
   then
      head -1 $1
      tail -$(($(queue_length $1)-1)) $1 > ${1}.new && mv ${1}.new $1
   else
      echo
   fi
}

# $1 -- queue file
queue_pop_youngest() {
   test "x${1}" = "x" && return 1
   if test $(queue_length $1) -gt 0
   then
      tail -1 $1
      head -$(( $(queue_length $1) - 1 )) $1 > ${1}.new && mv ${1}.new $1
   else
      echo
   fi
}

# $1 -- queue file
queue_flush() {
   test "x${1}" = "x" && return 1
   rm -f $1
}

# $1 -- queue file
queue_dump() {
   test "x${1}" = "x" && return 1
   if test $(queue_length $1) -gt 0
   then
      awk '{print NR ". " $0}' $1
   else
      log "Queue is empty"
   fi
}
