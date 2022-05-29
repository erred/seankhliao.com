# systemd networkd notes

## notes on server network setup

### _networkd_ notes

So, I have a server with a single /32 ipv4 and a /64 ipv6.
And I want to use it as a hypervisor, and a vpn server.

#### _wlan_

Static external addresses

```
[Match]
Name=enp41s0

[Network]
Address=.../64
Gateway=fe80::1
Gateway=...
IPForward=yes

[Address]
Address=...
Peer=.../32
```

#### _wireguard_ vpn server

Wireguard peers

```
[NetDev]
Name = wg0
Kind = wireguard

[WireGuard]
PrivateKey = ...
# PublicKey = ...
ListenPort = 51820

# peer1
[WireGuardPeer]
PublicKey = ...
AllowedIPs = .../24,.../80
```

- Address subnets should be smaller to ensure the correct routes are chosen.
- `IPForward` controls the same thing as the `sysctl` settings (which is in kernel stuff)
- `IPMasquerade` everything leaving the system that originated from this interface gets masked

```
[Match]
Name=wg0

[Network]
Address=.../20
Address=.../72
IPForward=yes
IPMasquerade=ipv4
```

#### _bridge_ tap

A bridge with tap devices for vms...

```
[NetDev]
Name=qemu0
Kind=bridge
```

- same as above, choose subnet carefully
- `IPv4ProxyARP` is apparently important

```
[Match]
Name=qemu0

[Network]
Address=.../26
Address=.../88
IPForward=yes
IPv4ProxyARP=yes
```

For the individual tap devices

```
[Match]
Name=tapqemu*

[Network]
Bridge=qemu0
```

```
[NetDev]
Name=tapqemu01
Kind=tap
```
