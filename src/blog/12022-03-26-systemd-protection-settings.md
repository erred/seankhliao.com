# systemd protection settings

##

### _systemd.exec_

Results of trial and error on the `[Service]` settings in `man 5 systemd.exec`

#### _paths_

- `MountAPIVFS=`: implied by other settings below
- `ProtectProc=invisible`: hides subtrees from other pids in `/proc/`,
  other things like `/proc/cpuinfo` remain available
- `ProcSubset=pid`: hides everything else, leaving just
  `/proc/<pid>`, `/proc/self/`, `/proc/thread-self/`

#### _identity_

- `DynamicUser=true`: dynamically allocated user/group, username uses service name.
  Note this also affects binaries with setuid/setcap on them,
  as they are forced to be a different user (so don't get the capabilities originally granted).

#### _capabilities_

- `CapabilityBoundingSet=cap_net_bind_service` limits existing capabilities (eg if you're root)
- `AmbientCapabilities=cap_net_bind_service`: grants new capabilities

#### _security_

- `NoNewPrivileges=true`: prevents bypasses by execing other processes.
- `SecureBits=noroot-locked`: do not grant capabilities from file system

#### _sandboxing_

- `ProtectSystem=strict`: Filesystem (except `/dev/`, `/proc`, `/sys/` is readonly,
  unless allowed by other settings
- `PrivateDevices=true`: Hides non virtual things in `/dev/`
- `PrivateIPC=true`
- `PrivateUser`: hides other users
- `ProtectHostname=true`
- `ProtectClock=true`
- `ProtectKernelTunables=true`, make `/proc/` and `/sys/` settings read only
- `ProtectKernelModules=true`
- `ProtectKernelLogs=true`
- `ProtectControlGroups=true`
- `RestrictNamespaces=true`
- `LockPersonality=true` (system architecture, eg x86_64 + x86)
- `MemoryDenyWriteExecute=true`
- `RestrictRealtime=true`
- `RemoveIPC=true`
- `RestrictSUIDSGID=true`, implied by DynamicUser
- `PrivateMounts=true` hides mounts from host
