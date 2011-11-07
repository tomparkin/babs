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

# ini
test_ini_functions() {
   . $(dirname $0)/libini.sh || test_fail "libini load"

   # Fuzz
   ini_get_section_list && test_fail "ini_get_section_list() with null arg"
   ini_get_section && test_fail "ini_get_section() with null arg"
   ini_get_values_in_section && test_fail "ini_get_values_in_section() with null arg"
   ini_get_value && test_fail "ini_get_value() with null arg"

   # Generate test file
   local i=
   local if=/tmp/$(basename $0)-$$-config.ini

   rm -f $if && touch $if
   ini_get_section_list $if || test_fail "ini_get_section_list() with empty file"
   ini_get_section $if "foobar" || test_fail "ini_get_section() with empty file"

   cat << __EOF__ > $if
[global]
name = Theodore
shoesize = 10

[zebra] # I saw one at the zoo, it seemed to long for something lost
colour = Black and white
legcount = 4

[snake]
colour=Multicolour # different snakes could be different colours
legcount=0

[threelegdog]
colour =Brown
legcount =3 # it is a three leg dog

# two legs or four legs?
#[monkey]
#color=olive
#legcount=2
__EOF__
  
   # get_section_list
   ini_get_section_list $if || test_fail "ini_get_section_list() with populated file"
   ini_get_section_list $if | grep global || test_fail "ini_get_section_list() global section"
   ini_get_section_list $if | grep zebra || test_fail "ini_get_section_list() zebra section"
   ini_get_section_list $if | grep snake || test_fail "ini_get_section_list() snake section"
   ini_get_section_list $if | grep threelegdog || test_fail "ini_get_section_list() threelegdog section"
   ini_get_section_list $if | grep monkey && test_fail "ini_get_section_list() monkey section"
   ini_get_section_list $if | grep "zebra.*zoo" && test_fail "ini_get_section_list() zebra/zoo section"

   # get_section
   ini_get_section $if global || test_fail "ini_get_section() with populated file"
   ini_get_section $if snake | grep "colour.*Multi" || test_fail "ini_get_section() snake check content"

   # get_values_in_section
   ini_get_values_in_section $if threelegdog || test_fail "ini_get_values_in_section() with populated file"
   ini_get_values_in_section $if threelegdog | grep "Brown" || test_fail "ini_get_values_in_section() threelegdog check content"
   ini_get_values_in_section $if threelegdog | grep "=" && test_fail "ini_get_values_in_section() check ="
   ini_get_values_in_section $if threelegdog | grep "legcount" && test_fail "ini_get_values_in_section() check property"

   # get_value
   test "$(ini_get_value $if global name)" = "Theodore" || test_fail "ini_get_value() global name"
   test "$(ini_get_value $if snake colour)" = "Multicolour" || test_fail "ini_get_value() snake colour"
   test "$(ini_get_value $if snake legcount)" = "0" || test_fail "ini_get_value() snake legcount"
   test "$(ini_get_value $if threelegdog legcount)" = "3" || test_fail "ini_get_value() threelegdog legcount"
   ini_get_value $if monkey legcount && test_fail "ini_get_value() monkey legcount"

   rm -f $if
}

test_event_functions() {
   . $(dirname $0)/libevent.sh || test_fail "libevent load"

   # Fuzz
   event_write && test_fail "event_write() with NULL data"
   event_blocking_read && test_fail "event_blocking_read() with NULL data"
   event_nonblocking_read && test_fail "event_nonblocking_read() with NULL data"

   local eq="/tmp/$(basename $0)-$$-eventqueue"

   # Writing events
   event_write $eq "EVENT_ID1" || test_fail "event_write() with id1"
   event_write $eq "EVENT_ID2" || test_fail "event_write() with id2"

   # Reading events
   event_blocking_read $eq || test_fail "event_blocking_read() with event pending"
   event_nonblocking_read $eq || test_fail "event_nonblocking_read() event pending"
   event_nonblocking_read $eq && test_fail "event_nonblocking_read() with no events pending"

   ( sleep 1 && event_write $eq "EVENT_ID3" ) &
   event_blocking_read $eq || test_fail "event_blocking_read() with event arriving in 1s"

   rm -f $eq
}

test_log_functions
test_job_functions
test_queue_functions
test_pmrpc_functions
test_ini_functions
test_event_functions

echo "Success :-)"
