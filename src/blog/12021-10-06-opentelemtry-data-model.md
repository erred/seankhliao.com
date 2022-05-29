# opentelemetry data model

## understanding how opentelemetry handles data

### _OpenTelemetry_

[OpenTelemetry](https://opentelemetry.io/),
the new standard in telemetry (observability data) collection,
has a [spec](https://github.com/open-telemetry/opentelemetry-specification)
(that I think is obtuse)
and protobufs defining its [data model](https://github.com/open-telemetry/opentelemetry-proto).

#### _Data_ Model

Keywords:

- Resource: an app/service
- InstrumentationLibrary: instance of sdk used to generate data in app

For the apps (resources) that generate data,
`ResourceSpans` will typically contain a single element.

##### _Traces_

ref: [trace.proto](https://github.com/open-telemetry/opentelemetry-proto/blob/main/opentelemetry/proto/trace/v1/trace.proto)

Traces

- ResourceSpans[]
  - InstrumentationLibrarySpans[]
    - Spans[]

##### _Metrics_

ref: [metrics.proto](https://github.com/open-telemetry/opentelemetry-proto/blob/main/opentelemetry/proto/metrics/v1/metrics.proto)

Metrics

- ResourceMetrics[]
  - InstrumentationLibraryMetrics[]
    - Metrics[]
      - metric type
        - data points[]

##### _Logs_

ref: [logs.proto](https://github.com/open-telemetry/opentelemetry-proto/blob/main/opentelemetry/proto/logs/v1/logs.proto)

Logs

- ResourceLogs[]
  - InstrumentationLibraryLogs[]
    - LogRecord[]

#### _Collector_

Where is the data model useful?
In the [collector](https://github.com/open-telemetry/opentelemetry-collector),
where the internal representation is a thin wrapper over the protobufs.

Ignoring the fact that there are layers of factories and indirection in the code,
processors are constructed with config and the next processor
(eg typed [`consumer.Traces`](https://pkg.go.dev/go.opentelemetry.io/collector/consumer#Traces)).

This means each processor is simply a method `ConsumeXXX`,
handed an instance of one the top level resources shown above,
and calls the next processor with the remaining/mutated data when its done.

The last processor is given a fanout processor which connects to all the exporters.
