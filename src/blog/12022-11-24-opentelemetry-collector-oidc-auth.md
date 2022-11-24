# opentelemetry collector oidc auth

## OpenID Connect authentication with the OpenTelemetry Collector

### _otelcol_ oidc auth

The [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector)
(otelcol)
has an [oidcauth extension](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/oidcauthextension).
This makes for an interesting alternative to using:

- [basicauth](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/basicauthextension):
  effectively a preshared key
- [bearertoken](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/bearertokenauthextension):
  either a static key or a file that you have to mount/keep up to date.
- [mTLS](https://github.com/open-telemetry/opentelemetry-collector/tree/main/config/configtls):
  requires provisioning and distributing TLS keys/certs

#### _oidc_ token

First, we're going to need an OIDC identity token.
I'm going to use GCP because... that's what I have (and where my workloads are running).
`gcloud` has a command to print out an identity token for a service account,
note this requires `roles/iam.serviceAccountTokenCreator` on the account itself,
and maybe switching over to it for default auth?

```sh
gcloud auth print-identity-token \
  hwaryun@com-seankhliao.iam.gserviceaccount.com \
  --include-email \
  --audiences otelcol \
  --impersonate-service-account hwaryun@com-seankhliao.iam.gserviceaccount.com
```

This gives you a long token like (`------` parts will be actual chars):

```txt
eyJhbGci------------J0eXAiOiJKV1QifQ.eyJhdWQi---------xODYifQ.FfpWwTlS24zl------v3pRd33tZmQgq1gLabQ
```

#### _collector_

On the collector side we'll nned the 
[oidcauth extension](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/oidcauthextension)
configured for Google's accounts endpoint,
and with the right header extractor.

The verified data is stored in the 
[context's authdata](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/1ab871940dbe9fa728fb5e7e6b4d5248fb91d454/extension/oidcauthextension/authdata.go#L27)
which can be extracted with the processors into proper attributes,
something you'll want to do before reshaping/regrouping data with batch/groupbyX.
Also, as an attribute, it's where you can implement richer filtering (eg checking project via email).

```yaml
extensions:
  # due to header canonicaliztion weirdness
  # http1 uses "Authorization" (leading capital)
  # while grpc uses lowercase
  oidc/grpc:
    issuer_url: https://accounts.google.com
    audience: otelcol
    username_claim: email

  oidc/http:
    issuer_url: https://accounts.google.com
    audience: otelcol
    username_claim: email
    attribute: Authorization

receivers:
  otlp:
    protocols:
      http:
        auth:
          authenticator: oidc/http
      grpc:
        auth:
          authenticator: oidc/grpc

processors:
  # using th resource processor, we can pull out auth data from the auth. * context
  # also available for the attribute processor
  # if we want to do any stricter validation, it can be done in a processor
  # eg, only allowing users with our @project.iam.gserviceaccount.com emails
  resource:
    attributes:
      - key: oidc.subject
        action: upsert
        from_context: auth.subject
      # google service accounts don't set this field
      - key: oidc.membership
        action: upsert
        from_context: auth.membership

exporters:
  logging:
    verbosity: detailed

service:
  extensions: [oidc/http, oidc/grpc]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [resource]
      exporters: [logging]
  telemetry:
    logs:
      level: debug
```

#### _client_

Now we need a client to use the token

##### _curl_

If we only care about testing if the token is accepted, curl works.

_note:_ this uses the otlp http endpoint.

```sh
curl -v http://localhost:4318/ -H "authorization: Bearer ${ID_TOKEN}"
```

##### _tracegen_

[tracegen](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/cmd/tracegen)
is a tool that is part of the opentelemetry-collector-contrib project.
It's an easy way to generate valid data.

_note:_ the quoting rules as tracegen requires the value be quoted

```sh
tracegen -otlp-insecure -otlp-header 'authorization="Bearer '${ID_TOKEN}'"'
```

##### _go_

For Go, this just mean pulling in GCP's `idtoken` generator and hooking that in to gRPC.
It should be easy to swap out to any other token provider.

```go
package main

import (
        "context"
        "crypto/tls"
        "log"

        "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
        "google.golang.org/api/idtoken"
        "google.golang.org/grpc"
        "google.golang.org/grpc/credentials"
        "google.golang.org/grpc/credentials/oauth"
)

func main() {
        ctx := context.Background()
        gcpTS, err := idtoken.NewTokenSource(ctx, "otelcol")
        if err != nil {
                log.Fatal(err)
        }

        exporter, err := otlptracegrpc.New(ctx,
                otlptracegrpc.WithDialOption(
                        // TLS required for credentials
                        grpc.WithTransportCredentials(credentials.NewTLS(&tls.Config{InsecureSkipVerify: true})),
                        // id token per request in headers
                        grpc.WithPerRPCCredentials(&oauth.TokenSource{TokenSource: gcpTS}),
                ),
        )
        if err != nil {
                log.Fatalln(err)
        }
}

```
