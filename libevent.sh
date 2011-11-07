#!/bin/bash
#
# libevent.sh
#
# Bash library of event generation/consumption functions
#
# Requires libqueue.sh -- it's just some wrappers, really...
#

# $1 -- event file
# $2 -- event id
event_write() {
   test "x$1" = "x" && return 1
   test "x$2" = "x" && return 1
   queue_lock "$1"
   queue_add "$1" "$2"
   queue_unlock "$1"
}

# $1 -- event file
event_blocking_read() {
   test "x$1" = "x" && return 1
   while true
   do
      event_nonblocking_read "$1" && break
   done
}

# $1 -- event file
event_nonblocking_read() {
   test "x$1" = "x" && return 1
   local ev=
   if queue_trylock "$1"
   then
      # fifo
      ev=$(queue_pop_eldest "$1")
      queue_unlock "$1"
   fi
   test "x${ev}" != "x" && echo "$ev"
}
