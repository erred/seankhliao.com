# go net/http server timeouts

## don't blindly copy the timeouts...


### _net/http_ Server

[Go](https://go.dev/)'s
[net/http.Server](https://pkg.go.dev/net/http#Server)
can be considered a production grade and suitable to exposing to the internet.
There are, of course, several settings you may want to change,
namely timeouts and crypto.

Filippo Valsorda has a few posts on that from a few years back:
on timeouts
[short](https://words.filippo.io/the-complete-guide-to-go-net-http-timeouts/)
[full](https://blog.cloudflare.com/the-complete-guide-to-golang-net-http-timeouts/),
[on everything](https://blog.gopheracademy.com/advent-2016/exposing-go-on-the-internet/).

#### _Who_ your clients are

So I read through those,
set some timeouts as suggested,
and didn't think too much about it.
Later, I moved the servers behind a reverse proxy, [envoy](https://www.envoyproxy.io/),
and everything worked fine.
A few days later, I added health probes every 10 seconds.

> error: unexpected status: 503 Service Unavailable
> body: upstream connect error or disconnect/reset before headers. reset reason: connection termination

Both envoy and my go server are on the same machine, so the network can't be flaky,
so something's wrong, and after thinking about it,
I realised this was the `net/http.Server.IdleTimeout` kicking in.
Envoy maintains a connection pool to the upstream,
but not every connection gets used before the `IdleTimeout` is up and reset,
so occasionally, stale connections in the pool get killed,
and envoy only realises when it tries to use them.

In this situation,
with a trusted downstream (envoy) that has its own timeouts for dealing with untrusted clients,
we can just not set the `IdleTimeout` and keep the connections around for longer.


#### _Diagram_ updated

Anyway, here's a diagram of the timeouts,
a few more control points have become available since Filippo's posts.

![net/http timeouts](/static/http-timeouts.svg)
