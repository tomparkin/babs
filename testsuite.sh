#!/bin/bash
#
# Lib function testing
#

test_fail() {
   local i=0
   echo "!!!! FAIL in function ${FUNCNAME[1]}(): $@" 1>&2
   exit 1
}

# Logging
test_log_functions() {
   . $(dirname $0)/liblog.sh || test_fail "liblog load"
   log "Test log()" || test_fail "log()"
   dbg "Test dbg()" || test_fail "dbg()"
   err "Test err()" && test_fail "err()"
}

# Jobs
test_job_functions() {
   . $(dirname $0)/libjob.sh || test_fail "libjob load"

   local job_id="myjobid_1"
   local job_script="10.0.0.1:/opt/bin/superfoo"
   local job_report="10.0.0.1:/opt/bin/superfoo_report"
   local job_string="myjobid_1@10.0.0.1:/opt/bin/superfoo@10.0.0.1:/opt/bin/superfoo_report"

   # pickle
   job_pickle $job_id $job_script $job_report || test_fail "pickle() with good args"
   test "$job_string" = "$(job_pickle $job_id $job_script $job_report)" || test_fail "check pickle() returns"
   job_pickle $job_id "1O.21.3.l23:/opt/bin/superfoo" $job_report && test_fail "pickle() bad script ip arg"
   job_pickle $job_id "10.21.3.123:/opt/bin/my silly path" $job_report && test_fail "pickle() bad script path arg"
   job_pickle $job_id $job_script "1O.21.3.l23:/opt/bin/superfoo" && test_fail "pickle() bad report ip arg"
   job_pickle $job_id $job_script "10.21.3.123:/opt/bin/my silly path" && test_fail "pickle() bad report path arg"
   job_pickle $job_script $job_report && test_fail "pickle() missing id arg"
   job_pickle $job_id $job_script && test_fail "pickle() missing report arg"

   # unpickle
   job_unpickle_id "$job_string" || test_fail "unpickle() id"
   test "$job_id" = "$(job_unpickle_id "$job_string")" || test_fail "check unpickle() id return"
   job_unpickle_scriptpath "$job_string" || test_fail "unpickle() script"
   test "$job_script" = "$(job_unpickle_scriptpath "$job_string")" || test_fail "check unpickle() script return"
   job_unpickle_reportpath "$job_string" || test_fail "unpickle() report"
   test "$job_report" = "$(job_unpickle_reportpath "$job_string")" || test_fail "check unpickle() report return"
   job_unpickle_reportpath "$job_script" && test_fail "unpickle() with malformed input string"
}

# Queues
test_queue_functions() {
   . $(dirname $0)/libqueue.sh || test_fail "libqueue load"

   local qf=/tmp/$(basename $0)-$$-queue

   queue_flush $qf || test_fail "queue_flush() with new queue"

   # Fuzzing
   queue_lock && test_fail "queue_lock() with null arg"
   queue_trylock && test_fail "queue_trylock() with null arg"
   queue_unlock && test_fail "queue_unlock() with null arg"
   queue_add && test_fail "queue_add() with null arg"
   queue_length && test_fail "queue_length() with null arg"
   queue_pop_eldest && test_fail "queue_pop_eldest() with null arg"
   queue_pop_youngest && test_fail "queue_pop_youngest() with null arg"
   queue_flush && test_fail "queue_flush() with null arg"
   queue_dump && test_fail "queue_dump() with null arg"

   # Locking
   queue_lock $qf || test_fail "queue_lock()"
   queue_trylock $qf && test_fail "queue_trylock() on locked queue"
   queue_unlock $qf || test_fail "queue_unlock()"
   queue_trylock $qf || test_fail "queue_trylock() on unlocked queue"
   queue_unlock $qf || test_fail "queue_unlock()"

   # Empty queue checks
   test $(queue_length $qf) -eq 0 || test_fail "queue_length() for empty queue"
   test "x$(queue_pop_eldest $qf)" = "x" || test_fail "queue_pop_eldest() for empty queue"
   test "x$(queue_pop_youngest $qf)" = "x" || test_fail "queue_pop_youngest() for empty queue"
   queue_dump $qf | grep "empty" || test_fail "queue_dump() for empty queue"

   # Adding
   local i=0
   for i in 1 2 3 4 5 6 7 8 9 10
   do
      queue_add $qf "$i" || test_fail "queue_add() $i"
   done
   test $(queue_length $qf) -eq 10 || test_fail "queue_length() 10 incorrect"
   
   # Popping
   test $(queue_pop_youngest $qf) -eq 10 || test_fail "queue_pop_youngest() 10 incorrect"
   test $(queue_pop_eldest $qf) -eq 1 || test_fail "queue_pop_eldest() 1 incorrect"
   test $(queue_length $qf) -eq 8 || test_fail "queue_length() 8 incorrect"
   
   # Dump
   queue_dump $qf | grep "empty" && test_fail "queue_dump() for filled queue"

   # Flush
   queue_flush $qf || test_fail "queue_flush() for filled queue"
}

# pmrpc
test_pmrpc_functions() {
   . $(dirname $0)/libpmrpc.sh || test_fail "libpmrpc load"

   # Fuzz
   pmrpc_run_command && test_fail "pmrpc_run_command() with no args"
   pmrpc_run_command $(whoami) 1O.O.O.1 "cat /proc/cpuinfo" && test_fail "pmrpc_run_command() invalid IP"
   pmrpc_run_command $(whoami) 10.0.0.1 && test_fail "pmrpc_run_command() no command"

   pmrpc_run_command $(whoami) 127.0.0.1 "cat /proc/cpuinfo" || test_fail "pmrpc_run_command() localhost cpuinfo"
}

test_log_functions
test_job_functions
test_queue_functions
test_pmrpc_functions
echo "Success :-)"
