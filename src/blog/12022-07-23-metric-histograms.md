# metric histograms

## a bucket for all

### histograms

In observability/metrics, histograms are primarily used to record
distributions in a space efficient manner
that can be aggregated and summarized (usually with quantile measurements)
at a later point.

But how can you pull out something like the 99.9 percentile from a few buckets?
The answer is you can't.
What you can do is find the bucket it would land in
and attempt a (linear) interpolation between the bucket bounds
and generate an estimate.

#### _implementations_

So it becomes apparent that having more buckets gives you higher resolutions.
Now for a look at different implentations.

##### _prometheus_

[Prometheus](https://prometheus.io/)
essentially stores each bucket as its own time series with the bucket bounds recorded as labels.
This is quite innefficient and as a result, by default it only gives a few buckets,
which while it covers the common range for things like http request latency,
is subject to large error bars if the boundaries aren't close to the actual values
(which is what is interesting... the outlier events).

```go
DefBuckets = []float64{.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10}
```

##### _hdr_ histogram

[HDR-Histograms](http://hdrhistogram.org/)
based on [this analysis](http://www.david-andrzejewski.com/publications/hdr.pdf)
divides the space between a given `(min, max)` pair into exponential buckets (`2^x`),
then subdivides each bucket linearly.
This apprently scales to ~1800 buckets in a ~1500 byte packet?

In other places this is called "log linear bounds" (logarithmic big buckets, linear sub buckets).

##### _datatdog_ ddsketch

[DDSketch](https://www.vldb.org/pvldb/vol12/p2195-masson.pdf)
based on [this analysis](https://blog.acolyer.org/2019/09/06/ddsketch/)
also uses exponential buckets, but this time choosing a base that guarantees relative error.
For a 1% error, `(1+0.1) / (1-0.1) = 1.02`, and so buckets are chosen with `1.02^x`.
A fixed number of buckets are chosen,
and the starting buckets (lowest indices) are merged if it ever grows out of space.
Their [blog post](https://www.datadoghq.com/blog/engineering/computing-accurate-percentiles-with-ddsketch/)
mentions somewhere on the order of a few hundred buckets (eg 802 for ns~day scale),
with their implementation setting a default limit at 2048.

##### _google_

In a [comment on an opentelemetry histogram proposal](https://github.com/open-telemetry/opentelemetry-proto/pull/226#issuecomment-737496026)
Google said they use a `(base = minimum_base^2^compression)^x` for buckets.

##### _opentelemetry_ exponentialhistogram

After
[much](https://github.com/open-telemetry/opentelemetry-proto/pull/226)
[discussion](https://github.com/open-telemetry/oteps/pull/149)
opentelemetry [proposed](https://github.com/open-telemetry/oteps/blob/main/text/0149-exponential-histogram.md)
and finally [defined](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/data-model.md#exponentialhistogram)
their buckets with
`base = 2 ^ (2 ^ -scale)`.

There are apparently no hard limits on bucket count,
though the [go implementation](https://github.com/open-telemetry/opentelemetry-go/pull/3022)
chooses a default of 160 buckets,
adjusting scaling as necessary.

Implementations already exist in the form of:
[NrSketch](https://github.com/newrelic-experimental/newrelic-sketch-java)
[DynaHist](https://github.com/dynatrace-oss/dynahist/blob/main/src/main/java/com/dynatrace/dynahist/layout/OpenTelemetryExponentialBucketsLayout.java)

#### others

- [Circlhist](https://arxiv.org/abs/2001.06561)
- [Dynatrace Dynamic Histograms](https://github.com/dynatrace-oss/dynahist)
