#!/usr/bin/env bash

# set -o xtrace # set -x: uncomment to trace this bash script on standard-error

function show_extern_function_names() {

    local code_file="${1?Executable code file necessary as first argument}"

    perf probe -x  "${code_file}"  --funcs
}


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
        perf probe  -x "${code_file}"  --add "${trace_point}"
    done
}


function list_event_probes() {

    local list_all_events="${1:-N}"

    if [[ "$list_all_events" == 'no' || "$list_all_events" == 'false' ]]; then
        list_all_events='N'
    fi

    if [[ "$list_all_events" == 'N' ]]; then
        perf probe -l
    else
        perf list
    fi
}


function del_dynamic_probes() {

    if [[ $# -lt 1 ]]; then
        echo "ERROR: list of probe names is necessary as the first argument" \
             "and so on to delete multiple probes simultaneously " \
             "[second argument, third, etc]." >&2
        return 1
    fi

    local probes_to_del=""
    for p in $@
    do
        probes_to_del=$( printf "%s --del %s " "$probes_to_del" "$p" )
    done

    perf probe $probes_to_del
}


function trace_pids() {

    local pids="${1?PIDs to trace needed as first argument [comma-separated]}"
    local seconds="${2?Number of seconds to trace needed as second argument.}"
    shift 2

    if [[ $# -lt 1 ]]; then
        echo "ERROR: list of probe names is necessary as the third argument" \
             "and so on if probing for multiple probes simultaneously " \
             "[fourth argument, fifth, etc]." >&2
        return 1
    fi

    local events=""
    for event in $@
    do
        events="$events -e $event"
    done

    # see the function perf_target__validate() in Linux's
    # ./source/tools/perf/util/target.c for which combination of perf
    # parameters are compatible with one another, and which are
    # mutually exclusive
    local perf_other_options="--timestamp -g --call-graph dwarf"

    perf record $events --pid=$pids $perf_other_options sleep "$seconds" &
    echo "Do your normal operation on PIDs $pids in order to trace them."

}

