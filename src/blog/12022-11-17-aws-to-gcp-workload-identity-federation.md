# aws to gcp workload identity federation

## config is king?

### _AWS_ workload, GCP resources

More workload identity, this time in the oppsoite direction.
Specifically, running the workload in Amazon Web Services (AWS)
Elastic Kubernetes Service (EKS),
accessing Google Cloud Platform (GCP) services.

There have been many blog posts on this.

#### _GCP_ cloud setup

On GCP, we need a workload identity pool associated with the AWS account.
Additionally, a service account with permissions allowing an AWS Role to impersonate it.
Permissions to other GCP resources should be granted to the service account.

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
  project        = "project-id"
  project_number = "000000000"
  aws_account_id = "000000000"
}

resource "google_iam_workload_identity_pool" "p" {
  project                   = local.project
  workload_identity_pool_id = "workload-pool-id"
}

#
# provider within the pool
# maps to individual AWS accounts
#
resource "google_iam_workload_identity_pool_provider" "p" {
  project                            = local.project
  workload_identity_pool_id          = google_iam_workload_identity_pool.p.workload_identity_pool_id
  workload_identity_pool_provider_id = "workload-provider-id"
  attribute_mapping = {
    "google.subject"        = "assertion.arn"
    "attribute.aws_account" = "assertion.account"
    # an attribute with the full arn of the assumed role
    # source attribute is arn:aws:sts::account:assumed-role/role-to-be-assumed/id
    "attribute.aws_role" = "assertion.arn.contains('assumed-role') ? assertion.arn.extract('{account_arn}assumed-role/') + 'assumed-role/' + assertion.arn.extract('assumed-role/{role_name}/') : assertion.arn"
  }
  aws {
    account_id = local.aws_account_id
  }
}

resource "google_service_account" "s" {
  project    = local.project
  account_id = "gcp-service-account-name"
}

resource "google_service_account_iam_member" "s" {
  service_account_id = google_service_account.a.id
  role               = "roles/iam.workloadIdentityUser"
  # principalSet matches anything with the given attribute 
  # here we're matching on assumed role arn
  member             = "principalSet://iam.googleapis.com/projects/${local.project_number}/locations/global/workloadIdentityPools/workload-pool-id/attribute.aws_role/arn:aws:sts::account:assumed-role/role-for-irsa"
}
```

#### _AWS_ cloud setup

We'll need an AWS Role and with a trust policy to allow the Kubernetes service account to assume the role.
The OIDC provider is also necessary but out of scope.

```terraform
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.39.0"
    }
  }
}

locals {
  oidc_provider = "..."
  oidc_provider_arn = "arn:aws:iam::000000000:oidc-provider/${local.oidc_provider}"
}

resource "aws_iam_role" "r" {
  name = "role-for-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Sid    = "r1"
      Principal = {
        # built in federated identity provider
        Federated = local.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:sub" = "system:serviceaccount:k8s-namespace:serviceaccount-name"
        }
      }
    }]
  })
}
```

#### _AWS_ workload setup

We'll need a kubernetes service account, annotated with the AWS Role it can use as an identity.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: serviceaccoount-name
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::account:role/role-for-irsa
```

The GCP SDK can use a config file to handle the token exchange.
It needs an audience referencing the workload identity pool provider,
and the intended service account to impersonate.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-name
data:
  creds.json: |
    {
      "type": "external_account",
      "audience": "//iam.googleapis.com/projects/project-number/locations/global/workloadIdentityPools/workload-pool-id/providers/workload-provider-id",
      "subject_token_type": "urn:ietf:params:aws:token-type:aws4_request",
      "token_url": "https://sts.googleapis.com/v1/token",
      "credential_source": {
        "environment_id": "aws1",
        "region_url": "http://169.254.169.254/latest/meta-data/placement/availability-zone",
        "url": "http://169.254.169.254/latest/meta-data/iam/security-credentials",
        "regional_cred_verification_url": "https://sts.{region}.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15",
        "imdsv2_session_token_url": "http://169.254.169.254/latest/api/token"
      },
      "service_account_impersonation_url": "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/gcp-service-account-name@project-id.iam.gserviceaccount.com:generateAccessToken"
    }
```

The pod needs to use the service account with the role annotation.
Additionally, it needs to mount the above config file, and point `GOOGLE_APPLICATION_CREDENTIALS` to it.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-name
spec:
  serviceAccountName: serviceaccount-name
  containers:
    - name: container-name
      image: image-ref
      env:
        - name: GOOGLE_APPLICATION_CREDENTIALS
          value: /var/run/secrets/google/creds.json
      volumeMounts:
        - name: google
          mountPath: /var/run/secrets/google
  volumes:
    - name: google
      configMap:
        name: configmap-name
```

