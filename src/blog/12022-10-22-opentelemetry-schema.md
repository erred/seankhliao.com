# OpenTelemetry Schema

## What does "schema" mean to you

### _Telemetry_ Schemas

In its current form,
OpenTelemetry's [Schemas](https://opentelemetry.io/docs/reference/specification/schemas/overview/)
are just a mapping of old names to new ones.
The primary motivation appears to be to allow
[semantic conventions](https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/)
(well known key names) to evolve,
with the consumer at the moment being the collector's
[schemaprocessor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/schemaprocessor).
If you wanted something like [JSON Schema](https://json-schema.org/),
this isn't it.
