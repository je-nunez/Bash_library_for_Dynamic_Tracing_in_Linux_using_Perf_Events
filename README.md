# dt

# WIP

This project is a *work in progress*. The implementation is *incomplete* and subject to change. The documentation can be inaccurate.

# A work-flow of using the library

Source the function library in this repository into your Bash session:

      . dt.sh

The following environment variable name MY_CODE_FILE is not necessary, the library does not use it, it is just as a macro for shortening the sample code pathname, e.g., the path to the actual executable file or to a shared object (`.so`).

      MY_CODE_FILE=/path/to/code/module-or-executable-fname

See which external functions are available in the code file, which then can be used as trace-points:

      trace.available_extern_functions  "$MY_CODE_FILE"
          ...
          ...

Set one or more trace-points on that code file (this call may be repeated multiple times on the same code file, or on another). Note please the names, or `ids`, that are returned in the standard-output for each new trace-point:

      trace.set_dynamic_probes  "$MY_CODE_FILE"  trace_point1  [trace_point2 ...]

To list all the dynamic trace-points that have been set, and their identifiers, use:

      trace.list_probes

To actually trace a process(es), obtain the PID(s) of those process(es) already running -probably using `ps` or the `/proc/` filesystem, etc- and that use the above code file (in our example, `"$MY_CODE_FILE"`). The PID(s) you specify is a comma-separated list of running PIDs. Then the command below starts tracing these PIDs during `<duration-seconds>` on the trace-points `trace_pointI [trace_pointJ ...]` you already set up above with `trace.set_dynamic_probes ...` (The PIDs may have been already running even well before you set the trace points with `trace.set_dynamic_probes ...` above, and this allows to troubleshoot long-running background processes and system services when an incident appears without needing to restart these system services.) (The `PIDs` environment variable below is not necessary either, it is just for shortening the comma-separated list of PIDs to trace). It is important to *take note of the `perf.data....` filename that this instruction below prints in its first output line, because it will be necessary later on to dump the results* (note: the `perf event counters` in the Linux kernel offer much more functionality, like, among others, live-mode -where the dump is printed immediately as the process is being traced, without using an intermediate `perf.data....` file: for this feature, please see the man page of `perf script` at (http://man7.org/linux/man-pages/man1/perf-script.1.html)[http://man7.org/linux/man-pages/man1/perf-script.1.html]):

      trace.trace_pids $PIDs <duration-seconds> trace_pointI [trace_pointJ ...]
         Creating new trace file: 'perf.data.<epoch-timestamp>.<random-numb>'.
         Do your normal operations on PIDs ... in order to trace them.

After the trace has started, wait `<duration-seconds>` while it is gathering the perf data.

To dump the trace filename "perf.data...." that the instruction above `trace.trace_pids ...` reported in its first line, including the calling stacks for those trace symbols, and source code filename and line number if available, you may use:

      trace.dump_trace   perf.data.<printed-by-trace.trace_pids-above>

To remove some tracepoints among the ones set up above in `trace.set_dynamic_probes ...`, specify their ids in:

      trace.del_dyn_probes  trace_pointX  [trace_pointY ...]


Pending to TODO more details.

