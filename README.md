# A Bash library for Dynamic-Tracing in Linux using Perf Events

[![Build Status](https://travis-ci.org/je-nunez/Bash_library_for_Dynamic_Tracing_in_Linux_using_Perf_Events.svg?branch=master)](https://travis-ci.org/je-nunez/Bash_library_for_Dynamic_Tracing_in_Linux_using_Perf_Events)

A very simple Bash wrapper library for a dynamic-tracer of user-processes in Linux (kernel 3.5+) using the [`Perf Counters` subsystem](https://perf.wiki.kernel.org/index.php/Main_Page), giving also the calling-stack (backtrace) for each case of the traced-points hit during the tracing.

Sometimes it is useful to trace a program at run-time, and at the same time, obtain the stack backtraces on the list of direct and indirect callers which made the execution reached till the tracepoint(s). It is similar to the `trace` and `backtrace` (`bt`) commands in `GDB`, in the sense that it does not stop the program like breakpoints would do, but it collects calling stacks. The Linux kernel `Perf Counters` subsystem using User-space Probing (`uprobe`) is an option that makes this possible, without using `GDB`.

# WIP

This project is a *work in progress*. The implementation is *incomplete* and subject to change. The documentation can be inaccurate.

# Other information about the Perf Event Counters in Linux

The Perf wiki [https://perf.wiki.kernel.org/index.php/Main_Page](https://perf.wiki.kernel.org/index.php/Main_Page) gives a quite broad introduction to the Perf Event Counters in Linux.

Brendan Gregg's webpage [http://www.brendangregg.com](http://www.brendangregg.com) has more actual examples of the flexibility of the Perf Event Counters in different use-cases.

# Requisites:

For user-land tracing in Linux, you need a kernel version 3.5 or later, and the following config parameters in the running kernel:

       CONFIG_UPROBE_EVENT=y
       CONFIG_UPROBES=y
       CONFIG_PERF_EVENTS=y
       CONFIG_TRACEPOINTS=y

(Note: Other kernel `CONFIG_` parameters may also be needed in order to trace inside the Linux kernel with Perf Events, which is not directly dealt with in this Bash library, whose purpose is more for user-land application tracing.)

You may need to confirm that the virtual debug filesystem is mounted, and mount it if necessary:

       mount -t debugfs nodev /sys/kernel/debug

The `perf` tools and utilities (generally installed from a package through your package system).

(TODO: review and finish this section)

# A work-flow of using the library

* Source the function library in this repository into your Bash session:

          . dt.sh

* <a name="macro_MY_CODE_FILE"></a> The following environment variable name below, `MY_CODE_FILE`, is not necessary, the library does not use it, it is just as a macro for shortening the sample code pathname on which to set the trace-points, i.e., the path to the actual executable file or to a shared object (`.so`).

          MY_CODE_FILE=/path/to/code/module-or-executable-fname

* See which external functions are available in the code file, which can then be used as reference in trace-points:

          trace.available_extern_functions  "$MY_CODE_FILE"
              ...
              ... <prints the external function names available in $MY_CODE_FILE>

* See which local variables are available at a location in the code file (and their C types), which can then be requested to be printed in the hits at the trace-points -for example, the local variables available at the entry point of a function-call are only the arguments passed to that function -its stack has not yet been allocated for its internal local variables:

          trace.available_local_vars  "$MY_CODE_FILE"  <a_location>
              ...
              ... <prints the local variables available in $MY_CODE_FILE at <a_location> >

* See which global and local variables are available at a location in the code file (and their C types), which can then be requested to be printed in the hits at the trace-points:

          trace.available_global_local_vars  "$MY_CODE_FILE"  <a_location>
              ...
              ... <prints the global and local variables available in $MY_CODE_FILE at <a_location> >

* See which source code lines are available to be traced at a location in the code file, which can then be used as reference in trace-points. For example, if <a_location> is a function name, then it prints the body of this function highlighting its source-lines which can be traceable (note: **this functionality below requires the availability of the source code in the local machine from which the code file was compiled, because this functionality given by Perf shows the source code lines as they are, which of course, are not in the compiled code itself** -e.g., only if you require this functionality to see the actual source code lines, then in RedHat/CentOS distros do a `yumdownloader --source ...` and `rpm2cpio ...`, and in Debian/Ubuntu distros, do a `apt-get source ...` before running this function):

          trace.available_src_lines  "$MY_CODE_FILE"  <a_location>
              ...
              ... <prints the source lines available for a tracing in $MY_CODE_FILE at <a_location> >

* <a name="set_trace_points"></a> Set one or more trace-points on that code file (this call may be repeated multiple times on the same code file, or on another). Note please the names, or `ids`, that are returned in the standard-output for each new trace-point:

          trace.set_dynamic_probes  "$MY_CODE_FILE"  trace_point1  [trace_point2 ...]
              ...
              ... <prints the ids of the new trace-points on $MY_CODE_FILE>

The trace-points requested to `trace.set_dynamic_probes` follow the syntax for them in [perf-probe](http://man7.org/linux/man-pages/man1/perf-probe.1.html#PROBE_SYNTAX).

<a name="collecting_data_at_trace_points"></a> In particular, note that a trace-point doesn't necessarily be at a function entry-point, but can be relative to it or at its return instruction (using the suffix `%return`). Also note that trace-points can also specify data variables (arguments) and their dereferences (including array subscripting and field members in a C structure), to collect at that trace-point, using the syntax at [http://man7.org/linux/man-pages/man1/perf-probe.1.html#PROBE_ARGUMENT](http://man7.org/linux/man-pages/man1/perf-probe.1.html#PROBE_ARGUMENT):

           [NAME=]LOCALVAR|$retval|%REG|@SYMBOL[:TYPE]

This ability to collect arbitrary data values at the moment a trace-point executed is somehow similar to `GDB`'s trace-points actions for collecting data -explained at [https://sourceware.org/gdb/onlinedocs/gdb/Tracepoint-Actions.html](https://sourceware.org/gdb/onlinedocs/gdb/Tracepoint-Actions.html).

Please note that the compiler may have optimized data into CPU registers in the executable code it emitted. If this was the case, then at execution-time you may need to collect the `%REG` to recall that data and not the original symbolic name of the variable in the input source code to the compiler. For example, to collect the values of the parameter to a function-call, if the executable code was emitted for the x86-64 architecture, then the calling convention is the System V AMD64 ABI, and then the compiler may have optimized such parameter-passing into a function-call using CPU registers, and not by actually pushing them onto the stack. So, if x86-64 is the architecture, then you may request the value of the parameters in your trace using:

          # let's name, in our tracing, the parameters to
          # my_traced_function(...) as:
          #     my_first_param
          #     my_second_param
          # etc. Then, in order to collect these parameters at the entry-point
          # of my_traced_function(...), if the code was compiled for the
          # x86-64 architecture and optimized by the compiler, we may need to
          # collect the CPU registers the compiler actually used to pass
          # these parameters to the function call:
           
          MY_TRACE_POINT='my_traced_function my_first_param=%di my_second_param=%si ...'
           
          trace.set_dynamic_probes  "$MY_CODE_FILE"  "$MY_TRACE_POINT"

Note in the example above that the trace-point and the argument data to collect at it, are specified as one single string argument (i.e., the trace-point and its arguments data to collect are all inside the single string variable `"$MY_TRACE_POINT"` -this Bash variable `"$MY_TRACE_POINT"` is for making this bundling clearer, the library does not use this variable). Furthermore, as an extra note, to save the parameters to a function call in the trace, if they were optimized into CPU registers by the compiler, you may need to collect them at a trace-point precisely at the entry-point of the function (as in this example above), not in a relative point later in the function body, since the compiler may have re-used those CPU registers to hold other data further down inside the function body.

To see all the CPU registers that a compiler may use when optimizing the parameters into a function call in the System V AMD64 ABI of the x86-64 architecture, see page 23 of [https://software.intel.com/sites/default/files/article/402129/mpx-linux64-abi.pdf](https://software.intel.com/sites/default/files/article/402129/mpx-linux64-abi.pdf).

For a practical example of collecting arguments at trace-points using Perf-Events -which this Bash library uses-, that may explain more easily the collection of data samples at trace-points (function-calls), see *Linux Perf Probes for Oracle Tracing* at [https://db-blog.web.cern.ch/blog/luca-canali/2016-01-linux-perf-probes-oracle-tracing](https://db-blog.web.cern.ch/blog/luca-canali/2016-01-linux-perf-probes-oracle-tracing).

* <a name="list_probes"></a> To list all the dynamic trace-points that have been set, and their identifiers, use:

          trace.list_probes
              ...
              ... <prints the ids of all the trace-points set>

* <a name="trace_pids"></a> To actually trace a process(es) that use the above code file (in our example, [`"$MY_CODE_FILE"`](#macro_MY_CODE_FILE)), first obtain the PID(s) of such process(es) already running. Join these PID(s) in a comma-separated list (no space). Then the command below starts tracing these PIDs during `<duration-seconds>` on the trace-points `trace_pointI [trace_pointJ ...]` you already set up above with [`trace.set_dynamic_probes ...`](#set_trace_points). (The `PIDs` environment variable below is not necessary either, it is just for shortening the comma-separated list of PIDs to trace.)

          trace.trace_pids $PIDs <duration-seconds> trace_pointI [trace_pointJ ...]
             Creating new trace file: 'perf.data.<epoch-timestamp>.<random-numb>'.
             Do your normal operations on PIDs ... in order to trace them.

The PIDs may have been already running even well before you set the trace points with [`trace.set_dynamic_probes ...`](#set_trace_points) above, and this allows to troubleshoot long-running background processes and system services when an incident appears without needing to restart these system services. It is important to **take note of the `perf.data....` filename that this instruction above prints in its first output line, because this filename will be necessary later on to dump the results**. (Note: the `perf event counters` subsystem in the Linux kernel, and associated user-level tools, offer much more functionality, like, among others, *live-mode* -where the dump is printed immediately as the process is being traced, without using an intermediate `perf.data....` file: for this feature, please see the man page of `perf script` at [http://man7.org/linux/man-pages/man1/perf-script.1.html](http://man7.org/linux/man-pages/man1/perf-script.1.html)):

* After the trace has started, wait `<duration-seconds>` while it is gathering the perf data.

* To dump the trace filename `perf.data....` that the instruction above [`trace.trace_pids ...`](#trace_pids) reported in its first line (including timestamps and dumping as well the calling stacks for those execution hits on the traced symbols, and source code filename and line number if available), you may use:

          trace.dump_trace   perf.data.<printed-by-trace.trace_pids-above>

If there are some probes recorded inside that trace file `perf.data....` which requested collection of data arguments at the probe -see [collecting data arguments at a trace point](#collecting_data_at_trace_points) above-, then `trace.dump_trace perf.data....` will print these data arguments collected when the execution passed through that probe point. (This is somehow similar to `GDB`'s `tdump` instruction to dump data collected at a trace-point, [https://sourceware.org/gdb/onlinedocs/gdb/tdump.html](https://sourceware.org/gdb/onlinedocs/gdb/tdump.html). I.e., `trace.dump_trace ...` will print automatically the data collected at a trace-point if the probe defined at `trace.set_dynamic_probes ...` had requested to collect such data at the trace-point -see [collecting data arguments at a trace point](#collecting_data_at_trace_points) above.)

* To remove some tracepoints among the ones set up above in [`trace.set_dynamic_probes ...`](#set_trace_points), specify their ids in:

          trace.del_dyn_probes  trace_pointX  [trace_pointY ...]

(In a long session, you may obtain the ids of the trace-points currently set calling [`trace.list_probes`](#list_probes).)

Pending to TODO more details.

