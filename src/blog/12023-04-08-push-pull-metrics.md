# push and pull metrics

metrics from A to B

## who should send the metrics

### _push_ vs pull metrics

Metrics, a snapshot view of counters and guages representing an aggregated state of a system.
Implementing it comes with a big debate of do you push or pull your metrics from a collector,
and do you use cumulative or delta temporality in aggregating your data.

Prometheus have a nice doc further elaborating on decisions,
especially wrt to Prometheus / OpenTelemetry
[Promteheus / OTLP](https://docs.google.com/document/d/1hn-u6WKLHxIsqYT1_u6eh94lyQeXrFaAouMshJcQFXs/edit?usp=sharing).

#### _dimensions_

##### _push_ vs pull

###### _push_

- metrics producer is responsible for sending metrics
- producer in full control over temporal resolution
- harder for receivers to load balance / shed
- no exposed endpoints for producer
- ability to flush on exit

###### _pull_

- any number of receivers without change
- receiver in control over distributing load
- requires service discovery
- creates an implicit check

##### _delta_ vs cumulative

###### _delta_

- producer retains minimal state / no historical values
- sensitive to loss of intermediate samples

###### _cumulative_

- requires smarter query functions
- hard to reliably convert to delta after the fact
