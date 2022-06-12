# cloud run opentelemetry go

## getting distributed traces to connect

### _cloud_ run

Google Cloud [Run](https://cloud.google.com/run)
takes your container and runs it serverlessly on a managed platform.
It also means you get quite a bit of observability built in for "free",
with load balancer logs, metrics, and traces available to query.
Now with distributed tracing, you can connect your traces to it.

#### _cloud_ trace

Cloud [Trace](https://cloud.google.com/trace)
has its own propagationheader and format: `x-cloud-trace-context: trace-id/span-id/o=options`.
It's what the load balancers are documented to set.

In Go, using [opentelemetry](https://opentelemetry.io/),
that means you need a [TextMapPropagator](github.com/GoogleCloudPlatform/opentelemetry-operations-go/propagator)
to parse the header and save it as a span context in your [context.Context](https://pkg.go.dev/context#Context).
Thankfully, they've provided one at [CloudTraceFormatPropagator](https://pkg.go.dev/github.com/GoogleCloudPlatform/opentelemetry-operations-go/propagator#CloudTraceFormatPropagator).

What they don't document yet
is that the load balancers now also set the standard [traceparent](https://www.w3.org/TR/trace-context/#traceparent-header) header,
So the above is all unnecessary, the standard [TraceContext](https://pkg.go.dev/go.opentelemetry.io/otel/propagation#TraceContext)
propagator is all that's needed.

#### _http2_

Cloud Run has the option to do [http2 end to end](https://cloud.google.com/run/docs/configuring/http2).
For Go, this means using [h2c](https://pkg.go.dev/golang.org/x/net/http2/h2c)
to wrap your handlers and allow it to handle the upgrade.
Important to note here is that h2c doesn't propagate the context properly,
so if your h2c handler isn't the outermost one,
the propagators will extract a trace id, set it in a context,
only for it to be abandoned by h2c,
and your calls to `tracer.Start` will start new traces not connected to anything.
