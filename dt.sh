#!/usr/bin/env bash
#
# A Bash function library for dynamic tracing of user-land code in Linux, using
# Linux's kernel Performance Counters sub-system ("perf").

# set -o xtrace # set -x: uncomment to trace this bash script on standard-error

show_extern_function_names() {
    # Show the extern function names (symbols) in the code file passed as the
    # first argument to this function.

    local code_file="${1?Executable code file necessary as first argument}"

    perf probe -x  "${code_file}"  --funcs
}


trace.available_extern_functions() {
    # This name is intended more as a convenience alias (although it is
    # implemented here as a function, so that it is more compatible with the
    # plain Bourne shell. Unfortunately, some constructs in this library file
    # use Bash-only features, like '[[' - FIXME to do it as plain Bourne sh.)
    # Besides, both as an alias or as a simple wrapper function, plain Bourne
    # shell and Bash suffer from dynamic lazy binding, ie., if the aliased-to
    # name (right-hand-side) or the wrapped-name are later on redefined, then
    # the alias or wrapper function is affected (except for fully qualified
    # pathnames or scripts that clear the environment inherited from the
    # parent.)
    # Both these notes also apply to the wrapper-aliases below.

    show_extern_function_names $@
}


show_available_local_vars() {
    # Show accessible local variables in a region in the code file passed as
    # the first argument to this function: the region is passed as the second
    # argument to this function

    local code_file="${1?Executable code file necessary as first argument}"
    local region="${2?Region where to find local vars needed as 2nd argument}"

    perf probe -x  "${code_file}"  --vars "${region}"
}


trace.available_local_vars() {
    show_available_local_vars $@
}


show_available_global_and_local_vars() {
    # Show accessible global and local variables in a region in the code file
    # passed as the first argument to this function: the region is passed as
    # the second argument to this function

    local code_file="${1?Executable code file necessary as first argument}"
    local region="${2?Region where to find variables needed as 2nd argument}"

    perf probe -x  "${code_file}"  --vars "${region}" --externs
}


trace.available_global_local_vars() {
    show_available_global_and_local_vars $@
}


show_available_src_lines() {
    # Show source-code lines that can be probed in a region in the code file
    # passed as the first argument to this function: the region is passed as
    # the second argument to this function.
    # Note: this may require access to the source-code of the code file in
    #       the local Linux instance where this function is run.

    local code_file="${1?Executable code file necessary as first argument}"
    local region="${2?Region where to find src-lines needed as 2nd argument}"

    perf probe -x  "${code_file}"  --line "${region}"
}


trace.available_src_lines() {
    show_available_src_lines $@
}


set_dynamic_probes() {
    # Set a dynamic probe(s) on the code file passed as the
    # first argument, and this probe(s) will have address as the next
    # arguments to this function.

    local code_file="${1?Executable code file necessary as first argument}"
    shift

    if [[ ! -f "$code_file" ]]; then
        echo "ERROR: '$code_file' does not seem to exist." >&2
        return 1
    fi

    # set dynamic trace points
    for trace_point in $@
    do
        perf probe  -x "${code_file}"  --add "${trace_point}"
    done
}


trace.set_dynamic_probes() {
    set_dynamic_probes $@
}


list_event_probes() {
    # If the first argument is 'N' or 'false' or 'no' or omitted, then this
    # function lists the dynamic probes set on different code files, as well
    # as their code in the first column in the output.
    # If the first argument is otherwise, then list all probes available to
    # the Linux Perf Counters sub-system, not only dynamic probes but also
    # in the kernel and hardware-based.

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


trace.list_probes() {
    list_event_probes $@
}


del_dynamic_probes() {
    # Delete a dynamic probe(s) given its code-symbol(s). (To obtain the
    # code-symbol of a dynamic probe, see the first column in the output of
    # the function 'list_event_probes()' above.

    if [[ $# -lt 1 ]]; then
        echo "ERROR: list of probe names is necessary as the first argument" \
             "and so on to delete multiple probes simultaneously " \
             "[second argument, third, etc]." >&2
        return 1
    fi

    # concat all the probes requested to be deleted
    local probes_to_del=""
    for p in $@; do
        probes_to_del="$probes_to_del --del $p "
    done

    perf probe $probes_to_del
}


trace.del_dyn_probes() {
    del_dynamic_probes $@
}


trace_pids() {
    # Trace a PID(s) during some time on some given dynamic probe(s).
    # The PID(s) is a comma-separated list of PID given as the first argument
    # to this function; the time to probe (in seconds) is the second argument
    # to this function; the dynamic probes on which to trace the PIDs are
    # given as the third and successive arguments to this function.
    # This function prints the new "perf.data" file it is using to write the
    # trace (no live-mode -see below).

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
    for event in $@; do
        events="$events -e $event"
    done

    # see the function perf_target__validate() in Linux's
    # ./source/tools/perf/util/target.c for which combination of perf
    # parameters are compatible with one another, and which are
    # mutually exclusive
    local perf_record_other_options="--timestamp --call-graph dwarf"

    # don't use the default "perf.data" file to save the perf-record to.
    # (Cons: for the final dump of the trace collected you need to specify
    #        this filename perf-record wrote to. The other option can be
    #        to join the perf record and perf script directly, in live-mode.)
    local perf_data="perf.data.$( date +%s ).$$"

    perf record --output="$perf_data" $events $perf_record_other_options \
                --pid=$pids sleep "$seconds" &

    echo -e "\nCreating new trace file: '$perf_data'.\nDo your normal" \
            "operations on PIDs $pids in order to trace them."

}


trace.trace_pids() {
    trace_pids $@
}


dump_trace() {
    # Dump the trace file ("perf.data" file) printed-out by the function
    # 'trace_pids()' above.
    # This function lists the probes it hit during the trace, as well as the
    # calling-stack-backtrace up to each occurrence of the probes requested,
    # symbols address-offset, and source filename and line-number (if
    # available in the code).
    # The only argument to this function is the trace file
    # ("perf.data" file) to list.

    local perf_data="${1?Trace file necessary as first argument}"

    local perf_script_other_options="--ns"   # print nanoseconds
    perf_script_other_options+=" --fields comm,tid,time,ip,sym,symoff,srcline"

    perf script --input="$perf_data" $perf_script_other_options
}


trace.dump_trace() {
    dump_trace $@
}
