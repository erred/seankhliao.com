# k8s leaderelection

## follow the leader

### _leader_ election

So you want to run a high availability service,
but your code can only really handle having a single instance do the critical work.
What do you do?
You run multiple replicas, choosing one to be the leader to do the critical sections.

Now you could implement [raft], [paxos], or something else yourself,
but if you're running in [kubernetes],
there's a ready made [Lease] resource,
and [leaderelection] libraries to use.

#### _manifests_

We need a service account to attach permissions to

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test-leader
```

The [leaderelection] library will create and update the [Lease]s on demand

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: test-leader
rules:
  - apiGroups:
      - coordination.k8s.io
    resources:
      - leases
    verbs:
      - "*"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: test-leader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: test-leader
subjects:
  - kind: ServiceAccount
    name: test-leader
```

We need to run our pods.
3 replicas so we actually see the effects of leader election.
We inject `POD_NAME` as a unique identity

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-leader
spec:
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: test-leader
  template:
    metadata:
      labels:
        app.kubernetes.io/name: test-leader
    spec:
      serviceAccountName: test-leader
      containers:
        - name: leader
          image: go.seankhliao.com/test-leaderelection/cmd/leader
```

#### _code_

Now for actual code:

```go
package main

import (
        "context"
        "os"
        "time"

        metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
        "k8s.io/client-go/kubernetes"
        "k8s.io/client-go/rest"
        "k8s.io/client-go/tools/leaderelection"
        "k8s.io/client-go/tools/leaderelection/resourcelock"
        "k8s.io/klog/v2"
)

func main() {
        // setup client to talk to api server using service account credentials
        restConfig, err := rest.InClusterConfig()
        if err != nil {
                klog.ErrorS(err, "get rest config")
                os.Exit(1)
        }
        client, err := kubernetes.NewForConfig(restConfig)
        if err != nil {
                klog.ErrorS(err, "get rest client")
                os.Exit(1)
        }

        // get a unique identity for ourselves
        hostname, err := os.Hostname()
        if err != nil {
                klog.ErrorS(err, "get hostname")
                os.Exit(1)
        }

        ctx := context.Background()
        ctx, cancel := context.WithCancel(ctx)


        // runs in a leader election loop
        // panics on failure
        leaderelection.RunOrDie(ctx, leaderelection.LeaderElectionConfig{
        // this is the lease we create/update if we win the leader
                Lock:            &resourcelock.LeaseLock{
                LeaseMeta: metav1.ObjectMeta{
                        Namespace: "default",
                        Name:      "test-lease",
                },
                Client: client.CoordinationV1(),
                LockConfig: resourcelock.ResourceLockConfig{
                        Identity: hostname,
                },
        },
                // recommended defaults
                LeaseDuration:   15 * time.Second,
                RenewDeadline:   10 * time.Second,
                RetryPeriod:     2 * time.Second,
                // TODO, ensure exit from critical work before canceling context
                ReleaseOnCancel: true,
                Callbacks: leaderelection.LeaderCallbacks{
                        // main work should happen here
                        OnStartedLeading: func(ctx context.Context) {
                                dur := 5 * time.Second
                                klog.InfoS("leading", "tick_dur", dur)
                                tick := time.NewTicker(dur)
                                defer tick.Stop()
                        leadLoop:
                                for {
                                        select {
                                        case <-tick.C:
                                                klog.InfoS("still leading")
                                        case <-ctx.Done():
                                                klog.InfoS("leading cancelled")
                                                break leadLoop
                                        }
                                }
                        },
                        OnStoppedLeading: func() {
                        // TODO: ensure work loop exit before canceling leaderelection ctx
                                cancel()
                                klog.InfoS("stopped leading")
                        },
                        OnNewLeader: func(identity string) {
                        // just notifications
                                klog.InfoS("new leader", "id", identity)
                        },
                },
        })
}
```

#### _deploy_

And a simple [skaffold] config to deploy into a [kind] cluster

```yaml
apiVersion: skaffold/v4beta1
kind: Config
metadata:
  name: test-leader
build:
  artifacts:
    - image: go.seankhliao.com/test-leaderelection/cmd/leader
      ko:
        main: ./cmd/leader
  local:
    push: false
  tagPolicy:
    sha256: {}
