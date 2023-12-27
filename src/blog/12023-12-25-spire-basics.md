# spire basics

## spiife / spire getting started

### _spire_ basic go app

Here's a basic Go app, running in k8s with siffe / spire.
It's basically a stripped down version of
[github.com/spiffe/go-spiffe/v2/examples/spiffe-http/client](https://pkg.go.dev/github.com/spiffe/go-spiffe/v2@v2.1.6/examples/spiffe-http/client).

#### _setup_

Install spire server, and agent.

Register a workload for spire agent:

```sh
$ kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://liao.dev/ns/spire/sa/spire-agent \
    -selector k8s_psat:cluster:ihwa \
    -selector k8s_psat:agent_ns:spire \
    -selector k8s_psat:agent_sa:spire-agent \
    -node
```

Register workloads for our test server / client

```sh
$ kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://ihwa.liao.dev/ns/default/sa/test-server \
    -parentID spiffe://ihwa.liao.dev/ns/spire/sa/spire-agent \
    -selector k8s:ns:default \
    -selector k8s:sa:test-server
$ kubectl exec -n spire spire-server-0 -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://ihwa.liao.dev/ns/default/sa/test-client \
    -parentID spiffe://ihwa.liao.dev/ns/spire/sa/spire-agent \
    -selector k8s:ns:default \
    -selector k8s:sa:test-client
```

#### _server_

[go-spiffe](https://pkg.go.dev/github.com/spiffe/go-spiffe/v2)
has a bunch of packages,
but the one we're interested in is [workloadapi](https://pkg.go.dev/github.com/spiffe/go-spiffe/v2/workloadapi)
which can talk to the socket from the agent.

The cert from the client is in PeerCertificates as the only URI entry.
VerifiedChains is not populated.

```go
package main

import (
        "context"
        "fmt"
        "io"
        "log"
        "net/http"

        "github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
        "github.com/spiffe/go-spiffe/v2/workloadapi"
)

func main() {
        http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
                fmt.Println("peer", r.TLS.PeerCertificates[0].URIs[0].String()) // peer spiffe://ihwa.liao.dev/ns/default/sa/test-client
                io.WriteString(w, "hello world")
        })

        ctx := context.Background()
        // uses SPIFFE_ENDPOINT_SOCKET by default
        source, err := workloadapi.NewX509Source(ctx)
        if err != nil {
                log.Fatalln("spiffe source:", err)
        }
        defer source.Close()
        server := &http.Server{
                Addr:      ":8443",
                TLSConfig: tlsconfig.MTLSServerConfig(source, source, tlsconfig.AuthorizeAny()),
        }

        log.Println("starting")
        log.Fatalln(server.ListenAndServeTLS("", ""))
}
```

manifest:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: test-server
spec:
  ports:
    - name: https
      port: 443
      targetPort: https
  selector:
    app: test-server
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-server
spec:
  selector:
    matchLabels:
      app: test-server
  template:
    metadata:
      labels:
        app: test-server
    spec:
      serviceAccountName: test-server
      containers:
        - name: app
          image: ko://go.seankhliao.com/testrepo0477/server
          env:
            - name: SPIFFE_ENDPOINT_SOCKET
              value: unix:///run/spire/sockets/agent.sock
          ports:
            - name: https
              containerPort: 8443
          volumeMounts:
            - name: spire-agent-socket
              mountPath: /run/spire/sockets
              readOnly: true
      volumes:
        - name: spire-agent-socket
          hostPath:
            path: /run/spire/sockets
            type: Directory
```

#### _client_

Almost a copy of server

```go
package main

import (
        "context"
        "fmt"
        "io"
        "log"
        "net/http"
        "os"
        "time"

        "github.com/spiffe/go-spiffe/v2/spiffetls/tlsconfig"
        "github.com/spiffe/go-spiffe/v2/workloadapi"
)

func main() {
        ctx := context.Background()
        source, err := workloadapi.NewX509Source(ctx)
        if err != nil {
                log.Fatalln("spiffe source:", err)
        }
        defer source.Close()

        tlsConfig := tlsconfig.MTLSClientConfig(source, source, tlsconfig.AuthorizeAny())
        client := &http.Client{
                Transport: &http.Transport{
                        TLSClientConfig: tlsConfig,
                },
        }

        log.Println("starting client loop")
        for range time.NewTicker(5 * time.Second).C {
                func() {
                        r, err := client.Get("https://test-server")
                        if err != nil {
                                log.Fatalln("get from server", err)
                        }
                        defer r.Body.Close()
                        fmt.Println("\npeer", r.TLS.PeerCertificates[0].URIs[0].String()) // peer spiffe://ihwa.liao.dev/ns/default/sa/test-server
                        io.Copy(os.Stdout, r.Body)
                }()
        }
}
```

manifest:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test-client
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-client
spec:
  selector:
    matchLabels:
      app: test-client
  template:
    metadata:
      labels:
        app: test-client
    spec:
      serviceAccountName: test-client
      containers:
        - name: app
          image: ko://go.seankhliao.com/testrepo0477/client
          env:
            - name: SPIFFE_ENDPOINT_SOCKET
              value: unix:///run/spire/sockets/agent.sock
          volumeMounts:
            - name: spire-agent-socket
              mountPath: /run/spire/sockets
              readOnly: true
      volumes:
        - name: spire-agent-socket
          hostPath:
            path: /run/spire/sockets
            type: Directory
```
