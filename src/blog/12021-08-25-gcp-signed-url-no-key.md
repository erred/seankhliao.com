# Google Cloud Storage Signed URLs without Service Account Keys

## no more passing keys, background auth everywhere

### _signed_ urls

So say you need to generate short lived urls granting access to a resource in GCP Cloud Storage,
because one of your third party SaaS solutions doesn't integrate with GCP
and their S3 integration is limited to actual AWS S3 and not just API compatible S3.

The Google documented way is to create a service account key and use that to sign URLs,
but we don't want that: managing service account keys is a PITA.

#### _permissions_

Because you never create a key,
you don't have anything to sign the url with.
So you need to grant `roles/iam.serviceAccountTokenCreator`
to allow the service to create tokens to sign things with.

If it's the service's identity is what has access to bucket contents,
then you'll be granting it the role on itself.

In terraform format with workload identity:

```terraform
resource "google_service_account" "your-sa" {
  account_id = "your-sa"
}
resource "google_service_account_iam_policy" "your-sa" {
  service_account_id = google_service_account.your-sa.name
  policy_data        = data.google_iam_policy.your-sa.policy_data
}
data "google_iam_policy" "your-sa" {
  binding {
    role = "roles/iam.workloadIdentityUser"
    members = [
      "serviceAccount:your-project.svc.id.goog[your-namespace/your-k8s-sa]",
    ]
  }
  binding {
    role = "roles/iam.serviceAccountTokenCreator"
    members = [
      "serviceAccount:your-sa@your-project.iam.gserviceaccount.com",
    ]
  }
}
```

#### _internet_ version

Obviously someone else also wants to do this and dumped it in a gist.

https://gist.github.com/pdecat/80f21e36583420abbfdeae0494a53501

#### _my_ version

I thought it could be shorter,
mainly taking advantage of the fact that all google api libraries know how to find/use default credentials.

```go
package main

import (
        "context"
        "fmt"
        "time"

        "cloud.google.com/go/compute/metadata"
        credentials "cloud.google.com/go/iam/credentials/apiv1"
        "cloud.google.com/go/storage"
        credentialspb "google.golang.org/genproto/googleapis/iam/credentials/v1"
)

func main() {
        ctx := context.Background()

        saEmail, _ := metadata.Email("default")
        iamClient, _ := credentials.NewIamCredentialsClient(ctx)
        defer iamClient.Close()

        u, _ := storage.SignedURL("bucket-name", "path/to/object", &storage.SignedURLOptions{
                GoogleAccessID: saEmail,
                SignBytes: func(b []byte) ([]byte, error) {
                        res, _ := iamClient.SignBlob(ctx, &credentialspb.SignBlobRequest{
                                Payload: b,
                                Name: saEmail,
                        })
                        return res.SignedBlob, nil
                },
                Method: "GET",
                Expires: time.Now().Add(5*time.Minute),
        })

        fmt.Println(u)
}
```
