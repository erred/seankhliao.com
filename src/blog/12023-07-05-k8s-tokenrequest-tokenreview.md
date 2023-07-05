# k8s tokenrequest and tokenreview

## K8s as an identity provider

### _k8s_ token request and review

Ever workload (Pod) that runs in Kubernetes has an attached ServiceAccount.
You might think that the ServiceAccount is only good for interacting with the K8s api server,
but you can actually do more.
With the big clouds like AWS and GCP,
cloud native roles / service accounts can be attached to K8s service accounts
and their SDKs will plumb through the authentication dance.

With the K8s TokenReview API and ServiceAccountIssuerDiscovery (OIDC) support,
your ServiceAccount tokens are actually ID tokens that can be verified by a third party.

#### _get_ a token

##### _default_ token

By default, a token attached to the service account will be present in
`/var/run/secrets/kubernetes.io/serviceaccount/token`.
It's a jwt / oidc token that can be decoded,
smallstep's `step-cli` can do it with `step-cli crypto jwt --insecure`.
Here we can see the audience for this token is just the kubernetes api server.

```sh
$ cat /var/run/secrets/kubernetes.io/serviceaccount/token
eyJhbGciOiJSUzI1NiIsImtpZCI6IlZsNTF6WjNLWW5PZmE5eFJLNmM0ZmM2NG1Jelc2MzdKVGRaTnhXc2ltODAifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzIwMTE4NjY3LCJpYXQiOjE2ODg1ODI2NjcsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0IiwicG9kIjp7Im5hbWUiOiJjdXJsLTIiLCJ1aWQiOiI0YjUwZjg1Mi0xYzY3LTRkMTItODBlZi00NGZjMmFjMTY3ZjAifSwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImRlZmF1bHQiLCJ1aWQiOiI0NmM1Zjg1Ni1mYzQ5LTQ2ZWMtYTY3OC1kZGE3NzVjNzQxM2QifSwid2FybmFmdGVyIjoxNjg4NTg2Mjc0fSwibmJmIjoxNjg4NTgyNjY3LCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6ZGVmYXVsdDpkZWZhdWx0In0.fnEhHvf4WC1QGobRTNpauMO_nXi36L_dYouTDsaO52B4bOC_2Ea_yqJmR44x4LMI3SaiPsynl5a_k0BWso_Ufx8YXU08wgDA7uC-1At31aSJeBX2oBpHm7hwjJcgQjUZVqJUN7hEvNf1YhZ-7jKnC6QSYhNp6qhdndIpVdwPNU1jwymLKHIA7F5Tb5cVWJPwusnkl3gNBtKKC2Z-Tknw1aATjNs2glnYM4ZSDfM47P1aklwi5MOA6J3mHkMaBD2fmBrrXLisKr7VfYS5sNBxq6yo71tPBQsi4DOejBqA1jefhb6p7NWYm9HzvbOSahZxHung3KrwhcHJKEQUyr7wXQ

$ step-cli crypto jwt inspect --insecure < /var/run/secrets/kubernetes.io/serviceaccount/token
{
  "header": {
    "alg": "RS256",
    "kid": "Vl51zZ3KYnOfa9xRK6c4fc64mIzW637JTdZNxWsim80"
  },
  "payload": {
    "aud": [
      "https://kubernetes.default.svc.cluster.local"
    ],
    "exp": 1720118667,
    "iat": 1688582667,
    "iss": "https://kubernetes.default.svc.cluster.local",
    "kubernetes.io": {
      "namespace": "default",
      "pod": {
        "name": "curl-2",
        "uid": "4b50f852-1c67-4d12-80ef-44fc2ac167f0"
      },
      "serviceaccount": {
        "name": "default",
        "uid": "46c5f856-fc49-46ec-a678-dda775c7413d"
      },
      "warnafter": 1688586274
    },
    "nbf": 1688582667,
    "sub": "system:serviceaccount:default:default"
  },
  "signature": "fnEhHvf4WC1QGobRTNpauMO_nXi36L_dYouTDsaO52B4bOC_2Ea_yqJmR44x4LMI3SaiPsynl5a_k0BWso_Ufx8YXU08wgDA7uC-1At31aSJeBX2oBpHm7hwjJcgQjUZVqJUN7hEvNf1YhZ-7jKnC6QSYhNp6qhdndIpVdwPNU1jwymLKHIA7F5Tb5cVWJPwusnkl3gNBtKKC2Z-Tknw1aATjNs2glnYM4ZSDfM47P1aklwi5MOA6J3mHkMaBD2fmBrrXLisKr7VfYS5sNBxq6yo71tPBQsi4DOejBqA1jefhb6p7NWYm9HzvbOSahZxHung3KrwhcHJKEQUyr7wXQ"
}
```

##### _token_ with audience

If we're going to use the token in other places,
like authenticating to a different service that isn't kubernetes,
the proper way to do it is to request a token with a specific audience that the other service will check against,
preventing lateral movement / misuse of existing tokens.

