# background auth

## how does google magically get authenticated to its apis

### _background_ auth

GCP SDKs can usually magically detect when they're running in a supported environment
and authenticate appropriately.
How does that work?

Looking at Go:

[`google.golang.org/api/transport`](https://pkg.go.dev/google.golang.org/api/transport)
provides wrappers that create authenticated HTTP and gRPC clients.
If no auth options are passed, this then goes to
[`golang.org/x/oauth2/google`](https://pkg.go.dev/golang.org/x/oauth2/google)
and its magic
[`FindDefaultCredentials`](https://pkg.go.dev/golang.org/x/oauth2/google#FindDefaultCredentials).
Well not really magic, it does what it says in the documentation:
check the env if it points to an auth file, check well known locations for auth files,
and query the metadata server (literally ask if the ip/internal dns address is available).

All this results in an OAuth2 token/source which is used to either wrap an http transport
(reuse token until it needs refresh, call source to get new token),
or with configure the gRPC client
[`WithPerRPCCredentials`](https://pkg.go.dev/google.golang.org/grpc#WithPerRPCCredentials).
