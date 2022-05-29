# promql notes

## who invented this... thing

### _PromQL_

[PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics/),
the query language for [Prometheus](https://prometheus.io/).

It is... not as intuitive as one would hope for such a widely used
monitoring system.

#### _aside:_ Google MQL

Google's [Monitoring Query Language](https://cloud.google.com/monitoring/mql)
makes much more sense:
select metric, pipe it to alignment / aggregations, output result.
I honestly think it's worth the read to get a grasp on the data model
and how time series things work.

#### _promql_ concepts

Data is stored in _time series_ uniquely identified by name + all labels,
with 1 data point per timestamp.

##### _instant_ vector

Multiple time series together form a instant vector

```
# a plain metric query results in an instant vector
http_server_requests_total

# these can be narrowed down with label sectors
http_server_requests_total{host="seankhliao.com"}


# example of values for 2 time series
time:               0  1  2  3  4  5  6  7  8  9 10
{host="a.example"}: 1  1  1  2  4  9 11 11 12 12 20
{host="b.example"}: 0  0  0  4  5  6  6  6  7  8  8
```

Time series in an instant vector can be aggregated through
[aggregation operators](https://prometheus.io/docs/prometheus/latest/querying/operators/#aggregation-operators).

##### _range_ vector

Like an instant vector but each timestamp
contains the values from that point + all points going back a set duration.
Most aggregations [functions](https://prometheus.io/docs/prometheus/latest/querying/functions/)
that downsample data take these.

If it were any more consistent,
all the functions taking a range vector would be `<aggregation>_over_time` like these:
[aggregation_over_time](https://prometheus.io/docs/prometheus/latest/querying/functions/#aggregation_over_time)
Which collapses an range vector back to an instant vector
but doesn't aggregate across time series.

```
http_server_requests_total[2m]

# lookback of 2 for the previous example
time:                 0       1       2       3       4       5       6       7       8       9      10
{host="a.example"}: [1]   [1 1]   [1 1]   [1 2]   [2 4]   [4 9]  [9 11] [11 11] [11 12] [12 12] [12 20]
{host="b.example"}: [0]   [0 0]   [0 0]   [0 4]   [4 5]   [5 6]   [6 6]   [6 6]   [6 7]   [7 8]   [8 8]
```

##### _alignment_

Note in the above,
there's nothing specifying how frequently to output a data point.
This is the `step` parameter in an api call
and is usually calculated automatically or specified separately.
Within a step, prometheus looks back up to 5 minutes to find a data point.
This can be problematic,
as your data points might get dropped (reasons why prometheus prefers counters over guages)
or misaligned with the source, leading some data points to appear more than others.

_note:_ make sure `rate()` or other `_over_time` ranges are larger than `step`.

##### _subquery_

background: [composing range vectors](https://www.robustperception.io/composing-range-vector-functions-in-promql)

Subqueries are confusing things,
they turn an instant query (not vector) into a range vector.

```
rate(http_requests_total[5m])[30m:1m]
```

- `rate(http_requests_total[5m])`:
  For every input timestamp:
  look back 5 min, calculate the rate,
  output a single value.

- `[30m:]`:
  Each input timestamp covers the last 30 min.

- `[...:1m]`: Evaluate every 1 min.

So together:
For each input timestamp:
look back 30 min, every 1 min within that, look back 5 min and calculate the rate.
This results in a range vector where every timestamp contains a vector of 30 (30/1) values.

##### _recording_ rules

When do you want to use these?
As alluded to above, mostly to precalculate `rate` on counter metrics,
ex: [kube-prometheus rules](https://github.com/prometheus-operator/kube-prometheus/blob/main/manifests/kubernetes-prometheusRule.yaml).

Note: guidance on [naming rules](https://prometheus.io/docs/practices/rules/): `level:metric:operations`
