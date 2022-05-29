# kubelet standalone mode with containerd

## why use systemd when you can use kubelet?


### _kubelet_ standalone

[kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)
is the agent that runs on every node in kubernetes.
It also has a standalone mode where it just manages pods based on manifests on the filesystem.

There are not many guides out there, and most of them outdated with the deprecation of docker,
like [kelseyhightower/standalone-kubelet-tutorial](https://github.com/kelseyhightower/standalone-kubelet-tutorial),
[povilasv.me/raspberrypi-kubelet](https://povilasv.me/raspberrypi-kubelet/),
with the closest being [ops.tips](https://ops.tips/notes/standalone-kubelet-with-containerd/)
but it doesn't actually list out all the configs.

Anyway, I want kubelet and I want containerd.

#### _setup_

I'm on [Arch Linux](https://archlinux.org/),
so getting sou is an easy:

```
pacman -S containerd kubelet
```

There are some necessary settings:

```
cat << EOF > /etc/modules-load.d/br_netfilter.conf
br_netfilter
EOF

cat << EOF > /etc/sysctl.d/30-ipforward.conf
net.ipv4.ip_forward=1
net.ipv4.conf.lxc*.rp_filter=0
net.ipv6.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1
EOF
```

#### _containerd_

[containerd](https://containerd.io/)
is our container runtime of choice, and it needs some configuring:

```
cat << EOF > /etc/containerd/config.toml

# importart or else it defaults to v1
version = 2

[plugins."io.containerd.grpc.v1.cri".cni]

    # archlinux default
    bin_dir = "/usr/lib/cni"

    # how to configure pod networking
    conf_template = "/etc/cni/cni.template"
EOF
```

So [cni](https://www.cni.dev/docs/) config..
There's a [spec](https://www.cni.dev/docs/spec/)
which defines the config format.
And there's the default [plugins repo](https://github.com/containernetworking/plugins)
with the [online docs](https://www.cni.dev/plugins/current/).

You could drop the full config (with subnet already set) into the container cni `conf_dir`,
or you could have kubelet trigger its generation via `conf_template`.
Note, changing things won't force containerd to regenerate the config, delete it manually.

Basically, use [ptp](https://www.cni.dev/plugins/current/main/ptp/),
add [host-local](https://www.cni.dev/plugins/current/ipam/host-local/) as ipam
and chain a [portmap](https://www.cni.dev/plugins/current/meta/portmap/) after.
I couldn't get [bridge](https://www.cni.dev/plugins/current/main/bridge/) to work.

_note:_ kubernetes us [currently](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
on v0.4.0 of CNI spec, so some old style config (subnet) is needed

```
cat << EOF > /etc/cni/cni.template
{
  "name": "containerd",
  "cniVersion": "0.4.0",
  "plugins": [{
    "type": "ptp",
    "ipMasq": true,
    "ipam": {
      "type": "host-local",
      "subnet": "{{.PodCIDR}}",
      "routes": [
        {"dst": "0.0.0.0/0"}
      ]
    }
  },{
    "type": "portmap",
    "capabilities": {
      "portMappings": true
    }
  }]
}
EOF
```

#### _kubelet_

Currently on kubelet v1.21.3

Arch provides a systemd unit file for kubelet where args are passed via env defined in:

```
cat << EOF > /etc/kubernetes/kubelet.env
KUBELET_ARGS=--container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock --config /etc/kubernetes/kubelet.yaml
EOF
```

I'm going to not use deprecated flags and use a config file instead:

```
cat << EOF > /etc/kubernetes/kubelet.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  webhook:
    enabled: false
authorization:
  mode: AlwaysAllow
enableServer: false
logging:
  format: text
  sanitization: false
podCIDR: 10.241.1.0/24
staticPodPath: /etc/kubernetes/manifests
EOF
```

Now we can put a pod definition in `/etc/kubernertes/manifests/foo.yaml` and watch it run:

```
cat << EOF > /etc/kubernetes/manifests/httpbin.yaml
apiVersion: v1
kind: Pod
metadata:
  name: httpbin
spec:
  containers:
    - name: httpbin
      image: kennethreitz/httpbin
      ports:
        - name: http
          containerPort: 80
          hostPort: 45678
EOF
```
