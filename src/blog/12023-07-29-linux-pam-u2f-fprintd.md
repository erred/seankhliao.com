# linux pam with u2f and fprintd

## all the auth options

### _pam_ auth

`pam` is the thing that controls auth to a linux system.
It's supposed to be a serial chain of options,
a `sufficient` module should terminate an auth process with success,
while `include` should just include everything from a file.

#### _u2f_ and fprintd

What I want: auth by fingerprint, yubikey, or password, in that order.
The important flows for me are system login (tty) and sudo.

Reading through the include chains of auth,
I thought login was: `login` -> `system-local-login` -> `system-login` -> `system-auth`
and sudo was: `sudo` -> `system-auth`.
I thought that I could just add both `pam_fprintd.so` and `pam_u2f.so` to `system-auth`.

However, when I tried that,
`sudo` worked,
but logging in to a tty would trigger all 3 auth options, then still fail.
Some experimenting later,
I realized that it was `pam_shells.so` that was somehow interfering with the login process.
So I could either remove the module
or place both `pam_fprintd.so` and `pam_u2f.so` somewhere before `pam_shells.so` was called.

##### /etc/pam.d/

Here's the auth chains I ended up with:

###### login

```
auth       required     pam_securetty.so
auth       requisite    pam_nologin.so
auth       include      system-local-login
```

###### system-local-login

```
auth      sufficient 		       pam_fprintd.so       max-tries=2 timeout=15
auth      sufficient 		       pam_u2f.so           cue origin=pam://hwaryun appid=pam://hwaryun authfile=/etc/u2f_keys [cue_prompt=touche]
auth      include   system-login
```

###### system-login

```
auth       required   pam_shells.so
auth       requisite  pam_nologin.so
auth       include    system-auth
```

###### system-auth

```
auth       sufficient 		       pam_fprintd.so       max-tries=2 timeout=15
auth       sufficient 		       pam_u2f.so           cue origin=pam://hwaryun appid=pam://hwaryun authfile=/etc/u2f_keys [cue_prompt=touche]
-auth      [success=2 default=ignore]  pam_systemd_home.so
auth       [success=1 default=bad]     pam_unix.so          try_first_pass nullok nodelay
auth       [default=die]               pam_faillock.so      authfail
auth       optional                    pam_permit.so
auth       required                    pam_env.so
auth       required                    pam_faillock.so      authsucc
```

###### sudo

```
auth		include		system-auth
```
