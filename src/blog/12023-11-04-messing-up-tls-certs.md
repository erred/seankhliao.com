# messing up tls certs

## doing things the hard way and making mistakes

### _tls_ certs the hard way

For $reasons,
I had been manually requesting and updating the TLS certs used in my kubernetes cluster by hand.
Specifically, using [acme.sh](https://github.com/acmesh-official/acme.sh)
to request wildcard certs from [Let's Encrypt](https://letsencrypt.org/)
via DNS challenge in [GCP Cloud DNS](https://cloud.google.com/dns?hl=en).

#### _renewing_ certs by hand

One uneventful (so far) Saturday,
I saw that my certs had a month and a half left,
and decided to renew them.
Having not written the process down,
I searched backwards in shell history
([zsh-substring-search](https://github.com/zsh-users/zsh-history-substring-search) is great)
for the right command and got some new certs.
At the same time,
I thought why not use [Google Public CA](https://cloud.google.com/certificate-manager/docs/public-ca)
to reduce the monoculture on Let's Encrypt.

```sh
$ gcloud alpha publicca external-account-keys create
$ acme.sh --register-account --email $EMAIL --server google --eab-kid $PUBLICCA_KID --eab-hmac-key $PUBLICCA_HMAC
$ acme.sh --server google --ecc --renew --force --dns dns_gcloud --domain '*.liao.dev' --domain '*.ihwa.liao.dev'
```

This gave me the usual directory of:

```
.acme.sh/
  *.liao.dev/
    *.liao.dev.cer
    *.liao.dev.conf
    *.liao.dev.csr
    *.liao.dev.key
    ca.cer
    fullchain.cer
```

#### _using_ new certs

Not remembering what I used last time,
I used the cert `*.liao.dev.cer` and key `*.liao.dev.key` as the TLS key pair
in a server ([Envoy Gateway](https://gateway.envoyproxy.io/)),
and it worked, sort of.
Chrome happily connected and verified the cert,
but when I tried to use cli tools like curl, openss, and step-cli,
I would fail to verify the cert:

```sh
$ curl https://ihwa.liao.dev
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

$ openssl -connect ihwa.liao.dev:443 </dev/null
openssl s_client -connect 127.0.0.1:8443 -servername ihwa.liao.dev < /dev/null
CONNECTED(00000003)
depth=0 CN = *.liao.dev
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0 CN = *.liao.dev
verify error:num=21:unable to verify the first certificate
verify return:1
depth=0 CN = *.liao.dev
verify return:1
---
Certificate chain
 0 s:CN = *.liao.dev
   i:C = US, O = Google Trust Services LLC, CN = GTS CA 1P5
   a:PKEY: id-ecPublicKey, 256 (bit); sigalg: RSA-SHA256
   v:NotBefore: Nov  4 09:32:23 2023 GMT; NotAfter: Feb  2 09:32:22 2024 GMT
---
Server certificate
-----BEGIN CERTIFICATE-----
MIIEqDCCA5CgAwIBAgIRANZ6hF26ru42Dk1AEW+t7eUwDQYJKoZIhvcNAQELBQAw
RjELMAkGA1UEBhMCVVMxIjAgBgNVBAoTGUdvb2dsZSBUcnVzdCBTZXJ2aWNlcyBM
TEMxEzARBgNVBAMTCkdUUyBDQSAxUDUwHhcNMjMxMTA0MDkzMjIzWhcNMjQwMjAy
MDkzMjIyWjAVMRMwEQYDVQQDDAoqLmxpYW8uZGV2MFkwEwYHKoZIzj0CAQYIKoZI
zj0DAQcDQgAED+loglA3i/62NqohbPruCDQnjbtNiffzdMipYWrSBqzdgVE60aNn
zbsI8PFDhGI/lSHNxu6GXpY0XUu4GKdSm6OCAoswggKHMA4GA1UdDwEB/wQEAwIH
gDAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAd
BgNVHQ4EFgQUFxukPjhCo6SqgU941B8UOgwJx9MwHwYDVR0jBBgwFoAU1fyeDd8e
yt0Il5duK8VfxSv17LgweAYIKwYBBQUHAQEEbDBqMDUGCCsGAQUFBzABhilodHRw
Oi8vb2NzcC5wa2kuZ29vZy9zL2d0czFwNS9Zcm9wWXhkZnlmNDAxBggrBgEFBQcw
AoYlaHR0cDovL3BraS5nb29nL3JlcG8vY2VydHMvZ3RzMXA1LmRlcjAmBgNVHREE
HzAdggoqLmxpYW8uZGV2gg8qLmlod2EubGlhby5kZXYwIQYDVR0gBBowGDAIBgZn
gQwBAgEwDAYKKwYBBAHWeQIFAzA8BgNVHR8ENTAzMDGgL6AthitodHRwOi8vY3Js
cy5wa2kuZ29vZy9ndHMxcDUvazRiRnFycUNBVkkuY3JsMIIBAwYKKwYBBAHWeQIE
AgSB9ASB8QDvAHYASLDja9qmRzQP5WoC+p0w6xxSActW3SyB2bu/qznYhHMAAAGL
meQV3QAABAMARzBFAiEAzJ7lwFWIIjzDNGMkPjryL3MWd2V1jkp2YYbFNsyOAI4C
IHjJ6a5gvz1p770j/+gB6PB9Qmd30922a2ylz2ZEGh6iAHUA7s3QZNXbGs7FXLed
tM0TojKHRny87N7DUUhZRnEftZsAAAGLmeQVuwAABAMARjBEAiBrJBSC0vkCyKhs
YZQnAFPvf5/W6i8PhjjF9yxVGXBdogIgJY0tSHO5j6qmgK8PtfdDJBw0tFSXuYJn
qv43QUazYEcwDQYJKoZIhvcNAQELBQADggEBAK6lM60o3cP6U7ahR+cbZE07JO/b
8dtrau0d89x8j8+d7/FIhmERzEgLlNGJzMliGxUuXu4RbBbV5U9DRkr2GnC+Pzyk
1qnpEOKdVQ7o7BzJ3AH/jtJMdJQ1dvaF8Z1NJZb0sj0lvUMoQt5DpSFFRzUO9U7l
Km72HxJFPG5JTjr6aYW5WDee/bHbL72hIgLCiUtub5iVPX7mZ2UCEeXU6wdZrK8v
ULpu/+vdY2yeHRdakC0DRY0qBSF+7zC9CWt4P8XRIXYj7c4zLdo9b2XXVod/Js8i
TII8ZJTUFedv0MOeHGN8ltE7gGjk4auwpFQ17a+CiuNrml8lVsUp9TRKJ5k=
-----END CERTIFICATE-----
subject=CN = *.liao.dev
issuer=C = US, O = Google Trust Services LLC, CN = GTS CA 1P5
---
No client certificate CA names sent
Peer signing digest: SHA256
Peer signature type: ECDSA
Server Temp Key: X25519, 253 bits
---
SSL handshake has read 1551 bytes and written 379 bytes
Verification error: unable to verify the first certificate
---
New, TLSv1.3, Cipher is TLS_AES_128_GCM_SHA256
Server public key is 256 bit
This TLS version forbids renegotiation.
Compression: NONE
Expansion: NONE
No ALPN negotiated
Early data was not sent
Verify return code: 21 (unable to verify the first certificate)
---
---
Post-Handshake New Session Ticket arrived:
SSL-Session:
    Protocol  : TLSv1.3
    Cipher    : TLS_AES_128_GCM_SHA256
    Session-ID: B655E45C351E5376E391FAAE8D33FDE522A049AFCDA9BEA16AA12646312385B6
    Session-ID-ctx:
    Resumption PSK: 9E5B00208476BC0CB3B19AB46DCD12266A25378AD3CD385D9243E5FA0B0541BD
    PSK identity: None
    PSK identity hint: None
    SRP username: None
    TLS session ticket lifetime hint: 604800 (seconds)
    TLS session ticket:
    0000 - 0d 5a 82 69 f6 2c 8d 43-62 4f ee 99 4b 01 16 51   .Z.i.,.CbO..K..Q
    0010 - 4f 3c 1d b0 ef d0 cb c4-26 1a 75 15 c5 10 58 84   O<......&.u...X.
    0020 - 9e a0 8b 97 b6 93 ba c1-30 c9 2e 45 24 95 f3 2a   ........0..E$..*
    0030 - 11 71 e4 70 19 c6 20 23-8e 5b 5a 60 fa fa 01 be   .q.p.. #.[Z`....
    0040 - e6 cc 7b 0e 73 92 62 cd-e8 2f f4 08 7e e5 0b d3   ..{.s.b../..~...
    0050 - 8b a0 10 8a 3d 76 dd 81-96 da af 06 54 60 7c 7e   ....=v......T`|~
    0060 - 59 3d ce 31 bf ce a0 53-b5                        Y=.1...S.

    Start Time: 1699218296
    Timeout   : 7200 (sec)
    Verify return code: 21 (unable to verify the first certificate)
    Extended master secret: no
    Max Early Data: 0
---
read R BLOCK
DONE

$ step-cli certificate verify https://ihwa.liao.dev
failed to connect: tls: failed to verify certificate: x509: certificate signed by unknown authority
```

Now this was confusing,
since I was pretty sure I was using the right certs.
Testing the certs locally with a simple Go HTTPS server it logged the following,
which was even more confusing since `bad record mac` was an internal error.

```
2023/11/05 21:03:31 http: TLS handshake error from 127.0.0.1:38672: local error: tls: bad record MAC
2023/11/05 21:05:57 http: TLS handshake error from 127.0.0.1:40788: remote error: tls: bad certificate
```

Stepping back a bit,
I tried to verify the certs directly,
which wasn't much more successful:

```sh
$ openssl verify '*.liao.dev.cer'
CN = *.liao.dev
error 20 at 0 depth lookup: unable to get local issuer certificate
error ./tls.crt: verification failed

$ step-cli certificate verify '*.liao.dev.cer'
failed to verify certificate: x509: certificate signed by unknown authority
```

Then I thought,
maybe I need to pass the CA file:

```sh
$ openssl verify -CAfile ca.cer '*.liao.dev.cer'
tls.crt: OK

$ step-cli certificate verify --roots ca.cer '*.liao.dev.cer'
```

When it finally clicked that I needed to use the fullchain cert (`fullchain.cer`)
instead of just the leaf cert.

The actual process consisted of more mistakes,
and my mind wandering to:
are the root certs on my machine broken/out of date,
did acme.sh mess up a cert somehow,
and other weird ideas I don't remember.

#### _exposing_ and revoking

Now that I finally had working certs,
time to save them.
I run my cluster via GitOps with the
[OSS version of Config Sync](https://github.com/GoogleContainerTools/kpt-config-sync).
For secrets,
I use [isindir/sops-secrets-operator](https://github.com/isindir/sops-secrets-operator).
The workflow consists of creating a SopsSecret custom resource,
then encypting it with [sops](https://github.com/getsops/sops)
`sops -e -i file.yaml` (in conjunction with the `.sops.yaml` config I have to specify keys).

```yaml
apiVersion: isindir.github.com/v1alpha3
kind: SopsSecret
metadata:
  name: wildcard-google
  namespace: envoy-gateway-system
spec:
  secretTemplates:
    - name: wildcard-google
      type: kubernetes.io/tls
      stringData:
        tls.crt: |
          ...
        tls.key: |
          ...
        ca.crt: |
          ...
```

`.sops.yaml` to only encrypt the data parts,
and with 2 [age](https://github.com/FiloSottile/age) keys:
a local admin key, and a remote server key.

```yaml
creation_rules:
  - encrypted_regex: "^(data|stringData)"
    key_groups:
      - age:
          - age14mg08panez45c6lj2cut2l8nqja0k5vm2vxmv5zvc4ufqgptgy2qcjfmuu
          - age19q63k49upkgc03e8rsvm5c04x09vqvp2g5u2x6fjjap5awvq0u6q25z8xp
```

I had 2 pairs of cert/keys:
from Let's Encrypt and from Google Public CA,
which I pushed into git.

I noticed that the sops operator failed to decode the secret,
and upon looking into why,
I realized it wasn't encrypted.
It wouldn't have been so bad if I didn't have a
[public mirror of my repo](https://github.com/seankhliao/config-sync-root/).

So now I have the fun task of revoking the exposed secrets.
I had issued certs from Google Public CA first,
then overwrote the data in acme.sh's config with a second set of certs from Let's Encrypt
(since I was testing if it was just Google Trust Services certs that wouldn't verify earlier).

This meant `acme.sh --revoke` didn't want to work.
So I go about downloading `certbot`,
which has the option to revoke using private key / cert pair:

```sh
$ sudo certbot revoke --cert-path tls.crt --key-path tls.key --reason keyCompromise  --server https://dv.acme-v02.api.pki.goog/directory
```

Later I realized that because I had issued my second set of certs via `acme.sh --renew --force`,
it kept the same private key.
So my "unexposed" cert/key were actually exposed.
This time I could use `acme.sh`:

```sh
$ acme.sh --revoke --ecc -d '*.liao.dev'
```

#### _cert-manager_

Now I could start from scratch,
and just remember to actually encrypt secrets.
But I thought I might as well go through with the automation
and setup [cert-manager](https://cert-manager.io/) in my cluster.
I had initially resisted because the last time I ran it it was during its graduation into 1.0.0
where there were deprecations to work around,
but now it's a much more stable project.

Again, I wanted certs from both Let's Encrypt and Google Public CA,
and this time, I would test with staging certs first.
Let's Encrypt was straightforward to set up,
while GCP had a surprise hiding in the footnote where
the EAB secret is needs to be generated seprately by switching the api endpoint in config
and not flags ([instructions](https://cloud.google.com/certificate-manager/docs/public-ca-tutorial#staging))

```sh
$ gcloud config set api_endpoint_overrides/publicca https://preprod-publicca.googleapis.com/
$ gcloud publicca external-account-keys create
$ gcloud config unset api_endpoint_overrides/publicca
```

With this I could finally have my issuers setup:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: acme+letsencrypt@liao.dev
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging-account
    solvers:
      - dns01:
          cloudDNS:
            project: ...
            serviceAccountSecretRef:
              name: gcp-cert-manager-sa
              key: key.json
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: google-staging
spec:
  acme:
    email: acme+google@liao.dev
    server: https://dv.acme-v02.test-api.pki.goog/directory
    privateKeySecretRef:
      name: google-staging-account
    externalAccountBinding:
      keyID: ...
      keySecretRef:
        name: gcp-publicca-staging
        key: b64MacKey
    solvers:
      - dns01:
          cloudDNS:
            project: ...
            serviceAccountSecretRef:
              name: gcp-cert-manager-sa
              key: key.json
```

And certs:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: google-staging
  namespace: envoy-gateway-system
spec:
  secretName: google-staging-tls
  duration: 720h # 30d
  renewBefore: 360h # 15d
  revisionHistoryLimit: 1
  subject:
    organizations:
      - seankhliao
  privateKey:
    rotationPolicy: Always
    algorithm: ECDSA
    size: 256
  dnsNames:
    - "*.liao.dev"
    - "*.ihwa.liao.dev"
  issuerRef:
    name: google-staging
    kind: ClusterIssuer
```

Repeat for production with the prod endpoints,
and I was finally done for the day.
