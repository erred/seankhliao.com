# Reading ServiceMonitors in OpenTelemetry

## Finally something that's not Prometheus

### ServiceMonitors with Prometheus

[ServiceMonitors](https://doc.crds.dev/github.com/prometheus-operator/prometheus-operator/monitoring.coreos.com/ServiceMonitor/v1@v0.58.0)
are CRDs deployed as part of 
[Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator).
They allow each service to define their own scrape configs as a dedicated Kubernetes resource,
giving them more control than just the usual scheme/port/path annotations,
such as over TLS, interval, relabelling, etc.

The Operator then discovers all the ServiceMonitors,
injects some standard relabellings, and generates a massive prometheus config file.
Prometheus reloads its config, and goes on its merry way.

Note here, the Operator needs access to Kubernetes to read ServiceMonitors,
and Prometheus also needs access to Kubernetes to discover the Pods behind the Services referenced by ServiceMonitors.

#### OpenTelemetry Collector

[OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector)'s
[prometheus receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/prometheusreceiver)
reuses the scraping code directly from [Prometheus](https://github.com/prometheus/prometheus).
This means it has access to all the usual prometheus service discovery options for scraping.
But that's not enough,
Prometheus itself doesn't read ServiceMonitors,
and the way the Prometheus Operator interfaces with Prometheus (generate config file and reload)
isn't compatible with the OpenTelemetry Collector
(prometheus receiver config is inlined, `$` needs escaping to `$$`, no hot reload).

##### Target Allocator

Instead, it takes a different approach:
a [target allocator](https://github.com/open-telemetry/opentelemetry-operator/tree/main/cmd/otel-allocator)
is responsible for all the communication with kubernetes
(reading ServiceMonitors, discovering actual pods behind Services).
It serves up the results to the collector's prometheus receiver over the 
[HTTP SD](https://prometheus.io/docs/prometheus/latest/http_sd/) mechanism (JSON describing each target).
The OpenTelemetry Collector just needs scrape the targets returned in the list.

Following this approach, sharding becomes possible,
and also changing the allocation strategy is much easier
since its a separate component.
Though it does come with a slight disadvantage that it may be easier for the cached target list
and the available pods to go out of sync.

And all this works as of:
- [OpenTelemetry Collector v0.62.1](https://github.com/open-telemetry/opentelemetry-collector-releases/releases/tag/v0.62.1)
- [OpenTelemetry Operator v0.61.0](https://github.com/open-telemetry/opentelemetry-operator/releases/tag/v0.61.0)
- [Target Allocator 0.60.0](https://github.com/open-telemetry/opentelemetry-operator/pkgs/container/opentelemetry-operator%2Ftarget-allocator/46443109?tag=0.60.0)
