# systemd-nspawn first impressions

##

### _systemd-nspawn_

So you want containers without docker?
Well here's a systemd project for you!
Create a fileystem tree on your machine,
and run systemd-nspawn against it, instant container.

#### _getting_ fs tree

So where do you get a fileystem tree from?
Your distro of choice usually has a tool to create one,
eg `debootstrap` for debian or `pacstap` for arch linux.

The manual also says it accepts OCI bundles,
but as far as I can tell, nothing except
[`oci-image-tool`](https://github.com/opencontainers/image-tools)
will create one of the correct format.
You can of course, `docker export` a running container, untar it, then `runc spec`
to create the `config.json`, but that's so much hassle,
and nspawn only accepts a spec version of exactly `1.0.0`.

#### _scratch_

If you use `go` with containers, you may be familiar with scratch containers,
well it's sort of possible to do the same,
except creating the `usr/bin` dir is mandatory (some sort of sanity check),
and nspawn doesn't setup networking for you,
so you'll have to interract with netlink to:
set the link `host0` up and assign it an IP address.
Hope you know how to speak DHCPv4 to get the correct address
(or cheat and type in a routable address in STDIN).
