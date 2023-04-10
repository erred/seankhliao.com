# library or framework

## which way to plug it in

### _library_ or framework

Occasionally, I'm in the mood to write a small utility:
maybe a webhook handler to automate something,
or a web page to display some information.
These are mostly all applications that work over HTTP(S),
so, after 2 or 3 of these,
I usually start thinking about factoring the common parts 
into a library,
and for that I've bounced between using a library style
and a framework style.

Framework would be like my previous iteration
[go.seankhliao.com/svcrunner](https://pkg.go.dev/go.seankhliao.com/svcrunner),
where you wire up everything into the framework
and hand it control to run everything.
This is quite concise, with minimal boilderplate in application,
but at times I found it limiting when I wanted to do something I didn't previously plan for,
like hook into a different part of the application lifecycle.

Example:

```go
func main() {
        hs := &http.Server{}
        svr := server.New(hs)
        svcrunner.Options{}.Run(
                svcrunner.NewHTTP(hs, svr.Register, svr.Init),
        )
}
```

What I currently do with v2 at
[go.seankhliao.com/svcrunner/v2/tshttp](https://pkg.go.dev/go.seankhliao.com/svcrunner/v2/tshttp)
might at first flance look similar,
still with `New` and `Run` functions,
but it leaves it up to the application to wire things up.
This is much more boilerplate at each callsite,
but crucially doesn't block me from doing anything.
(Though I did pull in a different framework like package in
[github.com/google/subcommands](https://pkg.go.dev/github.com/google/subcommands)...)

Example:

```go

func (c *Cmd) Execute(ctx context.Context, f *flag.FlagSet, args ...any) subcommands.ExitStatus {
        err := New(ctx, c).Run(ctx)
        if err != nil {
                return subcommands.ExitFailure
        }
        return subcommands.ExitSuccess
}

func New(ctx context.Context, c *Cmd) *Server {
        svr := tshttp.New(ctx, c.tshttpConf)
        s := &Server{
                o:   svr.O,
                svr: svr,

                render: webstyle.NewRenderer(webstyle.TemplateCompact),
                dir:    c.dir,
        }

        svr.Mux.Handle("/eur", otelhttp.NewHandler(s.hView("eur"), "hView - eur"))
        svr.Mux.Handle("/gbp", otelhttp.NewHandler(s.hView("gbp"), "hView - gbp"))
        svr.Mux.Handle("/twd", otelhttp.NewHandler(s.hView("twd"), "hView - twd"))
        svr.Mux.Handle("/", otelhttp.NewHandler(http.HandlerFunc(s.hIndex), "hIndex"))
        svr.Mux.HandleFunc("/-/ready", func(rw http.ResponseWriter, r *http.Request) { rw.Write([]byte("ok")) })
        return s
}

func (s *Server) Run(ctx context.Context) error {
        return s.svr.Run(ctx)
}
```
