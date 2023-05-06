# servicemonitors to datadog

## headaches over data conversion

### _servicemonitors_ into datadog

As part of $work's somewhat rushed replatforming of observability tooling on Datadog,
we've need to ingest the metrics currently produced by our applications
using Prometheus Exposition Format into Datadog.

This represents quite a few challenges:
Our services are defined by ServiceMonitor resources,
we have at least 1 very large cluster,
and Datadog fundamentally uses a different data model for recording data.

#### _servicemonitors_

The ServiceMonitor CRD is essentially a fragment of prometheus config as a kubernetes resource,
with some implicit rules for service discovery.
Prometheus Operator will read and combine them into a full prometheus config,
and run prometheus with the config for you.

The problem with using prometheus is... it doesn't retain type data in its storage TSDB,
so when you try to get the data out of it, you're left guessing if a series is a counter or a guage.

The only obvious choice was the OpenTelemetry Collector's nascent support for ServiceMonitors.
It uses a different architecture, using a separate service to perform service discovery,
and sharding the generated config to multiple collector instances,
allocating targets using the http sd protocol.

We've had issues, such as:
runaway resource consumption for the allocator component
(fixed by implementing relabeling earlier so it returns less data),
unstable conversion from cumulative to delta models
(use consistent-hashing allocation,
ongoing discussion for [conversion drops](https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/20770)).
But it seems to mostly work fairly reliably at this point.

#### _data_ model

I think the biggest issue has been the very different data models:
we're going from pull to push, cumulative to delta.
This forces a stateful conversion in our network,
which inherently won't have all the state to do it losslessly.

And finally, what I can only describe as datadog's anemic query and graphing functionality
has been a consistent source of pain.
