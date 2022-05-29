# ssh certificates

## everyone gets a cert


### _ssh_ certificates

When you only keep around 1 server,
setting up certificates seem like quite a bit of overhead.
But if you're constantly resetting your server
and/or creating new test VMs, certs become a little more attractive.

#### _ca_

A SSH CA is just any standard keypair.
You probably want to keep it saf(er) than usual.
Here I'm using a yubikey/fido2 token to make it a bit more "offline".

```sh
# where you store it doesn't matter
$ ssh-keygen -t ecdsa-sk -f ~/.ssh/ca/ca_ecdsa_sk
```

#### _host_ keys

Signing host keys with a certificate means less managing of your known_hosts file
and less "the keys for this server has changed!!!".

```sh
# generate your host key(s)
$ ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key

# sign the pubkey
# you may want to generate the key on the server and copy the pubkey locally to sign,
# the send the cert back.
# an identity (-I) is mandatory and used for revoking
$ ssh-keygen -s ~/.ssh/ca/ca_ecdsa_sk -I some-host -h /etc/ssh/ssh_host_ed25519_key
```

The new certificates have to be used on the server

```sshdconfig
# sshd_config

HostKey /etc/ssh/ssh_host_ed25519_key
HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub

# only if you need/want to limit this
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519
```

And also trusted by the client, in `known_hosts`.
This allows the cert to sign any server (`*`), but can be used to limit by hostname/IP.

```
@cert-authority * sk-ecdsa-sha2-nistp256@openssh.com AAAA.......==
```

#### _user_ keys

Signing user keys with a certificate means your hosts only need a single `authorized_keys` setup.
No more adding/removing when you get new keys.

```sh
# generate user keys
$ ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519

# sign the pubkey
# -I is a key id for revoking
# -n is the list of usernames you're going to use
#       while you can sign without it, sshd will refuse to accept such certs by default.
$ ssh-keygen -s ~/.ssh/ca/ca_ecdsa_sk -I user1 -n username1,root,username2 ~/.ssh/id_ed25519.pub
```

On the server side, trust the CA, in `sshd_config`:

```sshdconfig
TrustedUserCAKeys /etc/ssh/user_ca_keys
```

and the actual ca pubkey in `/etc/ssh/user_ca_keys`:

```
sk-ecdsa-sha2-nistp256@openssh.com AAAA.......==
```

And finally, get the client side ssh to use it in `~/.ssh/config`:

```sshconfig
Host medea
    IdentityFile ~/.ssh/id/id_ed25519
    CertificateFile ~/.ssh/id/id_ed25519-cert.pub
```

#### server all in one

So now to setup a server, in `sshd_config`:

```sshdconfig
HostKey /etc/ssh/ssh_host_ed25519_key
HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519
TrustedUserCAKeys /etc/ssh/user_ca_keys
```

and locally:

```sh
$ ssh-keygen -t ed25519 -f ssh_host_ed25519_key
$ ssh-keygen -s ~/.ssh/ca/ca_ecdsa_sk -I hostx -h ssh_host_ed25519_key.pub
$ echo 'sk-ecdsa-sha2-nistp256@openssh.com AAAA.......==' > user_ca_keys
# untested
$ rsync . root@host1:/etc/ssh
```