#### _AWS_ code setup - normal

The GCP Go SDK has built in support to do the necessary token exchanges with AWS STS.
All it needs is for `GOOGLE_APPLICATION_CREDENTIALS` to point to a config file (see above).

```go
package main

import (
        "context"
        "fmt"
        "os"

        "cloud.google.com/go/storage"
        "golang.org/x/exp/slog"
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

func run(lg *slog.Logger) error {
        ctx := context.Background()
        // Example: GCP storage client
        client, err := storage.NewClient(ctx)
        if err != nil {
                return fmt.Errorf("create GCP Cloud Storage client: %w", err)
        }

        _ = client
        return nil
}
```

#### _AWS_ code setup - manual token exchange

If for whatever reason, IMDSv2 is broken on your cluster 
(maybe someone forgot to set `ec2:MetadataHttpPutResponseHopLimit` to 2),
you can do a manual token exchange to generate the access tokens for sdk use.

Note: you'll want to remove the `GOOGLE_APPLICATION_CREDENTIALS` env and the file it points to.

```go
package main

import (
        "context"
        "encoding/json"
        "fmt"
        "net/http"
        "net/url"
        "os"
        "sort"
        "strconv"
        "strings"
        "time"

        credentials "cloud.google.com/go/iam/credentials/apiv1"
        "cloud.google.com/go/iam/credentials/apiv1/credentialspb"
        "cloud.google.com/go/storage"
        "github.com/aws/aws-sdk-go-v2/aws"
        signer "github.com/aws/aws-sdk-go-v2/aws/signer/v4"
        "github.com/aws/aws-sdk-go-v2/service/sts"
        "golang.org/x/exp/slog"
        "golang.org/x/oauth2"
        "google.golang.org/api/option"
        gcpsts "google.golang.org/api/sts/v1"
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

func run(lg *slog.Logger) error {
        ctx := context.Background()

        stsTS, err := NewAWSToGCPTokenSource(ctx)
        if err != nil {
                return fmt.Errorf("create gcp sts token source: %w", err)
        }
        ts, err := NewGCPServiceAccountTokenSource(ctx, stsTS)
        if err != nil {
                return fmt.Errorf("create gcp service account token source: %w", err)
        }

        // Example: GCP storage client
        client, _ := storage.NewClient(ctx,
                // use our access tokens
                option.WithTokenSource(ts),
        )
        _ = client
        return nil
}

type AWSToGCPTokenSource struct {
        s *gcpsts.Service
}

func NewAWSToGCPTokenSource(ctx context.Context) (*AWSToGCPTokenSource, error) {
        client, err := gcpsts.NewService(ctx, option.WithoutAuthentication())
        if err != nil {
                return nil, fmt.Errorf("create gcp sts service client: %w", err)
        }

        return &AWSToGCPTokenSource{
                s: client,
        }, nil
}

// Token implements oauth2.TokenSource by taking a local filesystem mounted EKS IRSA token,
// assuming the associated AWS Role, and exchanging that for a GCP STS token.
func (g *AWSToGCPTokenSource) Token() (*oauth2.Token, error) {
        // potential input values
        region := os.Getenv("AWS_REGION")    // injected by IRSA
        roleARN := os.Getenv("AWS_ROLE_ARN") // injected by IRSA
        gcpProjectNumber := "000000000"
        gcpWorkloadPool := "workload-pool-id"
        gcpProvider := "workload-provider-id"
        gcpTargetResource := "//iam.googleapis.com/projects/" + gcpProjectNumber + "/locations/global/workloadIdentityPools/" + gcpWorkloadPool + "/providers/" + gcpProvider

        // get the projected OIDC token within EKS
        // this has an audience of STS and is updated over time
        b, err := os.ReadFile("/var/run/secrets/eks.amazonaws.com/serviceaccount/token")
        if err != nil {
                return nil, fmt.Errorf("read mounted eks token: %w", err)
        }
        webToken := string(b)

        // assume the role mapped by IRSA using the OIDC token
        ctx := context.Background()
        tsNow := strconv.FormatInt(time.Now().Unix(), 10)
        assumed, err := sts.New(sts.Options{
                Region: region,
        }).AssumeRoleWithWebIdentity(ctx, &sts.AssumeRoleWithWebIdentityInput{
                RoleArn:          &roleARN,
                RoleSessionName:  &tsNow,
                WebIdentityToken: &webToken,
        })
        if err != nil {
                return nil, fmt.Errorf("assume role: %w", err)
        }

        // prepare and sign an HTTP request equivalent to a call to AWS sts.GetCallerIdentity.
        // hand the resulting URL / Method / Headers to GCP STS, which will use it to confirm our identity,
        // and give us a token.
        gciReq, err := http.NewRequest(
                http.MethodPost,
                "https://sts."+region+".amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15",
                nil,
        )
        if err != nil {
                return nil, fmt.Errorf("create fake request: %w", err)
        }
        // equivalent to setting an audience in oauth2
        gciReq.Header.Set(
                "x-goog-cloud-target-resource",
                gcpTargetResource,
        )
        err = signer.NewSigner().SignHTTP(ctx,
                aws.Credentials{
                        AccessKeyID:     *assumed.Credentials.AccessKeyId,
                        SecretAccessKey: *assumed.Credentials.SecretAccessKey,
                        SessionToken:    *assumed.Credentials.SessionToken,
                        CanExpire:       true,
                        Expires:         *assumed.Credentials.Expiration,
                },
                gciReq,
                // empty string representing the body
                "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
                "sts",
                os.Getenv("AWS_DEFAULT_REGION"),
                time.Now(),
        )
        if err != nil {
                return nil, fmt.Errorf("sign fake GetCallerIdentity request: %w", err)
        }

        var headers []map[string]string
        // host header is implicit in Go's net/http.Request
        headers = append(headers, map[string]string{
                "key":   "host",
                "value": gciReq.Host,
        })
        for k, vs := range gciReq.Header {
                headers = append(headers, map[string]string{
                        "key":   strings.ToLower(k),
                        "value": vs[0],
                })
        }
        // header fields should be sorted?
        sort.Slice(headers, func(i, j int) bool {
                return headers[i]["key"] < headers[j]["key"]
        })

        // GCP STS expects a url encoded json object containing the request data
        b, err = json.Marshal(map[string]any{
                "url":     gciReq.URL.String(),
                "method":  gciReq.Method,
                "headers": headers,
        })
        if err != nil {
                return nil, fmt.Errorf("json encode sts req: %w", err)
        }
        escaped := url.QueryEscape(string(b))

        // exchange for a GCP STS token associated with our pool
        res, err := g.s.V1.Token(&gcpsts.GoogleIdentityStsV1ExchangeTokenRequest{
                Audience:           gcpTargetResource,
                GrantType:          "urn:ietf:params:oauth:grant-type:token-exchange",
                RequestedTokenType: "urn:ietf:params:oauth:token-type:access_token",
                Scope:              "https://www.googleapis.com/auth/cloud-platform",
                SubjectToken:       escaped,
                SubjectTokenType:   "urn:ietf:params:aws:token-type:aws4_request",
        }).Do()
        if err != nil {
                return nil, fmt.Errorf("gcp sts exchange: %w", err)
        }

        exp := time.Now().Add(time.Duration(res.ExpiresIn) * time.Second)
        return &oauth2.Token{
                AccessToken: res.AccessToken,
                Expiry:      exp,
        }, nil
}

type GCPServiceAccountTokenSource struct {
        g *credentials.IamCredentialsClient
}

func NewGCPServiceAccountTokenSource(ctx context.Context, ts oauth2.TokenSource) (*GCPServiceAccountTokenSource, error) {
        client, err := credentials.NewIamCredentialsClient(ctx, option.WithTokenSource(ts))
        if err != nil {
                return nil, fmt.Errorf("create gcp credentials client: %w", err)
        }

        return &GCPServiceAccountTokenSource{
                g: client,
        }, nil
}

// Token implements oauth2.TokenSource by exchanging a GCP STS token
// for an GCP access token from the impersonated service account
func (g *GCPServiceAccountTokenSource) Token() (*oauth2.Token, error) {
        // potential input values
        gcpEmail := "gcp-service-account-name@project-id.iam.gserviceaccount.com"

        ctx := context.Background()
        // impersonate the service accoutn and generate an access token
        res, err := g.g.GenerateAccessToken(ctx, &credentialspb.GenerateAccessTokenRequest{
                Name:  "projects/-/serviceAccounts/" + gcpEmail,
                Scope: []string{"https://www.googleapis.com/auth/cloud-platform"},
        })
        if err != nil {
                return nil, fmt.Errorf("generate GCP access token: %w", err)
        }

        return &oauth2.Token{
                AccessToken: res.AccessToken,
                Expiry:      res.ExpireTime.AsTime(),
        }, nil
}
```
