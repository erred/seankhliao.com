# systemd-nspawn

## how do you configure the damn thing

### _systemd_-nspawn

So systemd has its own containery thing.
Now how do you use it?

#### _basics_

Give it a root filesystem and launch it with `systemd-nspawn ...`.
Some settings can be set in `<machine>.nspawn` files,
but there are caveats that make it less than useful.
`machinectl` claims to abstract over the lower level `systemd-nspawn` interface,
but all it really does is launch the machines using the `systemd-nspawn@.service`.
This service just calls `systemd-nspawn` and allows settings files to override it.

`systemd-nspawn` determines the `.nspawn` file to use based on the machine name:`-M`, `--machine`.
This is a problem if you want to use ephemeral containers: `-x`, `--ephemeral`,
since presumably you're launching a lot of them with different names,
and now you need a `.nspawn` file per launch (that you need to clean up too...).
Even though it claims settings will derive the name from the directory base name,
it doesn't seem to happen.

So your best bet is probably write your own templated `.service` file,
calling `systemd-nspawn` and using flags to run multiple instances of a container.

#### _network_

While you may get a veth pair, it's only L2,
so you probably still want to run an init system + something else that will handle DHCP for you.
This unfortunately makes the `-a`, `--as-pid2` much less useful.

#### _login_

```
arch-nspawn login: root
Login incorrect
```

But you're sure you typed in the correct passwd.
The Archwiki [suggests](https://wiki.archlinux.org/title/systemd-nspawn#Root_login_fails)
that you remove the `/etc/securetty` config (and associated factory setup).
Poettering instead
[recommends](https://github.com/systemd/systemd/issues/852#issuecomment-127759667)
removing `pam_securetty` from `/etc/pam.d/*`,
which I found to be much more successful at letting me log in.
