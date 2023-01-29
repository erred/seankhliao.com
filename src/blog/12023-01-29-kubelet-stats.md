# kubelet stats

## is it deprecated? maybe

### _kubelet_ stats

Recently, we switched over to the [OpenTelemetry Collector]
for collecting metrics from Kubernetes.
One of the things we collect is container and pod level metrics from kubelet,
and it's complicated.

#### _current_ state

First, what do we have to work with?

##### _kubelet_

These are the endpoints exposed by kubelet
(test with `kubectl get --raw "/api/v1/nodes/$NODE_NAME/proxy/$ENDPOINT"`):

- `/metrics`: (prometheus) metrics about kubelet itself (go runtime, controller, http)
- `/metrics/cadvisor`: (prometheus) 
  metrics from an embedded [cAdvisor] instance about the node, pod, and containers
- `/metrics/probes`: (prometheus) histograms about container probes
- `/metrics/resource`: (prometheus) metrics from Container Runtime Interface (CRI)
- `/stats/summary`: (json) combined metrics from CRI and cAdvisor

##### _otelcol_

###### _kubeletstats_

The [kubeletstats] receiver would appear to be the primary receiver to use for collecting metrics from kubelet.
This reads data from `/stats/summary`.
It only works for a single kubelet though, which is fine if you run the collector as a daemonset,
but alternatively, 
you could use the [receivercreator] in combination with a [k8sobserver] to generate subreceivers for nodes.
Example:

```yaml
extensions:
  k8sobserver:
    observe_pods: false
    observe_nodes: true

receivers:
  receiver_creator:
  watch_observers:
    - k8sobserver
  receivers:
    kubeletstats:
      rule: type == "k8s.node"
      config:
        endpoint: '`endpoint`:`kubelet_endpoint_port`'
        extra_metadata_labels:
          - container.id
        metric_groups:
          - container
          - pod
          - node

exporters:
  logging:
    verbosity: detailed

service:
  extensions:
    - k8sobserver
  pipelines:
    metrics:
      receivers:
        - receiver_creator
      exporters:
        - logging
```

###### _prometheus_

Of course, you could just fall back to what prometheus has been doing all along:

```yaml
receivers:
    prometheus:
      config:
        scrape_configs:
          - job_name: k8s
            kubernetes_sd_configs:
              - role: node
            scheme: https
            metrics_path: /metrics/cadvisor
            tls_config:
              ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            authorization:
              credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
```

#### _future_ changes

Poke around enough on the internet and you might find references to
[Reduce the set of metrics exposed by the kubelet] and related proposals.

The current state is probably best descrrbed by [KEP-2371 cAdvisor-less, CRI-full Container and Pod Stats].
In short,
container runtimes still need direct integration with cAdvisor to expose metrics,
but cAdvisor doesn't run everywhere (ex. Windows, virtual machines),
and this breaks the CRI abstraction.
Instead, add support for extra metrics fields in CRI,
and reduce metrics cAdvisor will collect to just the node/host.
If you need extra metrics, run cAdvisor as a daemonset.

Of course, all this investigation comes from wanting 
`container_cpu_cfs_throttled_seconds_total` (or equivalent metric) from `/stats/summary`,
but that doesn't appear to be planned for CRI...

The above appears to still be in Alpha for Kubernetes 1.25,
so expect more to change.


[OpenTelemetry Collector]: https://opentelemetry.io/docs/collector/
[cAdvisor]: https://github.com/google/cadvisor
[kubeletstats]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/kubeletstatsreceiver
[receivercreator]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/receivercreator
[k8sobserver]: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/observer/k8sobserver
[Reduce the set of metrics exposed by the kubelet]: https://github.com/kubernetes/kubernetes/issues/68522
[KEP-2371 cAdvisor-less, CRI-full Container and Pod Stats]: https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/2371-cri-pod-container-stats
