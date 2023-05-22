# opentelemetry-go metrics ga

## stable at last

### _opentelemetry-go_ metrics general availability

So the OpenTelemetry Go API is finally reaching stability.
Using it:

```gomod
module example.com/app

require (
    go.opentelemetry.io/otel v1.16.0-rc.1
    go.opentelemetry.io/otel/metric v1.16.0-rc.1
)
```

And in the application:

```go
package main

import (
    "context"
    "sync/atomic"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/metric"
)

func main() {
    // get the global meterprovider and create a meter named for our application
    meter := otel.Meter("example.com/app")

    // create a counter
    c1, err := meter.Int64Counter("counter1",
        // a string description
        metric.WithDescription("represents a thing"),
        // units, UCUM "c/s" type
        // https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/semantic_conventions/README.md#instrument-units
        // https://unitsofmeasure.org/ucum#section-Alphabetic-Index-By-Symbol
        metric.WithUnit("s"),
    )
    if err != nil {
        panic(err)
    }

    // context, future possibility of extracting exemplars
    ctx := context.Background()

    c1.Add(ctx, 1, metric.WithAttributes(
        // additional attributes for this datapoint
        attribute.String("foo", "bar"),
    ))

    // fake a synchronous gauge by using an atomic counter
    // this way we can set the value when we have one
    g := new(atomic.Int64)
    g.Store(22)
    // create a gauge
    _, err = meter.Int64ObservableGauge("gauge1",
        // a string description
        metric.WithDescription("represents another thing"),
        // async requires a callback to observe the value
        metric.WithInt64Callback(func(ctx context.Context, io metric.Int64Observer) error {
            io.Observe(g.Load(), metric.WithAttributes(
                attribute.String("fizz", "buzz"),
            ))
            return nil
        }),
    )
    if err != nil {
        panic(err)
    }
}
```
