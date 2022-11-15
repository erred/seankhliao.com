# circleci gcp workload identity federation

## look ma! no secrets

### _workload_ identity federation

The idea is:
your runtime environment gives you an identity,
and you can go exchange that identity for a different one,
which has the access you need.

Today, we'll be experimenting with using CircleCI's OIDC identity to get a Google Cloud Platform identity,
both to push images and to sign them.

#### _GCP_ setup

First we'll want to setup GCP to trust our CircleCI org:

```terraform
locals {
  project       = "com-seankhliao"
  circleci_org  = "e215a767-1102-43db-bab3-0a7246a49b03"
  circleci_proj = "daec1ef0-490b-4837-86f2-28e48b76411e"
}


# Pool of identities
resource "google_iam_workload_identity_pool" "pool" {
  project                   = local.project
  workload_identity_pool_id = "sigstore-oidc-test"
}

# CircleCI identities in the pool
resource "google_iam_workload_identity_pool_provider" "circleci" {
  project                            = local.project
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "circleci"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.project_id" = "assertion['oidc.circleci.com/project-id']"
  }
  oidc {
    allowed_audiences = [
      local.circleci_org
    ]
    issuer_uri = "https://oidc.circleci.com/org/${local.circleci_org}"
  }
}

# Service account for projects to impersonate as
resource "google_service_account" "circleci" {
  account_id = "sigstore-oidc-test-circleci"
  project = "com-seankhliao"
}

# granting all workflow runs on the project the permissions to impersonate the service account
resource "google_service_account_iam_member" "circleci_wi" {
  service_account_id = google_service_account.circleci.id
  member = "principalSet://iam.googleapis.com/projects/330311169810/locations/global/workloadIdentityPools/sigstore-oidc-test/attribute.project_id/${local.circleci_proj}"
  role               = "roles/iam.workloadIdentityUser"
}

# granting the service account access to create tokens about itself
resource "google_service_account_iam_member" "circleci_token" {
  service_account_id = google_service_account.circleci.id
  member             = "serviceAccount:${google_service_account.circleci.email}"
  role               = "roles/iam.serviceAccountTokenCreator"
}

# granting the service account permissions to push to an Artifact Repository
resource "google_artifact_registry_repository_iam_member" "build-circleci" {
  project    = local.project
  location   = "us-central1"
  repository = "build"
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.circleci.email}"
}
```

#### _circleci_ setup

Then we can use the identity that circleci gives us (if we attach any context),
and go exchange that for a GCP identity.
With the GCP identity,
we can get identity and access tokens for pushing and signing respectively.

```yaml
version: 2.1

jobs:
  all:
    # just need an executor
    docker:
      - image: golang:alpine
    environment:
      # keyless signing is still experimental
      COSIGN_EXPERIMENTAL: "1"
      # artifact repository to push in to
      KO_DOCKER_REPO: "us-central1-docker.pkg.dev/com-seankhliao/build"
      # service account to impersonate as
      SERVICE_ACCOUNT_EMAIL: "sigstore-oidc-test-circleci@com-seankhliao.iam.gserviceaccount.com"
    steps:
      # need code to build
      - checkout
      # main run
      - run:
          name: build-push
          command: |
            # basic tools
            apk add curl jq

            # exchange our local token for a GCP token
            STS_TOKEN=$(jq -n \
              --arg token "${CIRCLE_OIDC_TOKEN}" \
              '{
                audience:           "//iam.googleapis.com/projects/330311169810/locations/global/workloadIdentityPools/sigstore-oidc-test/providers/circleci", 
                grantType:          "urn:ietf:params:oauth:grant-type:token-exchange",
                requestedTokenType: "urn:ietf:params:oauth:token-type:access_token",
                scope:              "https://www.googleapis.com/auth/cloud-platform",
                subjectTokenType:   "urn:ietf:params:oauth:token-type:id_token",
                subjectToken:       $token
              }' | \
            curl -0 --fail -s \
              https://sts.googleapis.com/v1/token \
              -H 'Content-Type: text/json; charset=utf-8' \
              -d @- | \
            jq -r .access_token)
            
            # impersonate as the service account and generate an identity token for signing
            IDENTITY_TOKEN=$(jq -n \
              '{
                audience: "sigstore",
                includeEmail: true
              }' | \
            curl -0 --fail -s \
              https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${SERVICE_ACCOUNT_EMAIL}:generateIdToken \
              -H "Content-Type: text/json; charset=utf-8" \
              -H "Authorization: Bearer $STS_TOKEN" \
              -d @- | \
            jq -r .token)

            # impersonate as the service account and generate an access token for pushing to AR
            ACCESS_TOKEN=$(jq -n \
              '{
                scope: ["https://www.googleapis.com/auth/cloud-platform"]
              }' | \
            curl -0 --fail -s \
              https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${SERVICE_ACCOUNT_EMAIL}:generateAccessToken \
              -H "Content-Type: text/json; charset=utf-8" \
              -H "Authorization: Bearer $STS_TOKEN" \
              -d @- | \
            jq -r .accessToken)

            mkdir -p /go/bin
            # download ko for building & pushing
            curl -sL https://github.com/ko-build/ko/releases/download/v0.12.0/ko_0.12.0_Linux_x86_64.tar.gz | tar xzf - ko
            mv ko /go/bin/
            # download cosign for signing
            curl -sLo /go/bin/cosign https://github.com/sigstore/cosign/releases/download/v1.13.1/cosign-linux-amd64
            chmod +x /go/bin/*

            # use the access token to log in (~/.docker/config.json)
            ko login us-central1-docker.pkg.dev --username oauth2accesstoken --password "${ACCESS_TOKEN}"
            # build and push our image
            ko build --image-refs image.txt .

            # sign our image and push our signature
            # cosign is actually doing another exchange behind the scenes,
            # exchanging our GCP identity for a short-lived cert signed by fulcio
            cosign sign --identity-token "${IDENTITY_TOKEN}" $(cat image.txt)

            echo "=== image ==="
            cat image.txt

workflows:
  main:
    jobs:
      - all:
          context:
            # the job needs a context attached for CircleCI to set CIRCLE_OIDC_TOKEN
            # nothing needs to be in the context
            - empty-context
```
