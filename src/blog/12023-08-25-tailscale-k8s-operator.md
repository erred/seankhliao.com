# tailscale k8s operator

## private load balancers

### _tailscale_ k8s operator

For a few months,
I've been using [tailscale.com/tsnet](https://pkg.go.dev/tailscale.com/tsnet)
[as a library](https://pkg.go.dev/go.seankhliao.com/svcrunner/v2/tshttp),
like tailscale's [golinks blog post](https://tailscale.com/blog/golink/).
You just pass it a tailscale auth key,
and it can run anywhere (\* but you need a persistent state directory).
But I didn't like it for 2 reasons (actually a big one):
`tsnet` brought in a lot of dependencies that bloated the dependency graph
and slowed down the build,
plus there was a dependency on [gvisor.dev/gvisor](https://pkg.go.dev/gvisor.dev/gvisor)
which required extra care
(it's exported from a monorepo, you have to use a branch, it breaks sometime on go tip).

I was on the lookout for a new way to handle private web pages.
I thought about implementing a more zero-trust(?) style thing
with [WebAuthn](https://webauthn.io/) as a middleware layer
so I can log in using yubikeys and/or passkeys.
But I was never quite satisfied with the UI,
and it required persistence / accounts / keys and secret management.

Then I was made aware of tailscale's
[kubernetes operator](https://tailscale.com/kb/1236/kubernetes-operator/).
It watches for Services with `tyoe: LoadBalancer` and `spec.loadBalancerClass: tailscale`,
spinning up a proxy pod in the `tailscale` namespace to connect to the tailscale network
and forward traffic.
Easy, zero touch was of exposing services to the tailnet,
though it can be big slow to update on target pod rollouts.
Right now my problem is that it's a layer 4 (IP) LoadBalancer,
it doesn't do TLS termination so I'm stuck with http for the moment.
