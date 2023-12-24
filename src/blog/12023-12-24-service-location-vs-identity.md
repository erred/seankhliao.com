# service location vs identity

## what are you taling to

### _service_ location vs identity

In the beginning, there was ~~light~~ ip addresses,
and you accessed a remote computer using these numbers (ignore anycast).

But numbers are hard to remember,
so there was DNS to map names to numbers.
Here's the first crack in "addresses get you a direct connection to a (unique) server",
since multiple A/AAAA records can exist, and you can connect to different servers
from the same name.

Then thigs got popular,
and we needed reverse proxies and CDNs,
and a constellation of microservices.
A name no longer referred to a connection to a server,
but served more as part of the identity of the resource you were accessing.

A natural evolution is then HTTP Signed Exchanges (SXG),
where the entire flow of of accessing a resource is recorded and signed,
and can be replayed later.

So it comes, that the domain name isn't really there to denote a location to connect to,
rather a (trusted) identity as a source of content.

#### _multiple_ paths to the same service

Here's a different angle:
you want to access a service like "The Pirate Bay" or "Sci-Hub".
These are identities,
their actual accessible locations change all the time due to pesky government rulings blocking access.

In a more corporate environment,
you might have services accessible over the public internet at `foo.example.com`,
but also over internal networks at `foo.prod.svc.cluster.internal`.
These are the same service,
but their locations are different.

#### _tls_ and identity

TLS has been the typical way to secure communications,
and also verify identity:
certificates are issued when you demonstrate control over a location (ACME),
and clients verify that the cert a server presents matches the location it was accessed at.
Which is sort of ok,
except when you can't get widely trusted certs for internal names.

#### _spiffe_ and spire

So what's the better way?
[SPIFFE](https://spiffe.io/) is an identity framework
where instead of being issued certificates for `DNS:foo.example.com`,
you get something more like `URI:spiffe://example.com/service/foo`.
Clients trust the identity of the service regardless of the location it was accessed over.
