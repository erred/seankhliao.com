# Serving helm charts in s3 with envoy

## replacing chartmuseum with envoy

### _helm_ charts from AWS S3 with envoy

So this quarter's big goal was finops,
and someone came up with the excellent `:nerdsnipe:` of:
"our s3 bucket we use to serve helm charts costs us $20k / month".
First off: wtf.
Second: this looks like an easy win.

#### _chartmuseum?_

We publish helm charts using [helm-s3](https://github.com/hypnoglow/helm-s3)
to an S3 bucket,
and serve them locally in-cluster with [chartmuseum](https://chartmuseum.com/).
So what could be wrong?

Turns out that chartmuseum dynamically generates its `index.yaml` on every request,
we've disabled writing back generated indexes,
and set a very low cache time,
so every time, chartmuseum downloads the entire bucket to generate a new `index.yaml`.
This also meant that our runbooks for yanking a published chart version,
and our ci processes of `helm s3 reindex` was wrong,
since that modified a stored `index.yaml` that wasn't used.

Thinking some more,
I realized we didn't need dynamic index generation,
and we weren't using any of chartmuseum's features besides turning http calls into S3 API calls.
I could easily replace this with something much simpler.
And so I wrote up an envoy config (see below).

#### _mystery_

The next day,
as I prepared to roll out my envoy config,
I noticed that our request volume to the bucket had dropped off a cliff since the previous afternoon,
but there was still a high baseline.
As far as I knew, nothing had changed:
no chartmuseum config changes in the last month,
ArgoCD was last changed a week ago,
and deployment script changes were just adding logging.
We have a mystery on our hands.

Thankfully, another engineer had looked into our bucket costs a month ago,
and turned on S3 Server Access Logs,
so I went ahead and dumped 3 days of logs to compare (this took forever....).
First, verify who was making the calls: it was the IAM User for chartmuseum.
Second, a peek at their User Agent: it went from `aws-sdk-go v1.37.28` to `aws-sdk-go v1.44.288`,
which was version upgrade we did, but should have rolled out a month ago.
This was suspicious.
Looking at one of our dev clustres, nothing seemed amiss: the upgrade happened a month ago as expected.
Looking at one of our prod clusters, I noticed the rollout happened when our requests dropped.
I looked into our CI pipeline and saw: our upgrade rolled out to dev,
but there was a manual approval for prod deployments,
and nobody clicked approve until recently (a month after the dev rollout...).
So that was one mystery solved.

But we still had `aws-sdk-go v1.37.28` requests even after everything was supposedly upgraded.
The next field I had was the source IP addresses in the access logs.
Poking around a bit, I realized it was the NAT gateways for one of our dev clusters.
Did I have phantom pods running somewhere?
I looked everywhere but didn't see anything.
Running out of ideas, I logged into the AWS Console, opened the EC2 dashboard,
and was greeted with a suspiciously high number of instances.
Looking at the instance groupds,
I realized we had a second cluster running,
part of a failed experiment with blue-green cluster upgrades.
Oh.
That's where the requests were coming from.
I quizzed the team on their plans for the cluster (kill it off later),
and upgraded chartmuseum in there.

#### _envoy_

So, that envoy config.
Using envoy versions 1.26 - 1.28
with the key being the
[AwsRequestSigning](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/aws_request_signing_filter)
and [CacheFilter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/cache_filter).
`RFCF` (Response From Cache Filter) in the access log response flags indicated a cache hit.

```yaml
admin:
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 8081

static_resources:
  listeners:
    - address:
        socket_address:
          address: 0.0.0.0
          port_value: 8080
      filter_chains:
        - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: charts
                access_log:
                  - name: envoy.access_loggers.stdout
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
                http_filters:
                  - name: envoy.filters.http.cache
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.cache.v3.CacheConfig
                      typed_config:
                        "@type": type.googleapis.com/envoy.extensions.http.cache.file_system_http_cache.v3.FileSystemHttpCacheConfig
                        manager_config:
                          thread_pool:
                            thread_count: 1
                        cache_path: /tmp/envoy-cache
                        max_cache_size_bytes: 2147483648 # 2 GiB
                  - name: envoy.filters.http.aws_request_signing
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.aws_request_signing.v3.AwsRequestSigning
                      service_name: s3
                      region: SOME_AWS_REGION
                      use_unsigned_payload: true
                      host_rewrite: SOME_BUCKET_NAME.s3.SOME_AWS_REGION.amazonaws.com
                      match_excluded_headers:
                        - prefix: x-envoy
                        - prefix: x-forwarded
                        - exact: x-amzn-trace-id
                  - name: envoy.filters.http.router
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
                route_config:
                  name: s3
                  virtual_hosts:
                    - name: all
                      domains:
                        - "*"
                      routes:
                        # don't cache index
                        - match:
                            path: /index.yaml
                          route:
                            cluster: s3_clusters
                        # don't cache dev charts
                        - match:
                            safe_regex:
                              google_re2: {}
                              regex: ".*-dev-.*"
                          route:
                            cluster: s3_clusters
                        # cache everything else
                        - match:
                            prefix: /
                          route:
                            cluster: s3_clusters
                          response_headers_to_add:
                            - header:
                                key: Cache-Control
                                value: max-age=86400 # 1 day
                              append_action: OVERWRITE_IF_EXISTS_OR_ADD

  clusters:
    - name: s3_clusters
      type: LOGICAL_DNS
      connect_timeout: 5s
      dns_lookup_family: V4_ONLY
      load_assignment:
        cluster_name: s3_cluster
        endpoints:
          - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: SOME_BUCKET_NAME.s3.SOME_AWS_REGION.amazonaws.com
                      port_value: 443
      transport_socket:
        name: envoy.transport_sockets.tls
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
```
