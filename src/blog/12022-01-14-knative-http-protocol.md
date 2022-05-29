# knative http protocol

## http redirects?

### _knative_

So I was testing my shiny new [gRPC](https://grpc.io/)
backend deployed with [knative](https://knative.dev/docs/)
and for some reason, the client never reached the backend
(both in cluster).
The error I got was:

```
"error":"rpc error: code = Unknown desc = ",
```

Which wasn't really helpful.
With copious amounts of loggin,
I could determin that the requests never actually reached my backend.

At first I suspected the weird way knative sets up the
kubernetes core `Service` resource,
but looking at the backing `Endpoints`,
I could see it point to the (theoretically) right thing,
the internal load balancer.

Next I tried [grpcurl](https://github.com/fullstorydev/grpcurl)
which to be honest didn't help much as it just reported a similar error.
Finally, I remembered that gRPC was just HTTP/2,
so plain [curl](https://curl.se/) here I come:

```
curl --resolve authnb.auth.svc:8443:127.0.0.1 -v --http2-prior-knowledge https://authnb.auth.svc:8443
```

and wouldn't you know it: `< HTTP/2 301` pointing to https.
Ah, then I remembered the knative `config-network` setting
`http-protocol: Redirect` I had set,
thinking I needed it to redirect external plain http requests.
Setting it to `http-protocol: Enabled` got me back my grpc connections,
and my external requests still seem to go to https.
