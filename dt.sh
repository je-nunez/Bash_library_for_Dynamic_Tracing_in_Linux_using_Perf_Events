#!/usr/bin/env bash

# pending to finish, several things to do

declare -r machine_code_file="${1?Executable code file necessary as first argument}"

function set_dynamic_probes() {

     local code_file="${1?Executable code file necessary as first argument}"
     shift

     if [[ ! -f "$code_file" ]]
     then
         echo "ERROR: '$code_file' does not seem to exist." >&2
         return 1
     fi

     # set dynamic trace points
     for trace_point in $@
     do
        perf probe -x  "${code_file}"  --add "${trace_point}"
     done
}

# MAIN

shift
set_dynamic_probes  "$machine_code_file"  $@

