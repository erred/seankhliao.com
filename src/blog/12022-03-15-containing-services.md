# containing services

## isolating services so they don't interfere with each other

### _containing_ services

So you have a set of things you want to run,
and you want to isolate them from each other,
so they don't step on each other's toes.
Here come options,
many based on Linux [namespaces](https://man.archlinux.org/man/namespaces.7).

#### _oci_ runtimes

The [Open Containers Initiative OCI](https://opencontainers.org/)
governs standards for container images and runtimes.
This helps with interoperability between tools.

For networking, these containers will generally have it all setup for them,
so the single process that runs doesn't will automagically work.

##### _docker_

[docker](https://www.docker.com/) has become nearly synonymous with containers,
but that's confusing.
In colloquial usage,
"docker" can refer to: the container image, the running container,
the client side tool, the server daemon, or the company.

UX wise, you tell the daemon you want to run a base image (read only),
it creates an instance with a writable overlay.
Primarily aimed at a single container per process,
network is automagically configured for you.
Container config options are primarily passed as flags.

##### _containerd_

[containerd](https://containerd.io/) is based off the same tech as docker,
but stripped down and better suited to integration.
Container config is a json file describing the desired options.

##### _podman_

[podman](https://podman.io/) occupies a similar space,
single app containers,
with a big architechtural difference in that it doesn't run a persistent daemon.
Instead, it relies on the system (eg systemd) to handle process management.
Container config is also passed via flags.

#### _systemd_

What doesn't the all encompassing system manager [systemd](https://systemd.io/) do these days.

##### _systemd_ services

Plan old [systemd services](https://man.archlinux.org/man/systemd.service.5)
actually have a few namespacing options to lock down the processes,
documented in [systemd.exec](https://man.archlinux.org/man/systemd.exec.5).
A lot of it revolves around the filesystem but the major missing namespace is for network.
It's certainly possible to use namespaces with hooks and [ip](https://man.archlinux.org/man/ip.8),
but it's not ergonomic.

Image wise, there is none, it's a config file that makes use of files in the existing filesystem,
with conventions on where to place things.

##### _systemd_ portable services

[portable services](https://systemd.io/PORTABLE_SERVICES/) solves distrobution
by putting everything into a root tree (still with OS like heirarchy)
(optionally as a single file raw image),
and extracting/rewriting the service files to make them available to the host.
Also allows for composing overlays.
The remainder is still very much a systemd service

##### _systemd_ nspawn

[systemd-nspawn](https://man.archlinux.org/man/systemd-nspawn.1.en)
is an option for running more fully fledged containers,
starting from an oci bundle, disk image or fs root.
Networking wise, it configures a link level setup (L2),
but it's up to the container to setup ip connectivity (usually running DHCP),
meaning is better suited for a fully fledged OS with an init system etcd.

##### _systemd_ machined

[systemd-machined](https://man.archlinux.org/man/systemd-machined.service.8.en)
is an extra layer on top of nspawn that helps with managing the images,
and also claims to integrate with VM managers, though
there's hardly any documentation on how that's setup.

#### _linux_ containers

The very generically named [Linux Containers](https://linuxcontainers.org/)
is actually a specific set of technologies.

##### _lxc_

This more or less corresponds to systemd-nspawn, except it doesn't rely on systemd.

##### _lxd_

This maps to systemd-machined, but better because it has native support for running VMs.
