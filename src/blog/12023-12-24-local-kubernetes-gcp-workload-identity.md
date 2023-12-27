# workload identity for local kubernetes clusters

## no secrets anywhere

### _workload_ identity in any k8s cluster

One of the things I like about GCP is that every workload
always has an identity (GCP service account) attached,
and the GCP client libraries can just magically pick up the identity and make authenticated calls.

For Google managed kubernetes (GKE), there's a layer of indirection,
as you (typically) don't want everything in your cluster running on the same identity.
This is [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity):
your Kubernetes service accounts are annotated
with `iam.gke.io/gcp-service-account=GSA_NAME@GSA_PROJECT.iam.gserviceaccount.com`
and a GKE metadata agent running as a daemonset on your nodes serves the GCP metadata endpoint
with the appropriate info.
The GCP service account needs to grant permissions to `GSA_PROJECT.svc.id.goog[NAMESPACE/KSA_NAME]`,
but otherwise, the workload itself doesn't need to change.

For Kubernetes running anywhere else,
there's [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation-with-kubernetes)
to trust AWS, Azure, or any OIDC provider,
including the one built into Kubernetes (Service Account Issuer Discovery).
Your K8s api endpoint doesn't even need to be exposed to the world.
Setup is slightly more involved (workload identity pool + provider),
and the workload definitions need to change:
you'll need to pass `GOOGLE_APPLICATION_CREDENTIALS`,
and mount both a token and the generated config.
The client libraries start with the env,
read the file,
then read the token.
One hiccup was that depending on the library,
you may need to explicitly pass the google project.

generated config:

```json
{
  "type": "external_account",
  "audience": "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID",
  "subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
  "token_url": "https://sts.googleapis.com/v1/token",
  "credential_source": {
    "file": "/var/run/service-account/token",
    "format": {
      "type": "text"
    }
  },
  "service_account_impersonation_url": "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/GSA_NAME@GSA_PROJECT.iam.gserviceaccount.com:generateAccessToken"
}
```

application spec:

```yaml
spec:
  template:
    spec:
      containers:
        - env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /var/run/service-account/gcp-workload-identity.json
          volumeMounts:
            - name: token
              mountPath: "/var/run/service-account"
              readOnly: true
      serviceAccountName: my-app
      volumes:
        - name: token
          projected:
            sources:
              - serviceAccountToken:
                  audience: https://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
                  expirationSeconds: 3600
                  path: token
              - configMap:
                  name: gcp-workload-identity
```
