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
       
      #    set one or more trace-points on that code file
      trace.set_dynamic_probes  "$MY_CODE_FILE"  trace_point1  [trace_point2 ...]
      #    the above call may be repeated on the same code file, or on another
       
      #    list all the dynamic trace-points that have been set
      trace.list_probes
       
      #    start your program which uses the above code file and get its PID
      #    -you may need to set it to the background with the job control
      #    features in your shell- and trace it during <duration-seconds>
      #    on the trace-points trace_pointI [trace_pointJ ...] you already
      #    set up above with "trace.set_dynamic_probes ..."
      #    IMPORTANT: take note of the "perf.data...." filename that this
      #               instruction below prints as its first and only
      #               output line.
      trace.trace_pids $PID  <duration-seconds>  trace_pointI  [trace_pointJ ...]
       
      #    do the tests on your traced executable during <duration-seconds>
      ...
      ...
       
      #    dump the trace filename perf.data...." that the instruction
      #    above "trace.trace_pids..." reported in its first line.
      trace.dump_trace   perf.data.1488256162.1265


Pending to TODO.

