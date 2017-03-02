# dt

# WIP

This project is a *work in progress*. The implementation is *incomplete* and subject to change. The documentation can be inaccurate.

# Brief

Source the function library in this repository into your Bash session:

      . dt.sh
       
      #    this environment variable name MY_CODE_FILE is not necessary, it is
      #    just for shortening the sample pathname
      MY_CODE_FILE=/path/to/code/module-or-executable-fname
       
      #    see which external functions are available in the code file
      trace.available_extern_functions  "$MY_CODE_FILE"
          ...  
          ...  
       
      #    set one or more trace-points on that code file
      trace.set_dynamic_probes  "$MY_CODE_FILE"  trace_point1  [trace_point2 ...]
      #    the above call may be repeated on the same code file, or on another
       
      #    list all the dynamic trace-points that have been set
      trace.list_probes
       
      #    Obtain the PID(s) of program(s) already running -probably using "ps"
      #    or the /proc/ filesystem, etc- and that use the above code file. The
      #    PID(s) you specify is a comma-separated list of running PIDs. The
      #    command below starts tracing these PIDs during <duration-seconds> on
      #    the trace-points trace_pointI [trace_pointJ ...] you already set up
      #    above with "trace.set_dynamic_probes ...". (The PIDs may have been
      #    already running even well before you set the trace points with
      #    "trace.set_dynamic_probes ..." above, and this allows to
      #    troubleshoot long-running background processes and system services
      #    when an incident appears without needing to restart these system
      #    services.)
      #    IMPORTANT: take note of the "perf.data...." filename that this
      #               instruction below prints in its first output line.
      trace.trace_pids $PIDs <duration-seconds> trace_pointI [trace_pointJ ...]
         Creating new trace file: 'perf.data.<epoch-timestamp>.<random-numb>'.
         Do your normal operations on PIDs ... in order to trace them.
 
      #    [do the tests and] gather the samples on your traced executable
      #    during the <duration-seconds> of your sampling.
      ...
      ...
       
      #    remove some tracepoints of the ones set up above in
      #    "trace.set_dynamic_probes ..."
      trace.del_dyn_probes  trace_pointX  [trace_pointY ...]
       
      #    dump the trace filename "perf.data...." that the instruction
      #    above "trace.trace_pids ..." reported in its first line.
      trace.dump_trace   perf.data.1488256162.1265


Pending to TODO.

