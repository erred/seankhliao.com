# go profiling

## performance issues? profile with pprof

### _profiling_

Got a performance issue?
Other than stare at your code really hard,
you can profile it.
Or in other words,
measure it as it does real work.

Go has native (runtime) integration for profiling a few low level things:
the CPU (cpu, trace), memory (heap, alloc), sync (block, mutex),
concurrency (goroutine, threadcreate),
as well as custom profiles.
These are exposed via [`runtime/pprof`](https://pkg.go.dev/runtime/pprof)
and [`net/http/pprof`](https://pkg.go.dev/net/http/pprof),
with the output parseable by [`pprof`](https://github.com/google/pprof),
which is vendored into the `go` tool under `go tool pprof`.

#### _profile_ types

##### _custom_

The available API for custom profiles is really simple.
It serves a single usecase:
keep a count of live references by the stacktrace it took to reach the `Add` call.
That's really all there is, a count of stacktraces (unique execution paths),
which can be queried / graphed later.
The corollary is that profiling this way is likely only to be interesting for relatively low level things,
that are used across a range of paths,
else you'd just get a linear path.

- `p := pprof.NewProfile("example.com/profile1")`
- `p.Add(uniqueID, 1)`
- `p.Remove(uniqueID)`

##### _cpu_

The CPU profile shows you where time is spent in terms of function calls,
while a trace gives you a low level view of processors, goroutines, and scheduling.
All aided by the kernel which provides some of the info when it sends SIGPROF.

##### _memory_

`heap` is a view of where the live things are, 
`allocs`is where memory is being allocated (and also a likely candidate for churn / pressure on the GC).
Memory related information is only collected during / after a GC cycle.

##### _sync_

`block` points to the waiting things, 
while `mutex` points to the things holding the locks (causing others to wait).

##### _concurrency_

`goroutine` dumps the stacktrace of every running goroutine,
it is, expectedly, an expensive operation.
`threadcreate` is apparently broken, as the trigger to create new threads has shifted.
