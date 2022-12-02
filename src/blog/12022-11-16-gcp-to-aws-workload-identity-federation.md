# GCP to AWS workload identity federation

## built in platform, lacklustre sdk

### _GCP_ workload, AWS resources

More workload identity.
This time we're running a workload within Google Cloud Platform (GCP),
specifically Google Kubernetes Engine (GKE),
and we're trying to access Amazon Web Service (AWS) resources.

#### _AWS_ cloud setup

On AWS the setup is called
[IAM identity federation](https://aws.amazon.com/identity/federation/),
or something similar.
If you look around long enough,
you'll eventually realize that some providers are special and built in,
like the [Google provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
needed  for access from GCP.

All we need is a Role for other resources/policies to reference when granting permissions,
and a policy on the role detailing what to allow to assume the role.
To control who to allow, 
we can use [identity token fields](https://cloud.google.com/docs/authentication/token-types#id-contents),
though for some reason, the audience is under `oaud`.
In terraform this looks like:

```terraform
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.39.0"
    }
  }
}

resource "aws_iam_role" "r" {
  name = "role-to-be-assumed"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Sid    = "r1"
      Principal = {
        # built in federated identity provider
        Federated = "accounts.google.com"
      }
      Condition = {
        StringLike = {
          # sub (subject) appears to be a required condition somewhere.
          # For service accounts, this maps to a numeric account id,
          # which makes it harder to identify.
          # We're just going to allow everything use the other fields.
          "accounts.google.com:sub" = "*"
        }
        StringEquals = {
          # You can provide an audience when calling generateIdToken
          # This represents the intended recipient of the identity token.
          "accounts.google.com:oaud" = "sts",
          # This is the main check we want to use since it's easier to match.
          "accounts.google.com:email" = "xcloud-iam-fed-demo@snyk-main.iam.gserviceaccount.com"
        }
      }
    }]
  })
}
```

This [blog post](https://jpassing.com/2021/10/05/authenticating-to-aws-by-using-a-google-cloud-service-account-and-assumerolewithwebidentity/)
was a good reference point on the smae topic.

#### _GCP_ cloud setup

On the GCP side where we're running our workload,
we'll want [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
on our GKE cluster.

We'll also need a service account and rolebindings to associate it with the Kubernetes service account
our workload runs with.

```terraform
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.43.0"
    }
  }
}

locals {
  project             = "project-id"
  k8s_namespace       = "k8s-namespace-name"
  k8s_service_account = "k8s-service-account-name"
}

# service account that's going to be associated with the kubernetes workload
resource "google_service_account" "s" {
  project    = local.project
  account_id = "gcp-service-account-name"
}

# granting the kubernetes service account permissions to use this service account
resource "google_service_account_iam_member" "gke" {
  service_account_id = google_service_account.s.id
  member             = "serviceAccount:${local.project}.svc.id.goog[${local.k8s_namespace}/${local.k8s_service_account}]"
  role               = "roles/iam.workloadIdentityUser"
}
```

#### _GCP_ workload setup

Our Kubernetes pod will need a serviceaccount attached,
with annotations pointing to the GCP service account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: service-account-name
  annotations:
    iam.gke.io/gcp-service-account: gcp-service-account-name@project-id.iam.gserviceaccount.com
```

#### _GCP_ code setup

Finally, we get to our code.
The AWS SDK doesn't appear to make any special considerations for running in external clouds,
So we're responsible for wiring up the GCP token provider with the
AWS role credentials provider.

```go
package main

import (
        "context"
        "fmt"
        "net/http"
        "os"

        "github.com/aws/aws-sdk-go-v2/aws"
        "github.com/aws/aws-sdk-go-v2/config"
        "github.com/aws/aws-sdk-go-v2/credentials/stscreds"
        "github.com/aws/aws-sdk-go-v2/service/s3"
        "github.com/aws/aws-sdk-go-v2/service/sts"
        "golang.org/x/oauth2"
        "golang.org/x/exp/slog"
        "google.golang.org/api/idtoken"
)

func main() {
        lgh := slog.HandlerOptions{
                Level: slog.DebugLevel,
        }.NewJSONHandler(os.Stderr)
        lg := slog.New(lgh)

        err := run(lg)
        if err != nil {
                lg.Error("run", err)
                os.Exit(1)
        }
}

type GCPTokenGenerator struct {
        ts oauth2.TokenSource
}

// GetIdentityToken implements the stscreds.IdentityTokenGenerator interface for refreshing
// identiy tokens on demand.
func (g *GCPTokenGenerator) GetIdentityToken() ([]byte, error) {
        token, err := g.ts.Token()
        if err != nil {
                return nil, fmt.Errorf("generate gcp id token: %w", err)
        }
        return []byte(token.AccessToken), nil
}

func run(lg *slog.Logger) error {
        // potential input values
        idTokenAudience := "sts"
        targetAWSRegion := "us-east-1"
        targetAWSRoleARN := "arn:aws:iam::account:role/role-to-be-assumed"

        // setup a GCP id token generator
        ctx := context.Background()
        ts, err := idtoken.NewTokenSource(ctx, idTokenAudience)
        if err != nil {
                return fmt.Errorf("create GCP id token generator: %w", err)
        }

        // create a base AWS config
        cfg, err := config.LoadDefaultConfig(ctx)
        if err != nil {
                return fmt.Errorf("create base AWS config: %w", err)
        }

        cfg.Region = targetAWSRegion

        // update the credentials to use
        cfg.Credentials = aws.NewCredentialsCache(
                // credentials provider that will assume the role,
                // refreshing tokens on demand.
                stscreds.NewWebIdentityRoleProvider(
                        sts.NewFromConfig(cfg)
                        targetAWSRoleARN, 
                        &GCPTokenGenerator{ts: ts},
                ),
        )

        // Example: AWS S3 client
        client := s3.NewFromConfig(cfg)

        // use the client
        _ = client
        return nil
}
```
