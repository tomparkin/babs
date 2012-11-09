#!/bin/bash
#
# libevent.sh
#
# Bash library of event generation/consumption functions
#
# Requires libqueue.sh -- it's just some wrappers, really...
# Also requires inotifywait, which is in the fedora package
# inotify-tools.  This allows modification detection for the
# event queue, and hence blocking reads.
#

if ! which inotifywait &> /dev/null
then
   echo "ERROR: Cannot locate inotifywait, libevent.sh depends on it"
   exit 1
fi

# treat the queue as a fifo
__event_fifo_pop() {
   queue_pop_eldest "$1"
}

# wait for someone to write to the queue
__event_waitfor() {
   local t=
   # make sure the queue exists before trying to read
   touch "$1" && inotifywait -t0 -e modify "$1" > /dev/null 2>&1
}

# $1 -- event file
# $2 -- event id
event_write() {
   local ret=
   test "x$1" = "x" && return 1
   test "x$2" = "x" && return 1
   queue_lock "$1" && queue_add "$1" "$2"
   ret=$?
   queue_unlock "$1"
   return $ret
}

# $1 -- event file
event_blocking_read() {
   test "x$1" = "x" && return 1
   local ev=
   queue_lock "$1"
   if test "$(queue_length "$1")" -gt 0
   then
      # Happy days...
      ev=$(__event_fifo_pop "$1")
      queue_unlock "$1"
      echo "$ev"
   else
      # FIXME: there is potential for a race here...
      queue_unlock "$1"
      __event_waitfor "$1"
      queue_lock "$1"
      ev="$(__event_fifo_pop "$1")"
      queue_unlock "$1"
      test -n "$ev" && echo "$ev" # Should be an event available!
   fi
}

# $1 -- event file
event_nonblocking_read() {
   test "x$1" = "x" && return 1
   local ev=
   if queue_trylock "$1"
   then
      ev=$(__event_fifo_pop "$1")
      queue_unlock "$1"
   fi
   test "x${ev}" != "x" && echo "$ev"
}
