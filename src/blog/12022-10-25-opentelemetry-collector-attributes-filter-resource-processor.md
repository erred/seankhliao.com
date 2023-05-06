# OpenTelemetry Collector Attributes Filter Resource Processors

## What are all these overlapping processors

### _OpenTelemetry_ Collector processors

#### _Attributes_ Processor

The [attributesprocessor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/attributesprocessor)
allows changing the values of named attributes,
with optional selection fields to only process some data.
Regardless of processing result, all data passes through.

The filtering logic is:

- If `include` section, and not explicityly included, skip
- If `exclude` section, and explicityly excluded, skip
- keep

#### _Filter_ Processor

The [filterprocessor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/filterprocessor)
uses the same include/exclude config as the attributesprocessor,
but split into distinct metrics/logs/spans subsections.

The logic is:

- If `include` section, and not explicitly included, drop
- If `exclude` section, and explicitly excluded, drop
- keep

#### _Resource_ Processor

The [resourceprocessor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/resourceprocessor)
allows changing attributes at the resource level,
but with no filtering.
