# curl aws sts assumerolewithwebidentity

## curl ftw

### _assuming_ an AWS role with curl

So, OIDC token exchanges are all the rage.
They let you do away with long term secrets,
and use your local identity provider to attest who you are,
and assume a role in a different environment.

Here we're doing it with AWS's STS api using just `curl`.
The output for the sts api is... XML.
For some reason, [yq], the yaml tool, also handles XML,
so we use that to extract the interesting parts.

[yq]: https://github.com/mikefarah/yq

```sh
AWS_REGION= # region to operate in
ACCOUNT_ID= # account ID, not strictly necessary, but probably needed in ROLE_ARN
NAME= # choose a good name for this session
ROLE_ARN= # role to assume
OIDC_TOKEN= # token from third party allows to assume the role by trust policy

curl \
  -o assume_id.xml \
  -X POST \
  --url-query "Action=AssumeRoleWithWebIdentity" \
  --url-query "DurationSeconds=3600" \
  --url-query "RoleSessionName=${NAME}" \
  --url-query "RoleArn=${ROLE_ARN}" \
  --url-query "WebIdentityToken=${OIDC_TOKEN}" \
  --url-query "Version=2011-06-15" \
  "https://sts.${AWS_REGION}.amazonaws.com"

aws_res_prefix='.AssumeRoleWithWebIdentityResponse.AssumeRoleWithWebIdentityResult.Credentials'
export AWS_SESSION_TOKEN=$(yq e -p xml -o yaml "${aws_res_prefix}.SessionToken" assume_id.xml)
export AWS_SECRET_ACCESS_KEY=$(yq e -p xml -o yaml "${aws_res_prefix}.SecretAccessKey" assume_id.xml)
export AWS_ACCESS_KEY_ID=$(yq e -p xml -o yaml "${aws_res_prefix}.AccessKeyId" assume_id.xml)
```
