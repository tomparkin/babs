#!/bin/bash
#
# Autobuilder queue/list access functions
#
# Requires libutil.sh, libqueue.sh and liblist.sh

#
# A NOTE ON FUNCTION ARGUMENTS.
#
# The other lib* functions take data input as arguments and pass
# out data as echoed strings.  This keeps functions nicely general
# and decoupled from application logic, but it means that a function
# may return a single result (unless it munges multiple outputs into
# a single return string, which is scarcely better than multiple
# function calls!).
#
# In the case of these specialised autobuilder wrappers we break
# this convention of loose coupling in favour of main app convenience.
# Rather than echoing single strings on return, these functions
# set variables to pass out multiple results.  You should make use
# of Bash's "local variables" feature to constrain the scope of these
# variables, e.g.
#
# GLOBAL_VAR_ANIMAL=monkey
# GLOBAL_VAR_FOODSTUFF=banana
#
# my_function() {
#   local GLOBAL_VAR_ANIMAL="dog"
#   GLOBAL_VAR_FOODSTUFF="bone"
# }
#
# After calling my_function(), the global value of $GLOBAL_VAR_ANIMAL
# will be "monkey", while the global value of $GLOBAL_VAR_FOODSTUFF
# will have changed to "bone"
#

# Build queue.  The build queue stores information about
# a particular build for processing by a job runner.

# $1 -- build queue file
# $2 -- build id
# $3 -- build revision
autobuilder_enqueue_build() {
   # We'll treat the queue as a list to get the argument checking for free
   list_add_entry "$1" 2 "$2" "$3" > /dev/null
}

# $1 build queue file
# On successful return, sets build_id and build_rev
autobuilder_dequeue_build() {
   local entry=
   local bid=
   local brev=

   queue_lock "$1"
   entry="$(queue_pop_eldest "$1")"
   queue_unlock "$1"
   util_string_is_blank "$entry" && return 1

   # FIXME: don't use the private list interface :-|
   bid="$(_get_param_from_line "$entry" 1)"
   brev="$(_get_param_from_line "$entry" 2)"
   util_string_is_blank "$bid" && return 1
   util_string_is_blank "$brev" && return 1

   build_id="$bid"
   build_rev="$brev"
   return 0
}

# Report queue.  The report queue stores information about the
# results of a particular build after processing by a job runner.

# $1 -- report queue
# $2 -- build title
# $3 -- build revision
# $4 -- runner ip
# $5 -- build result
# $6 -- report path
autobuilder_enqueue_report() {
   # We'll treat the queue as a list to get the argument checking for free
   list_add_entry "$1" 5 "$2" "$3" "$4" "$5" "$6" > /dev/null
}

# $1 -- report queue file
# On successful return, sets:
#     build_title
#     build_rev
#     build_runner_ip
#     build_result
#     build_report_path
autobuilder_dequeue_report() {
   local entry=
   local btit=
   local brev=
   local brip=
   local bres=
   local brep=

   queue_lock "$1"
   entry="$(queue_pop_eldest "$1")"
   queue_unlock "$1"
   util_string_is_blank "$entry" && return 1

   # FIXME: don't use the private list interface :^/
   btit="$(_get_param_from_line "$entry" 1)" || return 1
   brev="$(_get_param_from_line "$entry" 2)" || return 1
   brip="$(_get_param_from_line "$entry" 3)" || return 1
   bres="$(_get_param_from_line "$entry" 4)" || return 1
   brep="$(_get_param_from_line "$entry" 5)" || return 1

   build_title="$btit"
   build_rev="$brev"
   build_runner_ip="$brip"
   build_result="$bres"
   build_report_path="$brep"
   return 0
}
