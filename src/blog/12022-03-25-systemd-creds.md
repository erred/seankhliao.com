# systemd-creds

## a credential manager in systemd


### _systemd-creds_

So, your service unit needs secrets,
and you need to store those secrets somewhere,
preferably in a way noone else can access.

_systemd-creds_ offers an integrated solution:
An RSA host key is generated at `/var/lib/systemd/credential.secret`,
encrypt secrets with `systemd-creds encrypt $input $output`,
use it either inline with `SetCredentialEncrypted=ID:...`
or referencing a file with `LoadCredentialEncrypted=ID:...`,
and use it by reading from a file `$CREDENTIALS_DIRECTORY/ID`.

This essentially ties secrets to root user permissions,
within units, it's scoped to the user and non swappable memory.

Is it better than having the secrets in environments?
Maybe, and while it supports reading secrets from a unix socket,
it can't expose them as such, which would have been nice for read-once semantics.
It doesn't look like it's meant to long term store of secrets across a distributed system,
just the last-mile storage on the local system.