To get a token with a specific audience,
we'll need an API call.
I think you just somehow have to be aware of your own Namespace and ServiceAccount to make the call
(the namespace is projected into `/var/run/secrets/kubernetes.io/serviceaccount/namespace`),
plus have the appropriate RBAC permissions:

RBAC:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tokenrequest
rules:
  - apiGroups: [""]
    resources:
      - "serviceaccounts/token"
    verbs:
      - "create"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: my-serviceaccount-tokenrequest
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tokenrequest
subjects:
  - kind: ServiceAccount
    name: my-serviceaccount
    namespace: my-namespace
```

Go code to request a token:

```go
package main

import (
    "context"
    "fmt"

    authenticationv1 "k8s.io/api/authentication/v1"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    corev1 "k8s.io/client-go/kubernetes/typed/core/v1"
    "k8s.io/client-go/rest"
)

func main() {
    k8sconf, err := rest.InClusterConfig()
    if err != nil {
        panic(err)
    }

    coreClient, err := corev1.NewForConfig(k8sconf)
    if err != nil {
        panic(err)
    }

    ctx := context.Background()
    res, err := coreClient.ServiceAccounts("my-namespace").CreateToken(ctx, "my-serviceaccount", &authenticationv1.TokenRequest{
        Spec: authenticationv1.TokenRequestSpec{
            Audiences: []string{"my-audience"},
        },
    }, metav1.CreateOptions{})
    if err != nil {
        panic(err)
    }
    fmt.Println(res.Status.Token)
}
```

#### _verify_ a token

So someone else forced their request upon you with a bearer token.
How do you verify it?

##### _tokenreview_

With the TokenReview API,
we can hand the token to kubernetes and it will tell us some info about it.
We'll also need RBAC,
the builtin `system:auth-delegator` ClusterRole is made for services that need to check tokens,
note that it needs to be granted as a ClusterRoleBinding and not just a RoleBinding.

`system:auth-delegator` looks like:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:auth-delegator
rules:
  - apiGroups:
      - authentication.k8s.io
    resources:
      - tokenreviews
    verbs:
      - create
  - apiGroups:
      - authorization.k8s.io
    resources:
      - subjectaccessreviews
    verbs:
      - create
```

and Go code to verify the token might look like:

```go
package main

import (
    "fmt"
    "log"
    "net/http"
    "slices"
    "strings"

    authentication_v1 "k8s.io/api/authentication/v1"
    meta_v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    authenticationv1 "k8s.io/client-go/kubernetes/typed/authentication/v1"
    "k8s.io/client-go/rest"
)

const audience = "my-audience"

func main() {
    k8sconf, err := rest.InClusterConfig()
    if err != nil {
        panic(err)
    }
    authClient, err := authenticationv1.NewForConfig(k8sconf)
    if err != nil {
        panic(err)
    }

    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        token := r.Header.Get("authorization")
        token = strings.TrimPrefix(token, "Bearer ")
        review, err := authClient.TokenReviews().Create(r.Context(), &authentication_v1.TokenReview{
            Spec: authentication_v1.TokenReviewSpec{
                Audiences: []string{audience}, // the audience value this service expects to see
                Token:     token,
            },
        }, meta_v1.CreateOptions{})
        fmt.Printf("%v %#v\n", err, review.Status)
        if err != nil || !review.Status.Authenticated || !slices.Contains(review.Status.Audiences, audience) {
            http.Error(w, "unauthorized", http.StatusUnauthorized)
            return
        }
        fmt.Println(review.Status.User.Username)
        fmt.Println(review.Status.User.Groups)
    })

    log.Fatalln(http.ListenAndServe(":8080", nil))
}
```

##### _oidc_

Alternatively, we can authenticate using OIDC.
Note here we need to inject a custom client to talk to the kubernetes api server,
which uses its own ca certificate and requires auth.
But no additional RBAC necessary for this.

```go
package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/coreos/go-oidc/v3/oidc"
	"golang.org/x/oauth2"
)

const audience = "my-audience"

func main() {
	caPEM, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
	if err != nil {
		panic(err)
	}
	pool := x509.NewCertPool()
	ok := pool.AppendCertsFromPEM(caPEM)
	if !ok {
		panic(ok)
	}

	saToken, err := os.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/token")
	if err != nil {
		panic(err)
	}

	ctx := context.Background()
	ctx = oidc.ClientContext(ctx, &http.Client{
		Transport: &oauth2.Transport{
			Source: oauth2.StaticTokenSource(&oauth2.Token{
				AccessToken: string(saToken),
			}),
			Base: &http.Transport{
				TLSClientConfig: &tls.Config{
					RootCAs: pool,
				},
			},
		},
	})
	provider, err := oidc.NewProvider(ctx, "https://kubernetes.default.svc.cluster.local")
	if err != nil {
		panic(err)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		token := r.Header.Get("authorization")
		token = strings.TrimPrefix(token, "Bearer ")

		id, err := provider.Verifier(&oidc.Config{
			SkipClientIDCheck: true,
		}).Verify(r.Context(), token)
		log.Println(id, err)
		if err != nil {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
	})
	log.Fatalln(http.ListenAndServe(":8080", nil))
}
```
