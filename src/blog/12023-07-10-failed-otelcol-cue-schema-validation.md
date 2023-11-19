# failed: otelcol config schema validation in cue

## failed experiment 3

#### _cue_ schema validation

I wanted a json schema for the
[opentelemetry-collector's](https://github.com/open-telemetry/opentelemetry-collector-contrib)
configuration.
As far as I know,
the only way config is defined is as Go types within the various components
(receivers, processors, exporters, connectors, extensions).

My thought went straight to [cue](https://cuelang.org/),
thinking it could automatically extract cue schemas from go types,
then maybe validate directly or generate an openapi schema.

Unfortunately,
it turns out that `cue get go $go_package` has quite a few issues:
it panics on generics, and it doesn't like unsafe,
I think there was a third panic that i don't quite remember.
This makes it much less useful for automatic schema extraction,
even if the types I want (usually the `Config` structs + their fields)
don't use any of generics or unsafe.

```sh
$ cue get go -i go.opentelemetry.io/collector/service
panic: unsupported type *types.TypeParam [recovered]
	panic: unsupported type *types.TypeParam
---
$ cue get go go.opentelemetry.io/collector/receiver/otlpreceiver
invalid identifier "unsafe.Pointer"
```

As for validation directly via cue,
I get the feeling the output isn't quite as nice.

```sh
$ cue vet config.yaml config.cue -d '#Config'
_pipelines.logs.exporters.awss3: conflicting values false and true:
    ./config.cue:61:3
    ./config.cue:69:5
    ./config.cue:70:24
    ./config.cue:70:31
```

Config included below for completion

```cue
package otelcolconfig

import (
	"github.com/open-telemetry/opentelemetry-collector-contrib/exporter/awss3exporter"
	"github.com/open-telemetry/opentelemetry-collector-contrib/processor/transformprocessor"
	"github.com/open-telemetry/opentelemetry-collector-contrib/receiver/webhookeventreceiver"
)

#Config: {
	receivers: {
		[=~"^webhookevent(/.+)?$"]: webhookeventreceiver.#Config
	}
	processors?: {
		[=~"^transform(/.+)?$"]: transformprocessor.#Config
	}
	exporters: {
		[=~"^awss3(/.+)$"]: awss3exporter.#Config
	}
	connectors?: {}
	extensions?: {}
	// can't import service def due to
	// https://github.com/cue-lang/cue/issues/2217
	service: close({
		telemetry?: close({
			logs?: {
				level?:              "debug" | "info" | "warn" | "error"
				development?:        bool
				disable_caller?:     bool
				disable_stacktrace?: bool
				sampling?: {
					initial?:    int
					thereafter?: int
				}
				error_output_paths?: [...string]
				initial_fields?: [string]: string
			}
			metrics?: {
				level:   "none" | "basic" | "normal" | "detailed"
				address: =~"^.*(:\\d)?"
				metric_readers?: [...{
					args?: _
					type?: string
				}]
			}
			traces?: {
				propagators?: [...string]
			}
		})
		extensions: [...string]
		pipelines: [=~"^traces(/.*)?"]:  #Pipeline
		pipelines: [=~"^metrics(/.*)?"]: #Pipeline
		pipelines: [=~"^logs(/.*)?"]:    #Pipeline
	})

	_extensions: {
		for e in service.extensions {
			(e): true & extensions[e] != _|_
		}
	}
	_pipelines: {
		for pname, pipeline in service.pipelines {
			(pname): {
				for r in pipeline.receivers {
					"receivers": (r): true & receivers[r] != _|_
				}
				for p in pipeline.processors {
					"processors": (p): true & processors[p] != _|_
				}
				for e in pipeline.exporters {
					"exporters": (e): true & exporters[e] != _|_
				}
			}
		}
	}
}
#Pipeline: {
	receivers: [...string]
	processors?: [...string]
	exporters: [...string]
}
```
