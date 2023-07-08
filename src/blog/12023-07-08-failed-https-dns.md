# failed: HTTPS DNS records

## deep in config

#### HTTPS DNS records

[SVCB and HTTPS](https://datatracker.ietf.org/doc/draft-ietf-dnsop-svcb-https/) record types
are the new DNS records on the block,
acting as a dual purpose redirector and all-in-one record type.
SVCB is the generic one,
while HTTPS is dedicated to the https protocol.

I wanted to try it out on my self hosted setup,
so I turned on the seeting in chrome
[`chrome://flags/#use-dns-https-svcb-alpn`](chrome://flags/#use-dns-https-svcb-alpn),
set [alpn](https://www.iana.org/assignments/tls-extensiontype-values/tls-extensiontype-values.xhtml#table-alpn-protocol-ids)
to `http/1.1,h2`,
and promptly discovered nothing changed.

Upon closer inspection,
I think the chrome flag only uses it for HTTP3 and not HTTP2,
which is an issue,
since I'm testing it with [envoyproxy/gateway](https://github.com/envoyproxy/gateway),
and implementation of [Gateway API](https://gateway-api.sigs.k8s.io/),
and that doesn't yet (transparently) support HTTP3,
even if envoy itself does.
