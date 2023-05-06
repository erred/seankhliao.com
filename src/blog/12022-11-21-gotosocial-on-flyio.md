# GoToSocial on Fly.io

## more hosting options

### _GoToSocial_ running on fly.io

There's been a recent trend of people turning from [Twitter](https://twitter.com/)
to the Fediverse, mostly [mastodon](https://joinmastodon.org/servers),
but since it's an open ecosystem centered around the [ActivityPub](https://www.w3.org/TR/activitypub/)
protocol, there are other options, like [plemora](https://pleroma.social/).

Mastodon is a Rails app with lots of dependencies,
Plemora is an Elixir app that's not much better.

[GoToSocial](https://gotosocial.org/) is a project that covers just the server side of ActivityPub,
exposing client side communications via a Mastodon compatible API.
Deployment is easy-ish, a single binary + web assets.

#### _fly.io_

[fly.io](https://fly.io/)
takes your container image and runs it as a [firecracker](https://firecracker-microvm.github.io/)-based vm.
It's an interesting halfway point in between VMs and containers in terms of deployment.
What's more attractive though is their 3x 256MB shared cpu vm free tier.

To run GoToSocial, we're taking their prebuilt docker image,
and deploying it.

Create the fly.io app and volume

```sh
$ fly apps create estherian
$ fly volumes create gotosocial_data -s 1 -r lhr
```

Flip `GTS_LETSENCRYPT_ENABLED` to `false` in the below config,
then run `fly deploy`.

Get the IP address, set the DNS `A`/`AAAA` records,
flip the `GTS_LETSENCRYPT_ENABLED` back to `true` and redeploy.

```toml
app = "estherian"

[build]
  image = "superseriousbusiness/gotosocial:latest"

[env]
  GTS_PORT = "8443"
  GTS_HOST = "estherian.liao.dev"
  GTS_ACCOUNT_DOMAIN = "liao.dev"
  GTS_DB_TYPE = "sqlite"
  GTS_DB_ADDRESS = "/gotosocial/storage/db.sqlite"
  GTS_ACCOUNTS_REGISTRATION_OPEN = "false"
  GTS_LETSENCRYPT_ENABLED = "true"
  GTS_LETSENCRYPT_PORT = "8080"
  GTS_LETSENCRYPT_EMAIL = "estherian@liao.dev"

[mounts]
  source = "gotosocial_data"
  destination = "/gotosocial/storage"

[[services]]
  internal_port = 8080
  protocol = "tcp"
  [[services.ports]]
    port = 80
[[services]]
  internal_port = 8443
  protocol = "tcp"
  [[services.ports]]
    port = 443
```

Once it's running,
create your user following the
[standard documentation](https://docs.gotosocial.org/en/latest/installation_guide/docker/).

```sh
$ fly ssh console
# gotosocial admin account create --username some_username --email someone@example.org --password 'some_very_good_password'
# gotosocial admin account confirm --username some_username
# gotosocial admin account promote --username some_username
```

And done.
Find a frontend, use the actual hosting domain to login.
