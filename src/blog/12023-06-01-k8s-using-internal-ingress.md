# k8s using internal ingress

## so dns??

### _k8s_ using internal ingress

So in the places i've been,
someone has usually managed to deploy
[ingress-nginx](https://kubernetes.github.io/ingress-nginx/)
in Kubernetes.
And usually that means an "external" and an "internal" deployment.

Most people only seem to figure out the external part:
Setup DNS to point to your cloud load balancer,
configure Ingress objects to match those external DNS names.

But what about the internal one?
You could:

Rewrite an external name or serve up a new internal domain
with the resolved address being that of internal ingress'es Service virtual IP.
Demonstrated by this [coredns blogpost](https://coredns.io/2017/05/08/custom-dns-entries-for-kubernetes/).

Or... you could set `http_proxy` in your clients to point at the internal ingress.
There is a bit of difference in the requests,
but it shouldn't really matter for routing.
Note that this only really works with plain HTTP
as HTTPS is going to get a CONNECT request instead to tunnel through to the target.

Plain request:

```http
GET /foo HTTP/1.1
Host: example.com
User-Agent: curl/8.1.2
Accept: */*
```

Proxy request

```http
GET http://example.com/foo HTTP/1.1
Host: example.com
User-Agent: curl/8.1.2
Accept: */*
Proxy-Connection: Keep-Alive
```
