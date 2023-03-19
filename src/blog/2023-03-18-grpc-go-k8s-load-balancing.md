# gRPC Go Kubernetes Load Balancing

## streams and stuff

### _load_ balancing with gRPC in Kubernetes

Scenario:
client and server both in kubernetes,
client is given a DNS address for it to connect to the servers.
Server pods may be cycled and scaled up/down.

#### _http/1.1_

##### _http_ background

So in HTTP/1.1 is fairly simple:
open a TCP connection, write your payload across.
If you need to make HTTP requests in parallel, 
open more TCP connections.

##### _http1_ in Go

Go's net/http implementation doesn't cache name resolution
(mapping DNS names to IP addresses),
but does maintain a connection pool.
This generally results in connections being cycled 
as connections exceed the pool size,
or they hit the idle timeout and are closed.
New connections are made on-demand, re-resolving names to addresses,
and picking a random one.

##### _http1_ in k8s

As server Pods in K8s come and Go,
this system generally works well with the Service objects,
both in ClusterIP and headless mode.
In ClusterIP mode, as connections are created, 
the CNI (or kube-proxy) will assign the connection to a random backend,
while in headless mode, 
the lack of DNS caching means a new choice is made every time with an up to date list of backends.

#### _gRPC_

##### _gRPC_ background

gRPC is based on HTTP/2,
which introduces substreams within a single TCP connection.
This allows parallel requests to utilizie the same underlying TCP connection.

##### _gRPC_ in Go

The grpc-go implementation uses its own implementations 
for both name resolution and load balancing (connection pooling).

[gRPC Name Resolution] is the canonical doument for how things should work.
Reality is a bit different.
grpc-go [defaults to `passthrough`] as the name resolver.
`passthrough` resolves names to addresses [once on Dial], then never again.
The `dns` resolver has the ability to [update the list] of resolved addresses,
but this is only triggered on connection failure.
It also has a 30s minimum update frequency.

[grpc name resolution]: https://github.com/grpc/grpc/blob/master/doc/naming.md
[defaults to `passthrough`]: https://github.com/grpc/grpc-go/blob/master/resolver/resolver.go#L39
[once on Dial]: https://github.com/grpc/grpc-go/blob/master/internal/resolver/passthrough/passthrough.go#L41
[update the list]: https://github.com/grpc/grpc-go/blob/master/internal/resolver/dns/dns_resolver.go#L209

##### _gRPC_ in k8s

So `passthrough` with ClusterIP might work,
if gRPC tries to re-establish TCP connections and leaves it to the CNI to assign it to a pod.
But this leaves gRPC unaware of multiple possible backends.
and it would just send all its traffic over a single connection.

`passthrough` with headless services doesn't work,
since the list is never updated.

`dns` with ClusterIP has the same issue of it being unaware of multiple possible backends.

`dns` with headless services' main issue is
name re-resolution only happens on connection failure.
Spinning up new pods to spread load won't work as they're never discovered by clients,
and in a full cycle of server pods, if they're not all ready by the time the clients try to connect,
load will be unevenly spread.

#### _what_ to do?

##### _better_ resolver

[kuberesolver] is an implementation that hooks directly into kubernetes API to watch
Endpoint objects (backing Service objects),
updating the gRPC target pool in real time,
leaving the load balancing to gRPC's native load balancers.

[kuberesolver]: https://github.com/sercand/kuberesolver

opentelemetry-collector's [loadbalancingexporter] takes a different approach
and re-resolves targets on a timer, 
maintaining a pool of gRPC conns to load balance between on the application level.

[loadbalancingexporter]: https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/loadbalancingexporter/loadbalancer.go

gRPc in theory also supports the xDS protocol for making the client smart / aware of backend changes,
if you implement an appropriate control server.

##### _load_ balancer

Slightly overloaded term, but running a L7 gRPC aware load balancer can help
(or in other words, make it someone else's problem).
But not one of those that lives in cluster, 
as you'll have the same issue of balancing traffic to the load balancer pods,
unless you think not having to deserialize requests gives you enough performance headroom.

##### _service_ mesh?

So like a load balancer, but put it closer to the application.
A node level daemonset might make use of internaltrafficpolicy to present a consistent IP address,
but handle each node locally,
while sidecars handle it locally to the pod.

It doesn't even need to be a big generic mesh like Istio or LinkerD,
it could just be an application specific deployment.
