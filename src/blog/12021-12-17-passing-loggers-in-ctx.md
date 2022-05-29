# passing loggers in context

## thoughts on passing loggers downstream

### loggers

Loggers, usually you don't want the global one
as there's groups of settings you want to pass together or log everytime.
So now you have a logger instance,
how do you pass that downstream?

One option is to make the logger part of struct,
after all, you probably also have other state you need to hold:

```go
func (s *Server) DoX() {
        s.l.Info("something happened")
}
```

Another is to stuff the logger into a context and pass it down the request chain:

```go
func (s *Server) DoX(ctx context.Context) {
        l := logr.FromContextOrDiscard(ctx)
        l.Info("something happened")
}
```

#### ctx

For the past year,
I've been using [`logr`](https://pkg.go.dev/github.com/go-logr/logr) as my logging interface
and extensively using its [`FromContextOrDiscard`](https://pkg.go.dev/github.com/go-logr/logr#FromContextOrDiscard)
to pass around the logger.

Advantages:

- everything can log, as long as it takes a `context.Context`
- adding values to be used in all downstream logs is easy

Disadvantages:

- your first line of every function is now: `l := logr.FromContextOrDiscard(ctx)`
- every entrypoint (ie public function) needs to remember to set common values (eg name)
- logger naming is awkward when passed between 2 long lived components

#### logger in struct

I've now more or less swung back to having the logger embedded as part of a struct.
It is unfortunate that now free standing functions can't easily log,
but maybe that's ok?
The logger provenance is much clearer,
but embedding fixed values for the duration of a request becomes more awkward.

In this light, [`zerolog`](https://pkg.go.dev/github.com/rs/zerolog)'s
[`Context`](https://pkg.go.dev/github.com/rs/zerolog#Context) makes more sense.
Maybe it's something I'll look at.

#### trace

An alternative to repeating fields every time you log
may be to log `trace_id` / `span_id` fields with every request,
and you'd look at all messages to get the full picture,
though how well this works with levelled logging might be questionable,
if key information is only included in the more verbose log levels.
