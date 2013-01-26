#!/bin/bash
#
# Lib function testing
#

if test -z "$NETWORK_IF"; then
NETWORK_IF="eth0"
fi

test_fail() {
   local i=0
   echo "!!!! FAIL in function ${FUNCNAME[1]}(): $@" 1>&2
   exit 1
}

run_testsuite() {
   echo "### RUNNING $1"
   $1 | sed 's=^=   =g'
   echo "### $1 COMPLETED"
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
   . $(dirname $0)/libutil.sh || test_fail "libutil load"
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
   . $(dirname $0)/libutil.sh || test_fail "libutil load"
   . $(dirname $0)/libpmrpc.sh || test_fail "libpmrpc load"

   # Fuzz
   pmrpc_run_command && test_fail "pmrpc_run_command() with no args"
   pmrpc_run_command $(whoami) 1O.O.O.1 "cat /proc/cpuinfo" && test_fail "pmrpc_run_command() invalid IP"
   pmrpc_run_command $(whoami) 10.0.0.1 && test_fail "pmrpc_run_command() no command"
   pmrpc_pull_remote_file && test_fail "pmrpc_pull_remote_file() with null args"
   pmrpc_push_local_file && test_fail "pmrpc_push_local_file() with null args"
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

test_util_functions() {
   . $(dirname $0)/libutil.sh || test_fail "libutil load"

   # Fuzz
   util_check_abspath_string && test_fail "util_check_abspath_string() with NULL input"
   util_check_dotted_quad && test_fail "util_check_dotted_quad() with NULL input"
   util_find_interface_on_network && test_fail "util_find_interface_on_network() with NULL input"
   util_get_ip_for_interface && test_fail "util_get_ip_for_interface() with NULL input"

   # abspath check
   util_check_abspath_string "/etc/init.d/foobar" || test_fail "util_check_abspath_string() with good input"
   util_check_abspath_string "./etc/init.d/foobar" && test_fail "util_check_abspath_string() with relative path 1"
   util_check_abspath_string "etc/init.d/foobar" && test_fail "util_check_abspath_string() with relative path 2"
   util_check_abspath_string "/etc/my silly path/foobar" && test_fail "util_check_abspath_string() with spaces"

   # dotted quad check
   util_check_dotted_quad "10.0.0.1" || test_fail "util_check_dotted_quad() with good input"
   util_check_dotted_quad "10.O.0.1" && test_fail "util_check_dotted_quad() non-numeric"
   util_check_dotted_quad "127.0.0" && test_fail "util_check_dotted_quad() missing quad"
   util_check_dotted_quad "127,0,0,1" && test_fail "util_check_dotted_quad() commas not dots"

   # string trim
   util_trim_string "  this is your life    " || test_fail "util_trim_string() with good input"
   test "$(util_trim_string "  this is your life    ")" = "this is your life" || test_fail "util_trim_string() with good input output check 1"
   test "$(util_trim_string "this is your life    ")" = "this is your life" || test_fail "util_trim_string() with good input output check 2"
   test "$(util_trim_string "  this is your life")" = "this is your life" || test_fail "util_trim_string() with good input output check 3"

   # get ip
   util_get_ip_for_interface $NETWORK_IF || test_fail "util_get_ip_for_interface() with good input"
   util_get_ip_for_interface foobar && test_fail "util_get_ip_for_interface() with invalid interface"

   # find interface
   local if_ip="$(util_get_ip_for_interface $NETWORK_IF)"
   util_find_interface_on_network $if_ip || test_fail "util_find_interface_on_network() with good input"
   util_find_interface_on_network 123.456.789.101 && test_fail "util_find_interface_on_network() with bad input"

   # empty string
   util_string_is_blank "" || test_fail "util_string_is_blank() with blank string 1"
   util_string_is_blank "   " || test_fail "util_string_is_blank() with blank string 2"
   util_string_is_blank || test_fail "util_string_is_blank() with blank string 3"
   util_string_is_blank "a" && test_fail "util_string_is_blank() with non-blank string 1"
   util_string_is_blank "a   " && test_fail "util_string_is_blank() with non-blank string 2"
   util_string_is_blank "   a" && test_fail "util_string_is_blank() with non-blank string 3"
   util_string_is_blank "   a   " && test_fail "util_string_is_blank() with non-blank string 4"
}

test_list_functions() {
   . $(dirname $0)/libutil.sh || test_fail "libutil load"
   . $(dirname $0)/libqueue.sh || test_fail "libqueue load"
   . $(dirname $0)/liblist.sh || test_fail "liblist load"

   # Fuzz
   list_add_entry && test_fail "list_add_entry() with null args"
   list_remove_entry && test_fail "list_remove_entry() with null args"
   list_lookup_by_parameter && test_fail "list_lookup_by_parameter() with null args"
   list_parameter_parse && test_fail "list_parameter_parse() with null args"

   local l=/tmp/$(basename $0)-$$-list.txt
   list_add_entry "$l" 5 "one" "two" "three" "four" && test_fail "list_add_entry() with too few args"
   list_add_entry "$l" 5 "one" "two" "three" "four" "five" "six" && test_fail "list_add_entry() with too many args"
   list_add_entry "$l" 5 "one" "two" "three" "four" "" && test_fail "list_add_entry() with blank args"
   list_add_entry "$l" 5 "one" "two" "three" "four" "five" || test_fail "list_add_entry() with correct args 1"

   local id=$(list_add_entry "$l" 3 "one" "for" "all") || test_fail "list_add_entry() with correct args 2"
   list_remove_entry "$l" "abceded" && test_fail "list_remove_entry() with invalid id"
   list_remove_entry "$l" "$id" || test_fail "list_remove_entry() with valid id"
   grep "one.*for.*all" $l && test_fail "list_remove_entry() failed to remove text"

   id=$(list_add_entry "$l" 3 "siamang" "lemur" "orangutang") || test_fail "list_add_entry() with correct args 3"
   list_add_entry "$l" 5 "fff" "munge" "util" "huhuh" "zig" || test_fail "list_add_entry() with correct args 4"
   list_add_entry "$l" 2 "supercalifragilistic" "expialidocious" || test_fail "list_add_entry() with correct args 5"
   list_add_entry "$l" 1 "notmuchofanargumentfrankly" || test_fail "list_add_entry() with correct args 6"
   list_add_entry "$l" 3 "one" "AAA" "BBB" || test_fail "list_add_entry() with correct args 7"
   local id2=$(list_add_entry "$l" 3 "two" "AAA" "BBB") || test_fail "list_add_entry() with correct args 8"
   list_add_entry "$l" 3 "three" "AAA" "BBB" || test_fail "list_add_entry() with correct args 9"

   test "$id" = "$(list_lookup_by_parameter "$l" 1 "siamang")" || test_fail "list_lookup_by_parameter() correct args 1"
   test "$id" = "$(list_lookup_by_parameter "$l" 2 "lemur")" || test_fail "list_lookup_by_parameter() correct args 2"
   test "$id" = "$(list_lookup_by_parameter "$l" 3 "orangutang")" || test_fail "list_lookup_by_parameter() correct args 3"
   test "$id2" = "$(list_lookup_by_parameter "$l" 1 "two" 2 "AAA")" || test_fail "list_lookup_by_parameter() correct args 3"
   test "$id" = "$(list_lookup_by_parameter "$l" 2 "siamang")" && test_fail "list_lookup_by_parameter() incorrect args 1"
   test "$id" = "$(list_lookup_by_parameter "$l" 3 "lemur")" && test_fail "list_lookup_by_parameter() incorrect args 1"
   test "$id" = "$(list_lookup_by_parameter "$l" 1 "orangutang")" && test_fail "list_lookup_by_parameter() incorrect args 1"

   test "siamang" = "$(list_parameter_parse "$l" "$id" 1)" || test_fail "list_parameter_parse() correct args 1"
   test "lemur" = "$(list_parameter_parse "$l" "$id" 2)" || test_fail "list_parameter_parse() correct args 2"
   test "orangutang" = "$(list_parameter_parse "$l" "$id" 3)" || test_fail "list_parameter_parse() correct args 3"
   test "siamang" = "$(list_parameter_parse "$l" "$id" 3)" && test_fail "list_parameter_parse() incorrect args 1"
   test "lemur" = "$(list_parameter_parse "$l" "$id" 1)" && test_fail "list_parameter_parse() incorrect args 2"
   test "orangutang" = "$(list_parameter_parse "$l" "$id" 2)" && test_fail "list_parameter_parse() incorrect args 3"

   rm -f $l
}

test_autobuilder_functions() {
   . $(dirname $0)/libutil.sh || test_fail "libutil load"
   . $(dirname $0)/libqueue.sh || test_fail "libqueue load"
   . $(dirname $0)/liblist.sh || test_fail "liblist load"
   . $(dirname $0)/libautobuilder.sh || test_fail "libautobuilder load"

   local queue=/tmp/$(basename $0)-$$-queue.txt

   # Fuzz
   autobuilder_enqueue_build && test_fail "autobuilder_enqueue_build() fuzz"
   autobuilder_dequeue_build && test_fail "autobuilder_dequeue_build() fuzz"
   autobuilder_enqueue_report && test_fail "autobuilder_enqueue_report() fuzz"
   autobuilder_dequeue_report && test_fail "autobuilder_dequeue_report() fuzz"
   autobuilder_add_inflight_build && test_fail "autobuilder_add_inflight_build() fuzz"
   autobuilder_rem_inflight_build && test_fail "autobuilder_rem_inflight_build() fuzz"
   autobuilder_add_build_to_history && test_fail "autobuilder_add_build_to_history() fuzz"

   # enqueue build
   autobuilder_enqueue_build "$queue" "5" "1.55.6.2" || test_fail "autobuilder_enqueue_build() good arguments 1"
   local tmp=$(autobuilder_enqueue_build "$queue" "2" "516892") || test_fail "autobuilder_enqueue_build() good arguments 2"
   util_string_is_blank "$tmp" || test_fail "autobuilder_enqueue_build() isn't quiet"
   test $(queue_length "$queue") -eq 2 || test_fail "queue_length() check 1"
   autobuilder_enqueue_build "$queue" "5" && test_fail "autobuilder_enqueue_build() bad arguments 1"
   autobuilder_enqueue_build "$queue" "5" "   " && test_fail "autobuilder_enqueue_build() bad arguments 2"
   autobuilder_enqueue_build "$queue" "5 251225" && test_fail "autobuilder_enqueue_build() bad arguments 3"

   # dequeue build
   local build_id=
   local build_rev=
   autobuilder_dequeue_build "$queue" || test_fail "autobuilder_dequeue_build() with good arguments 1"
   test "$build_id" = "5" || test_fail "autobuilder_dequeue_build() check return 1"
   test "$build_rev" = "1.55.6.2" || test_fail "autobuilder_dequeue_build() check return 2"
   test $(queue_length "$queue") -eq 1 || test_fail "queue_length() check 2"
   autobuilder_dequeue_build "$queue" || test_fail "autobuilder_dequeue_build() with good arguments 2"
   test "$build_id" = "2" || test_fail "autobuilder_dequeue_build() check return 3"
   test "$build_rev" = "516892" || test_fail "autobuilder_dequeue_build() check return 4"
   test $(queue_length "$queue") -eq 0 || test_fail "queue_length() check 3"

   # enqueue report
   autobuilder_enqueue_report "$queue" "Foobar_trunk_testbuild" "412032" "10.0.0.2" "SUCCESS" "/opt/report/rep.txt" || test_fail "autobuilder_enqueue_report() with good arguments 1"
   autobuilder_enqueue_report "$queue" "Fizzbuzz_M5_releasebuild" "1.920.5.56" "10.0.0.9" "FAILURE" "/var/log/rep.txt" || test_fail "autobuilder_enqueue_report() with good arguments 2"
   test $(queue_length "$queue") -eq 2 || test_fail "queue_length() check 4"
   autobuilder_enqueue_report "$queue" "Fizzbuzz_M5_releasebuild" "" "10.0.0.9" "" "/var/log/rep.txt" && test_fail "autobuilder_enqueue_report() with bad arguments 1"
   autobuilder_enqueue_report "$queue" && test_fail "autobuilder_enqueue_report() with bad arguments 2"
   autobuilder_enqueue_report "$queue" "    " "1.920.5.56" "10.0.0.9" "FAILURE" "  " && test_fail "autobuilder_enqueue_report() with bad arguments 3"

   # dequeue report
   local build_title=
   local build_rev=
   local build_runner_ip=
   local build_result=
   local build_report_path=

   autobuilder_dequeue_report "$queue" || test_fail "autobuilder_dequeue_report() with good arguments 1"
   test "$build_title" = "Foobar_trunk_testbuild" || test_fail "autobuilder_dequeue_report() check return 1"
   test "$build_rev" = "412032" || test_fail "autobuilder_dequeue_report() check return 2"
   test "$build_runner_ip" = "10.0.0.2" || test_fail "autobuilder_dequeue_report() check return 3"
   test "$build_result" = "SUCCESS" || test_fail "autobuilder_dequeue_report() check return 4"
   test "$build_report_path" = "/opt/report/rep.txt" || test_fail "autobuilder_dequeue_report() check return 5"
   test $(queue_length "$queue") -eq 1 || test_fail "queue_length() check 5"

   autobuilder_dequeue_report "$queue" || test_fail "autobuilder_dequeue_report() with good arguments 2"
   test "$build_title" = "Fizzbuzz_M5_releasebuild" || test_fail "autobuilder_dequeue_report() check return 6"
   test "$build_rev" = "1.920.5.56" || test_fail "autobuilder_dequeue_report() check return 7"
   test "$build_runner_ip" = "10.0.0.9" || test_fail "autobuilder_dequeue_report() check return 8"
   test "$build_result" = "FAILURE" || test_fail "autobuilder_dequeue_report() check return 9"
   test "$build_report_path" = "/var/log/rep.txt" || test_fail "autobuilder_dequeue_report() check return 10"
   test $(queue_length "$queue") -eq 0 || test_fail "queue_length() check 6"

   # add inflight build
   autobuilder_add_inflight_build "$queue" "Fizzbuzz_M5_testbuild" "123456" "10.0.0.92" || test_fail "autobuilder_add_inflight_build() with good arguments 1"
   test $(queue_length "$queue") -eq 1 || test_fail "queue_length() check 7"
   autobuilder_add_inflight_build "$queue" "Foobar_trunk_releasebuild" "456789" "10.0.1.42" || test_fail "autobuilder_add_inflight_build() with good arguments 2"
   test $(queue_length "$queue") -eq 2 || test_fail "queue_length() check 8"
   autobuilder_add_inflight_build "$queue" && test_fail "autobuilder_add_inflight_build() with bad arguments 1"
   autobuilder_add_inflight_build "$queue" "Foobar" "   " "10.0.0.92" && test_fail "autobuilder_add_inflight_build() with bad arguments 2"
   autobuilder_add_inflight_build "$queue" "  FF" "29292929"  "   " && test_fail "autobuilder_add_inflight_build() with bad arguments 3"

   # remove inflight build
   autobuilder_rem_inflight_build "$queue" 9999 && test_fail "autobuilder_rem_inflight_build() with bad arguments 1"
   test $(queue_length "$queue") -eq 2 || test_fail "queue_length() check 9"

   autobuilder_rem_inflight_build "$queue" 123456 "Fizzbuzz_M5_testbuild" || test_fail "autobuilder_rem_inflight_build() with good arguments 1"
   test "$build_rev" = "123456" || test_fail "autobuilder_rem_inflight_build() check return 2"
   test "$build_runner_ip" = "10.0.0.92" || test_fail "autobuilder_rem_inflight_build() check return 3"
   test $(queue_length "$queue") -eq 1 || test_fail "queue_length() check 10"

   autobuilder_rem_inflight_build "$queue" 456789 "Foobar_trunk_releasebuild" || test_fail "autobuilder_rem_inflight_build() with good arguments 2"
   test "$build_rev" = "456789" || test_fail "autobuilder_rem_inflight_build() check return 5"
   test "$build_runner_ip" = "10.0.1.42" || test_fail "autobuilder_rem_inflight_build() check return 6"
   test $(queue_length "$queue") -eq 0 || test_fail "queue_length() check 10"

   # history
   autobuilder_add_build_to_history "$queue" "$(date)" "Foobar_2001" "123456" "10.0.1.42" "/export/home/autobuild/foo" "SUCCESS" "123" || test_fail "autobuilder_add_build_to_history() with good arguments 1"

   rm -f "$queue"
}

# Initial sanity check
if ! ifconfig $NETWORK_IF
then
   echo "Whoops, no $NETWORK_IF on this box.  Please set NETWORK_IF at the top of the script."
   exit 1
fi

test_log_functions
test_util_functions
test_job_functions
test_queue_functions
test_pmrpc_functions
test_ini_functions
test_event_functions
test_list_functions
test_autobuilder_functions

echo "Success :-)"
