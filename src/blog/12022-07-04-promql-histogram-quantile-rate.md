# promql histogram_quantile and rate

## is the rate necessary?

### _histogram_quantile_

[PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics/),
the query language for [prometheus](https://prometheus.io/),
has a [`histogram_quantile`](https://prometheus.io/docs/prometheus/latest/querying/functions/#histogram_quantile)
function to calculate φ-quantiles from a histogram.
Or in other words, estimate where a particular quantile was from your partially aggregated data.

All the examples show it used like: `histogram_quantile(0.99, rate(some_metric_query_bucket[5m]))`,
and someone asked: is the `rate()` necessary?

#### _refreshers_

Let's start from basics

##### _vector_ refresher

Prometheus records data in time series.
An _instant-vector_ gives you a single data point per timestamp, per time series:

```
time (min)  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
metric_one  1  1  2  2  4  4  8  8  8  8 16 16 32 32 64 64
```

A _range-vector_ gives you a slice of data (covering the lookback period up to now),
for each point in time. For the above with a range of 2:

```
time (min)       0     1       2       3       4       5       6       7      8       9        10        11         12         13         14         15
metric_one[2m] [1] [1 1] [1 1 2] [1 2 2] [2 2 4] [2 4 4] [4 4 8] [4 8 8] [8 8 8] [8 8 8] [8 8 16] [8 16 16] [16 16 32] [16 32 32] [32 32 64] [32 64 64]
```

##### _rate_ refresher

`rate()` takes a range vector,
and calculates a per second average increase over the time period,
eg, for a given range `[8 16 16]`,
the increase is `8` over `2m` (`120s`),
giving a rate `8 / 120` = approx. `0.67`.

```
time (min)           0     1     2     3     4     5     6     7     8     9    10    11    12    13    14    15
rate(metric_one[2m]) 0     0 0.008 0.008 0.017 0.017 0.033 0.033     0     0 0.067 0.067 0.133 0.133 0.267 0.267
```

##### _histograms_ refresher

The histograms produced by prometheus are a collection of counters,
each having a `le` label denoting bucket boundaries,
recording the count up to now (monotonic over time)
and up to `le` in size (monotonic over the buckets).

```
time (min)                   0  1  2  3  4  5
metric_two_bucket{le="10"}   0  1  1  4  4  4
metric_two_bucket{le="50"}   0  1  2  6  6  8
metric_two_bucket{le="100"}  0  2  3  7  7  9
metric_two_bucket{le="+Inf"} 0  2  4  8  8 10
---
represents the following events:
time (min)                   0  1  2  3  4  5
0 - 10                       0  1  0  3  0  0
10 - 50                      0  0  1  1  0  2
50 - 100                     0  1  0  0  0  0
100 - Inf                    0  0  1  0  0  0
```

##### _histogram_quantile_ refresher

For a given instant, `histogram_quantile`
looks at the increases between buckets to get a distribution of events.
It then calculates the quantile from this distribution,
interpolating if necessary.

ref: [quantile.go](https://github.com/prometheus/prometheus/blob/26117fc8850f36d6018b01c54d84df16859467e9/promql/quantile.go#L119)

```
metric_two_bucket{le="10"}    40     40
metric_two_bucket{le="50"}    80  -> 40
metric_two_bucket{le="100"}   90     10
metric_two_bucket{le="+Inf"} 100     10
---
quantile = 0.85 sits between bucket 2 and 3,
so: bucket_2_bound + (bucket_3_bound - bucket_2_bound) * (quantile * all_events - bucket_2_events) / events_in_bucket)
so:        50      + (      100      -       50      ) * (  0.85   *    100     -       80       )  / (90-80)          = 75
```

From here, we can see that the absolute value of the buckets don't matter,
only their relative sizes.

#### _is_ rate necessary?

`histogram_quantile` has no intrinsic requirement that the argument passed to is has passed through `rate`,
it will happily calculate the quantile for any set of buckets represented by instant vectors.
For most histograms, that means a quantile representing over all of the data.

However, in most cases, we'll want `rate` or `increase`,
bounding our quantile calculations to fresh data.
`rate(metric_three_bucket[2m])` gives us the increase over the last 2 mins,
meaning our quantile calculations are for all the requests in the past 2 mins,
rather than for all of time.
