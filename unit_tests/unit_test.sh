#!/usr/bin/env bash

# Testing some functionality of the Bash library, using "shunit2"
# Expects some environment set up by Travis Continuous Integration
# like a Linux kernel whose version be 3.5 or greater, the "shunit2"
# Shell Unit-Testing library under /tmp/, etc.

my_prg_to_trace='/tmp/simple'
my_function_to_trace='my_func'
my_param_to_trace='my_param'

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

  trace.set_dynamic_probes "$my_prg_to_trace" "$my_function_to_trace"

  trace.list_probes | grep -qs "$my_probe_name"

  exit_code=$?
  if [[ "$exit_code" == "0" ]]; then
    trace.del_dyn_probes "$my_probe_name"
  fi

  assertEquals "Expected to see a new probe '$my_probe_name'" "$exit_code" 0
}

testDelDynamicProbe() {

  # create the probe
  trace.set_dynamic_probes "$my_prg_to_trace" "$my_function_to_trace"

  # del the probe
  trace.del_dyn_probes "$my_probe_name"

  # see if the probe still exists
  trace.list_probes | grep -qs "$my_probe_name"

  exit_code=$?

  assertEquals "Did not expect the probe '$my_probe_name'" "$exit_code" 1
}

. /tmp/shunit2-source/2.1.6/src/shunit2

