# otelcol cueprocessor

## cue as a data mangler?

### _otelcol_

The [opentelemetry collector](https://github.com/open-telemetry/opentelemetry-collector)
is built in a modular way.
Which means you can relatively easily write your own receiver/processor/exporter
and build a version of the collector with it.

#### _cue_

[cue](https://cuelang.org/)
is a language more suited for config and validation,
but that doesn't mean you can't use it for data transformations too...

#### _writing_ a processor

So, what do we need to write a procssor?

Using collector v0.56.0

##### _config_

This is the config that our procssor takes,
which will be nested in the collector config yaml.

```go
package cueprocessor

import (
        "cuelang.org/go/cue/cuecontext"
        "go.opentelemetry.io/collector/config"
)

type Config struct {
        // standard field that you need to embed
        // squash ensures fields are correctly decoded in embedded struct
        config.ProcessorSettings `mapstructure:",squash"`

        // input that our processor needs
        Program string `mapstructure:"program"`
}

// We're not going to do any validation now,
// cue makes it a bit annoying to handle undeclared references
func (c *Config) Validate() error {
        return nil
}
```

##### _factory_

The collector builder hardcodes the name NewFactory.
With that, we register functions that will create our processor instances.

```go
package cueprocessor

import (
        "context"

        "go.opentelemetry.io/collector/component"
        "go.opentelemetry.io/collector/config"
        "go.opentelemetry.io/collector/consumer"
        "go.opentelemetry.io/collector/pdata/plog"
        "go.opentelemetry.io/collector/pdata/pmetric"
        "go.opentelemetry.io/collector/pdata/ptrace"
)

const (
        // The value of "type" key in configuration.
        typeStr = "cue"
)

// This registers the type name, the config, and functions to create processor instances.
func NewFactory() component.ProcessorFactory {
        return component.NewProcessorFactory(
                typeStr,
                createDefaultConfig,
                component.WithTracesProcessorAndStabilityLevel(createTracesProcessor, component.StabilityLevelInDevelopment),
                component.WithMetricsProcessorAndStabilityLevel(createMetricsProcessor, component.StabilityLevelInDevelopment),
                component.WithLogsProcessorAndStabilityLevel(createLogsProcessor, component.StabilityLevelInDevelopment),
        )
}

func createDefaultConfig() config.Processor {
        return &Config{
                ProcessorSettings: config.NewProcessorSettings(config.NewComponentID(typeStr)),
        }
}

func createTracesProcessor(ctx context.Context, s component.ProcessorCreateSettings, p config.Processor, next consumer.Traces) (component.TracesProcessor, error) {
        proc, err := newProcessor(p.(*Config))
        if err != nil {
                return nil, err
        }
        return &tracesProcessor{
                processor: proc,
                next:      next,
                m:         ptrace.NewJSONMarshaler(),
                u:         ptrace.NewJSONUnmarshaler(),
        }, nil
}

func createMetricsProcessor(ctx context.Context, s component.ProcessorCreateSettings, p config.Processor, next consumer.Metrics) (component.MetricsProcessor, error) {
        proc, err := newProcessor(p.(*Config))
        if err != nil {
                return nil, err
        }
        return &metricsProcessor{
                processor: proc,
                next:      next,
                m:         pmetric.NewJSONMarshaler(),
                u:         pmetric.NewJSONUnmarshaler(),
        }, nil
}

func createLogsProcessor(ctx context.Context, s component.ProcessorCreateSettings, p config.Processor, next consumer.Logs) (component.LogsProcessor, error) {
        proc, err := newProcessor(p.(*Config))
        if err != nil {
                return nil, err
        }
        return &logsProcessor{
                processor: proc,
                next:      next,
                m:         plog.NewJSONMarshaler(),
                u:         plog.NewJSONUnmarshaler(),
        }, nil
}
```

##### _processor_

The actual processor.
It's a bit repetitive to work over the 3 metric types.

The collector only exposes the data via a lot of functions
and not the underlying data structure.
This makes is sufficiently annoying to work with and I opted
to roundtrip through json serialization.
Additionally, I made the choice here to call the processor once per resource,
but after thinking a bit more about it,
I think it could have been called over the entire batch,
and left to the user to iterate over the input in a list comprehension.

```go
package cueprocessor

import (
        "context"

        "cuelang.org/go/cue"
        "cuelang.org/go/cue/cuecontext"
        cuejson "cuelang.org/go/encoding/json"
        "go.opentelemetry.io/collector/component"
        "go.opentelemetry.io/collector/consumer"
        "go.opentelemetry.io/collector/pdata/plog"
        "go.opentelemetry.io/collector/pdata/pmetric"
        "go.opentelemetry.io/collector/pdata/ptrace"
)

type tracesProcessor struct {
        processor
        next consumer.Traces
        m    ptrace.Marshaler
        u    ptrace.Unmarshaler
}

type metricsProcessor struct {
        processor
        next consumer.Metrics
        m    pmetric.Marshaler
        u    pmetric.Unmarshaler
}

type logsProcessor struct {
        processor
        next consumer.Logs
        m    plog.Marshaler
        u    plog.Unmarshaler
}

type processor struct {
        prog string
}

func newProcessor(c *Config) (processor, error) {
        return processor{
                prog: c.Program,
        }, nil
}

func (p processor) Capabilities() consumer.Capabilities {
        return consumer.Capabilities{MutatesData: true}
}

func (p processor) Start(ctx context.Context, host component.Host) error {
        return nil
}

func (p processor) Shutdown(ctx context.Context) error {
        return nil
}

func (p tracesProcessor) ConsumeTraces(ctx context.Context, data ptrace.Traces) error {
        final := ptrace.NewTraces()
        final.ResourceSpans().EnsureCapacity(data.ResourceSpans().Len())

        single := ptrace.NewTraces()
        single.ResourceSpans().EnsureCapacity(1)

        for i := 0; i < data.ResourceSpans().Len(); i++ {
                single.ResourceSpans().AppendEmpty()
                data.ResourceSpans().At(i).MoveTo(single.ResourceSpans().At(0))
                jsonRaw, err := p.m.MarshalTraces(single)
                if err != nil {
                        return err
                }
                expr, err := cuejson.Extract("", jsonRaw)
                if err != nil {
                        return err
                }

                c := cuecontext.New()
                val := c.CompileString("in: {}")
                val = val.Fill(expr, "in")
                val = c.CompileString(p.prog, cue.Scope(val))
                val = val.Lookup("out")

                jsonRaw, err = val.MarshalJSON()
                if err != nil {
                        return err
                }
                single, err = p.u.UnmarshalTraces(jsonRaw)
                if err != nil {
                        return err
                }

                single.ResourceSpans().MoveAndAppendTo(final.ResourceSpans())
        }

        return p.next.ConsumeTraces(ctx, final)
}

func (p metricsProcessor) ConsumeMetrics(ctx context.Context, data pmetric.Metrics) error {
        final := pmetric.NewMetrics()
        final.ResourceMetrics().EnsureCapacity(data.ResourceMetrics().Len())

        single := pmetric.NewMetrics()
        single.ResourceMetrics().EnsureCapacity(1)

        for i := 0; i < data.ResourceMetrics().Len(); i++ {
                single.ResourceMetrics().AppendEmpty()
                data.ResourceMetrics().At(i).MoveTo(single.ResourceMetrics().At(0))
                jsonRaw, err := p.m.MarshalMetrics(single)
                if err != nil {
                        return err
                }
                expr, err := cuejson.Extract("", jsonRaw)
                if err != nil {
                        return err
                }

                c := cuecontext.New()
                val := c.CompileString("in: {}")
                val = val.Fill(expr, "in")
                val = c.CompileString(p.prog, cue.Scope(val))
                val = val.Lookup("out")

                jsonRaw, err = val.MarshalJSON()
                if err != nil {
                        return err
                }
                single, err = p.u.UnmarshalMetrics(jsonRaw)
                if err != nil {
                        return err
                }

                single.ResourceMetrics().MoveAndAppendTo(final.ResourceMetrics())
        }

        return p.next.ConsumeMetrics(ctx, final)
}

func (p logsProcessor) ConsumeLogs(ctx context.Context, data plog.Logs) error {
        final := plog.NewLogs()
        final.ResourceLogs().EnsureCapacity(data.ResourceLogs().Len())

        single := plog.NewLogs()
        single.ResourceLogs().EnsureCapacity(1)

        for i := 0; i < data.ResourceLogs().Len(); i++ {
                single.ResourceLogs().AppendEmpty()
                data.ResourceLogs().At(i).MoveTo(single.ResourceLogs().At(0))
                jsonRaw, err := p.m.MarshalLogs(single)
                if err != nil {
                        return err
                }
                expr, err := cuejson.Extract("", jsonRaw)
                if err != nil {
                        return err
                }

                c := cuecontext.New()
                val := c.CompileString("in: {}")
                val = val.Fill(expr, "in")
                val = c.CompileString(p.prog, cue.Scope(val))
                val = val.Lookup("out")

                jsonRaw, err = val.MarshalJSON()
                if err != nil {
                        return err
                }
                single, err = p.u.UnmarshalLogs(jsonRaw)
                if err != nil {
                        return err
                }

                single.ResourceLogs().MoveAndAppendTo(final.ResourceLogs())
        }

        return p.next.ConsumeLogs(ctx, final)
}

```

#### _building_ the collector

With the above, we can build a collector using the
[builder](https://github.com/open-telemetry/opentelemetry-collector/tree/main/cmd/builder)

We need a config file with some basic receivers/exporters for debugging:

```yaml
receivers:
  - import: go.opentelemetry.io/collector/receiver/otlpreceiver
    gomod: go.opentelemetry.io/collector v0.56.0
processors:
  - gomod: go.seankhliao.com/otelcol-exp v0.0.0
    import: go.seankhliao.com/otelcol-exp/cueprocessor
    path: /home/arccy/code/soft-serve/otelcol-exp
exporters:
  - import: go.opentelemetry.io/collector/exporter/loggingexporter
    gomod: go.opentelemetry.io/collector v0.56.0
```

and we can build it with

```sh
$ builder --config builder.yaml
```

#### _running_ the collector

And we can run it, with an example config like:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: localhost:4317

processors:
  cue:
    program: |
      out: resourceSpans: [{
        resource: attributes: [
            for x in in.resourceSpans[0].resource.attributes {x},
            {key: "foo", value: stringValue: "bar"},
        ]
        scopeSpans: in.resourceSpans[0].scopeSpans
        schemaUrl: in.resourceSpans[0].schemaUrl
      }]

exporters:
  logging:
    loglevel: debug

service:
  pipelines:
    traces:
      receivers:
        - otlp
      processors:
        - cue
      exporters:
        - logging
```

running it with:

```sh
$ /tmp/otelcol-distribution1976041369/otelcol-custom --config config.yaml
```

and we can test it by sending some traces using
[tracegen](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/cmd/tracegen)

```sh
$ tracegen -otlp-insecure -traces 1
```
