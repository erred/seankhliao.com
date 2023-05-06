# tailscale funnel, secure grpc

more than just https

## grpc for all?

### _grpc_ secure through tailscale funnel

[Tailscale Funnel](https://tailscale.com/blog/introducing-tailscale-funnel/)
is a feature that lets you expose endpoints in you private tailnet (vpn) publicly
via Tailscale operated proxies that do SNI based routing.

[tsnet](https://pkg.go.dev/tailscale.com@v1.38.4/tsnet)
is their library to run your excutable as its own node,
so you can have a self contained binary that will
connect and register itself with the Tailscale control plane
and expose a stable endpoint.

tsnet recently gained a method [`ListenFunnel(network, addr string, opts ...FunnelOption) (net.Listener, error)`](https://pkg.go.dev/tailscale.com@v1.38.4/tsnet#Server.ListenFunnel),
which gives you a TLS-terminated [`net.Listener`](https://pkg.go.dev/net#Listener).
Good for HTTP,
less nice for something like the canonical gRPC library,
which wants to be in control over the TLS handshake.

Thankfully, we can look into the implementation for ListenFunnel,
and see it doesn't need anything that isn't publicly available.
So...

```go
package main

import (
        "context"
        "crypto/tls"
        "log"

        "github.com/sanity-io/litter"
        "google.golang.org/grpc"
        "google.golang.org/grpc/credentials"
        "google.golang.org/grpc/health"
        "google.golang.org/grpc/health/grpc_health_v1"
        "tailscale.com/ipn"
        "tailscale.com/tsnet"
)

func handle(msg, err) {
        if err != nil {
                log.Fatalln("up", err)
        }
}

func main() {
        ctx := context.Background()
        ts := &tsnet.Server{
                Ephemeral: true,
        }

        // start the server
        _, err := ts.Up(ctx)

        // get our FQDN
        doms := ts.CertDomains()

        // get a local client
        lc, err := ts.LocalClient()
        handle("get local client", err)

        // enable funnel
        sc = &ipn.ServeConfig{
                AllowFunnel: map[ipn.HostPort]bool{ipn.HostPort(doms[0] + ":443"): true},
        }
        err = lc.SetServeConfig(ctx, sc)
        handle("set serve config", err)

        // listen on the ip network, listener is TCP / unterminated TLS
        lis, err := ts.Listen("tcp", ":443")
        handle("listen", err)

        // simple grpc server with the healthcheck endpoint
        gs := grpc.NewServer(grpc.Creds(credentials.NewTLS(&tls.Config{
                // use the local client to get the certificate on demand
                GetCertificate: lc.GetCertificate,
        })))
        hs := health.NewServer()
        hs.SetServingStatus("foo", grpc_health_v1.HealthCheckResponse_SERVING)
        grpc_health_v1.RegisterHealthServer(gs, hs)

        // run the grpc server
        log.Println("serve")
        err = gs.Serve(lis)
        handle("grpc serve", err)
}
```

And of course, we can test it with
[grpc-health-probe](https://github.com/grpc-ecosystem/grpc-health-probe).
We can expect the initial requests to fail as it takes time to provision the cert,
which only happens on demand.

```sh
11:45:08 ~/tmp/grpc-health-probe 0:00:01
master » go run . -tls -addr testrepo0163.badger-altered.ts.net:443
timeout: failed to connect service "testrepo0163.abc-def.ts.net:443" within 1s
exit status 2

11:45:10 ~/tmp/grpc-health-probe 0:00:01
master » go run . -tls -addr testrepo0163.abc-def.ts.net:443
status: SERVING
```
