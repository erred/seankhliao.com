# fly.io wireguard vpn server

## diy vpn server on wireguard

### _fly.io_ and wireguard

[fly.io](https://fly.io/) is a compute platform that runs your apps
from container images as micro vms on firecracker.
Their have docs on how their 
[private networking](https://fly.io/docs/reference/private-networking/)
uses wireguard,
and an interesting blog post on 
[embedding wireguard](https://fly.io/blog/ssh-and-user-mode-ip-wireguard/) into their CLI.

But what I want is a vpn server that will forward all my traffic,
not just access internal services on fly.io.
So, back to DIY then.
Fortunately, they do mention that their kernels are wireguard enabled.

#### _build_ the image

Let's start with a `Dockerfile`,
we'll want the wireguard tools and an script:

```dockerfile
FROM alpine

RUN apk update && \
    apk add --no-cache \
        wireguard-tools

COPY run.sh .
ENTRYPOINT [ "/run.sh" ]
```

And for our script:

```sh
#!/bin/sh

set -ex

# ip forwarding, not strictly necessary I think?
cat << EOF > /etc/sysctl.d/forward.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
EOF

sysctl -p /etc/sysctl.d/forward.conf

# wireguard config
cat << EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 192.168.100.4/24
ListenPort = 51820
PrivateKey = ${WIREGUARD_PRIVATE_KEY}

# NAT the clients, we don't allocate extra ip addresses for them
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE;iptables -A FORWARD -o %i -j ACCEPT
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE;iptables -D FORWARD -o %i -j ACCEPT

[Peer]
# eevee
PublicKey = ......
AllowedIPs = ......
EOF

# bring up wireguard
wg-quick up wg0

# never exit
while true; do
    wg show
    sleep 60
done
```

#### _deploy_ the app

We'll need the app definition

```toml
# choose a globally unique name
app = "app-name"

# build from our dockerfile
[build]
  dockerfile = "Dockerfile"

  # expose the wireguard port
[[services]]
  internal_port = 51820
  protocol = "udp"
  [[services.ports]]
    port = 51820
```

Some commands to setup the app:


```sh
$ flyctl apps create app-name
$ wg genkey | tee /dev/stderr | wg pubkey
$ flyctl secrets set WIREGUARD_PRIVATE_KEY=$first_line_from_previous_command
$ flyctl deploy
$ flyctl ips list
```

Then setup clients to connect

```ini
[WireGuardPeer]
PublicKey = ...
Endpoint = ...:51820
PersistentKeepalive = 30
AllowedIPs = ...
```