manifests:
  rawYaml:
    - deploy/manifests/*
deploy:
  kubectl: {}
  kubeContext: kind-kind
  logs:
    prefix: podAndContainer
```

#### _run_ logs

```sh
$ skaffold run --tail
Generating tags...
 - go.seankhliao.com/test-leaderelection/cmd/leader -> go.seankhliao.com/test-leaderelection/cmd/leader:latest
Checking cache...
 - go.seankhliao.com/test-leaderelection/cmd/leader: Not found. Building
Starting build...
Found [kind-kind] context, using local docker daemon.
Building [go.seankhliao.com/test-leaderelection/cmd/leader]...
Target platforms: [linux/amd64]
Using base gcr.io/distroless/static:nonroot@sha256:bce851161342b0c9d19d0d56e3d37b4787cc6b53a164ec21432e0e1755d08e17 for go.seankhliao.com/test-leaderelection/cmd/leader
Using build config go.seankhliao.com/test-leaderelection/cmd/leader for go.seankhliao.com/test-leaderelection/cmd/leader
Building go.seankhliao.com/test-leaderelection/cmd/leader for linux/amd64
Loading go.seankhliao.com/test-leaderelection/cmd/leader:266dddc70cc019db6657b05dd884b16d59882f98947c1e2833dc5274cca5ecac
Loaded go.seankhliao.com/test-leaderelection/cmd/leader:266dddc70cc019db6657b05dd884b16d59882f98947c1e2833dc5274cca5ecac
Adding tag latest
Added tag latest
Build [go.seankhliao.com/test-leaderelection/cmd/leader] succeeded
Starting test...
Tags used in deployment:
 - go.seankhliao.com/test-leaderelection/cmd/leader -> go.seankhliao.com/test-leaderelection/cmd/leader:5963bd657b4fabc4e4dcb69b57ef08569e25a3b8df132c8c67339801cac25d9c
Starting deploy...
Loading images into kind cluster nodes...
 - go.seankhliao.com/test-leaderelection/cmd/leader:5963bd657b4fabc4e4dcb69b57ef08569e25a3b8df132c8c67339801cac25d9c -> Loaded
Images loaded in 1.455 second
 - deployment.apps/test-leader configured
 - role.rbac.authorization.k8s.io/test-leader configured
 - rolebinding.rbac.authorization.k8s.io/test-leader unchanged
 - serviceaccount/test-leader unchanged
Waiting for deployments to stabilize...
 - deployment/test-leader is ready.
Deployments stabilized in 3.068 seconds
Press Ctrl+C to exit
[test-leader-6d7766bbcc-8sddv leader] I0107 12:50:38.714950       1 leaderelection.go:248] attempting to acquire leader lease default/test-lease...
[test-leader-6d7766bbcc-8sddv leader] I0107 12:50:38.718334       1 main.go:76] "new leader" id="test-leader-7d76b8f7df-7m2x8"
[test-leader-6d7766bbcc-pdp5j leader] I0107 12:50:37.666586       1 leaderelection.go:248] attempting to acquire leader lease default/test-lease...
[test-leader-6d7766bbcc-pdp5j leader] I0107 12:50:37.671308       1 main.go:76] "new leader" id="test-leader-7d76b8f7df-7m2x8"
[test-leader-6d7766bbcc-r7qq8 leader] I0107 12:50:36.889879       1 leaderelection.go:248] attempting to acquire leader lease default/test-lease...
[test-leader-6d7766bbcc-r7qq8 leader] I0107 12:50:36.894878       1 main.go:76] "new leader" id="test-leader-7d76b8f7df-7m2x8"
[test-leader-6d7766bbcc-pdp5j leader] I0107 12:50:52.958867       1 leaderelection.go:258] successfully acquired lease default/test-lease
[test-leader-6d7766bbcc-pdp5j leader] I0107 12:50:52.958957       1 main.go:76] "new leader" id="test-leader-6d7766bbcc-pdp5j"
[test-leader-6d7766bbcc-pdp5j leader] I0107 12:50:52.958985       1 main.go:57] "leading" tick_dur="5s"
[test-leader-6d7766bbcc-8sddv leader] I0107 12:50:54.270478       1 main.go:76] "new leader" id="test-leader-6d7766bbcc-pdp5j"
[test-leader-6d7766bbcc-r7qq8 leader] I0107 12:50:54.749086       1 main.go:76] "new leader" id="test-leader-6d7766bbcc-pdp5j"
[test-leader-6d7766bbcc-pdp5j leader] I0107 12:50:57.959756       1 main.go:64] "still leading"
[test-leader-6d7766bbcc-pdp5j leader] I0107 12:51:02.960722       1 main.go:64] "still leading"
[test-leader-6d7766bbcc-pdp5j leader] I0107 12:51:07.959616       1 main.go:64] "still leading"
[test-leader-6d7766bbcc-pdp5j leader] I0107 12:51:12.959551       1 main.go:64] "still leading"
[test-leader-6d7766bbcc-pdp5j leader] I0107 12:51:17.959866       1 main.go:64] "still leading"
```

[raft]: https://en.wikipedia.org/wiki/Raft_(algorithm)
[paxos]: https://en.wikipedia.org/wiki/Paxos_(computer_science)
[kubernetes]: https://kubernetes.io/
[Lease]: https://kubernetes.io/docs/concepts/architecture/leases/
[leaderelection]: https://pkg.go.dev/k8s.io/client-go/tools/leaderelection
[skaffold]: https://skaffold.dev/
[kind]: https://kind.sigs.k8s.io/
