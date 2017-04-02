#!/usr/bin/env bash

# Testing some functionality of the Bash library, using "shunit2"
# Expects some environment set up by Travis Continuous Integration
# like a Linux kernel whose version be 3.5 or greater, the "shunit2"
# Shell Unit-Testing library under /tmp/, etc.

my_prg_to_trace='/tmp/simple'
my_function_to_trace='my_func'
my_param_to_trace='my_param'
my_param_value='0x4'

my_probe_name=$( printf "probe_%s:%s" $( basename "$my_prg_to_trace" ) \
                                      "$my_function_to_trace" )

oneTimeSetUp() {
  . ./dt.sh
}

testShowAvailableExternFunctions() {

  trace.available_extern_functions "$my_prg_to_trace" | \
      grep -qs "$my_function_to_trace"

  exit_code=$?

  assertEquals "Expected to find function $my_function_to_trace" "$exit_code" 0
}

testShowAvailableLocalVars() {

  trace.available_local_vars "$my_prg_to_trace" "$my_function_to_trace" | \
      grep -qs "int[[:space:]]*$my_param_to_trace$"

  exit_code=$?

  assertEquals "Expected to find local var $my_param_to_trace" "$exit_code" 0
}

testShowAvailableSrcLines() {

  trace.available_src_lines "$my_prg_to_trace" "$my_function_to_trace" | \
      fgrep -qs 'printf("%d\n", my_param);'

  exit_code=$?

  assertEquals "Expected to find a printf() instruction" "$exit_code" 0
}

testSetDynamicProbe() {

  # catching with Perf Events a parameter argument into the function
  # $my_function_to_trace:
  # The compiler optimizes the parameter passing so that the first function
  # argument is passed through a CPU register: in the case of Linux on the
  # x86-64 is the System V AMD64 ABI: see page 24 of:
  # https://software.intel.com/sites/default/files/article/402129/mpx-linux64-abi.pdf
  trace.set_dynamic_probes "$my_prg_to_trace" \
                           "$my_function_to_trace $my_param_to_trace=%di"

  trace.list_probes | grep -qs "$my_probe_name"

  exit_code=$?
  if [[ "$exit_code" == "0" ]]; then
    trace.del_dyn_probes "$my_probe_name"
  fi

  assertEquals "Expected to see a new probe '$my_probe_name'" "$exit_code" 0
}

testDelDynamicProbe() {

  # create the probe: see notes inside testSetDynamicProbe above
  trace.set_dynamic_probes "$my_prg_to_trace" \
                           "$my_function_to_trace $my_param_to_trace=%di"

  # del the probe
  trace.del_dyn_probes "$my_probe_name"

  # see if the probe still exists
  trace.list_probes | grep -qs "$my_probe_name"

  exit_code=$?

  assertEquals "Did not expect the probe '$my_probe_name'" "$exit_code" 1
}

testTracePID() {

  local duration_of_trace=30
  local test_process_pid
  local perf_record_fname

  # create the probe: see notes inside testSetDynamicProbe above
  trace.set_dynamic_probes "$my_prg_to_trace" \
                           "$my_function_to_trace $my_param_to_trace=%di"

  # Fork the test process stopped in the background
  ( kill -SIGSTOP $BASHPID; exec "${my_prg_to_trace?}" ) &
  # Get the PID of the test process stopped in the background
  test_process_pid=$!

  # Trace the test process PID for "$duration_of_trace" seconds
  ( trace.trace_pids "${test_process_pid?}" \
             "$duration_of_trace" "$my_probe_name" ) &

  # Send the CONT signal to the test process
  sleep 1    # this seems to be required for the automated Unit-Test
  kill -CONT "$test_process_pid"
  # ps -p "$test_process_pid" -f

  sleep $(( duration_of_trace + 1 ))

  # delete the perf-record dynamic uprobe
  trace.del_dyn_probes "$my_probe_name"

  # get filename that trace.trace_pids created
  perf_record_fname=$( find . -maxdepth 1 -name perf.data.\* -mmin -4 | \
                          xargs ls -tr | tail -n 1 )

  # dump that file and see a call to "$my_function_to_trace" with
  # argument "$my_param_to_trace=$my_param_value"
  trace.dump_trace "${perf_record_fname?}" | \
     grep -A 1 "$my_param_to_trace=$my_param_value" | \
     grep -qs "$my_function_to_trace"

  exit_code=$?

  # delete the perf-record trace file
  rm -f "${perf_record_fname?}"

  # expected to see a call to:
  assertEquals "Expected a call to '$my_function_to_trace" "$exit_code" 0
}

. /tmp/shunit2-source/2.1.6/src/shunit2
