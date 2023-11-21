# blocking deletes with kyverno

## enforcing disabling deletion_protection first

### _kyverno_ to block deletes that will fail

With terraform resources,
you have things like
[aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket),
which to prevent you from accidentally destroying a bucket containing important information,
has a `force_destroy` argument.
In normal terraform usage,
if you forget to set it,
you'll run into an error,
you can go back to change your code to set it to `true`,
and run it again to destroy things.

At $work, we use [hashicorp/terraform-k8s](https://github.com/hashicorp/terraform-k8s)
(it's really bad, do not recommend).
Here, destroy runs are triggered by deleting the `Workspace` CRD,
which leads to the unfortunate situation where if you forgot to set `force_destroy` beforehand,
there's no way to go back and update it to `true`,
since the `Workspace` object is already in a deleting state,
and the operator won't try to pick up new changes to apply first.

After having to fix this a few times for different teams,
I came up with using a [kyverno](https://kyverno.io/)
policy to block deletes that will fail.
We block the delete operation if it affects a `Workspace` whose `force_destroy` variable isn't set.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: s3-force-destroy
spec:
  validationFailureAction: Enforce
  background: false
  rules:
    - name: s3-force-destroy
      match:
        any:
          - resources:
              kinds:
                - Workspace
              operations:
                - DELETE
      validate:
        message: |
          force_destroy must be set to destroy buckets
        deny:
          conditions:
            all:
              # NOTE: MUST use double quotes "" outside for yaml
              # and single quotes '' inside for JMESPath
              - key: "{{ request.oldObject.spec.variables[?key == 'force_destroy'].value | [0] }}"
                operator: Equals
                value: "false"
              # filtering because we didn't have the foresight to implement labels properly
              - key: "{{ contains(request.oldObject.spec.module.source, 's3-bucket') }}"
                operator: Equals
                value: true
```
