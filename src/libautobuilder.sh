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

# Inflight list.  The inflight list stores information about the
# details of builds currently being processed by jobrunners.

# $1 -- inflight list file
# $2 -- build title
# $3 -- build revision
# $4 -- build runner ip
autobuilder_add_inflight_build() {
   local d=$(date)
   list_add_entry "$1" 4 "$d" "$2" "$3" "$4" > /dev/null
}

# $1 -- inflight list file
# $2 -- build revision
# $3 -- build title
# On successful return, sets:
#     build_rev
#     build_runner_ip
#     build_date
autobuilder_rem_inflight_build() {
   local entry=
   local bdat=
   local btit=
   local brev=
   local brip=

   entry=$(list_lookup_by_parameter "$1" 2 "$3" 3 "$2") || return 1
   bdat=$(list_parameter_parse "$1" "$entry" 1) || return 1
   brev=$(list_parameter_parse "$1" "$entry" 3) || return 1
   brip=$(list_parameter_parse "$1" "$entry" 4) || return 1
   list_remove_entry "$1" "$entry" || return 1

   build_date="$bdat"
   build_rev="$brev"
   build_runner_ip="$brip"
   return 0
}

# Build history list

# $1 -- build history file
# $2 -- build timestamp
# $3 -- build title
# $4 -- build revision
# $5 -- build runner ip
# $6 -- build path
# $7 -- build result
# $8 -- build runtime
autobuilder_add_build_to_history() {
   list_add_entry "$1" 7 "$2" "$3" "$4" "$5" "$6" "$7" "$8" > /dev/null
}

# $1 -- build history file
# $2 -- build title
# On successful return, sets:
#     build_time
#     build_date
#     build_title
#     build_rev
#     build_runner_ip
#     build_path
#     build_result
#     build_runtime
autobuild_lookup_build_in_history() {
   local entry=
   local btim=
   local bdat=
   local btit=
   local brev=
   local brip=
   local bpat=
   local bres=
   local brti=
}

# $1 -- job queue file
# On successful return, sets:a
#    job_ipaddr
#    job_id
#    job_script
#    report_ipaddr
#    report_script
autobuilder_dequeue_job() {
    local entry=""
    local jip=""
    local jid=""
    local jsc=""
    local rip=""
    local rsc=""

    queue_lock "$1"
    entry="$(queue_pop_eldest "$1")"
    queue_unlock "$1"
    util_string_is_blank "$entry" && return 1

    jip="$(job_unpickle_scriptpath "$entry" | cut -d":" -f1)" || return 1
    jid="$(job_unpickle_id "$entry")" || return 1
    jsc="$(job_unpickle_scriptpath "$entry" | cut -d":" -f2)" || return 1
    rip="$(job_unpickle_reportpath "$entry" | cut -d":" -f1)" || return 1
    rsc="$(job_unpickle_reportpath "$entry" | cut -d":" -f2)" || return 1

    job_ipaddr=$jip
    job_id=$jid
    job_script=$jsc
    report_ipaddr=$rip
    report_script=$rsc
    return 0
}
