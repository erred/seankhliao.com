# curl aws sigv4

## signed requests the easy way

### _curl_ aws sigv4

So, say you've obtained some AWS credentials without using the `aws` CLI
(see [previous post]).
Now you want to make API calls,
and we're not going to install the CLI now!

AWS API uses an interesting auth mechanism where you sign the contents of your request,
rather than just presenting the token.
`curl` thankfully learned how to do this via its `--aws-sigv4` flag.

Woe unto me who didn't read the AWS docs for this [header] [query param]
(but also the docs suck).

- `X-Amz-Target`: a combination of the service and the method, get the value from the API examples...
- `X-Amz-Security-Token`: a required field if you used STS to obtain your ACCESS/SECRET keys.
- `Content-Type`, body (min: `{}`): required fields too or the api returns weird errors
- `--user $KEY_ID:$SECRET_KEY` + `--aws-sigv4 aws:amz:$REGION:$SERVICE`:
  telling curl to do the signature calculations,
  while in theory it can guess the region and service from the URL,
  it's probably more reliable to provide it yourself.
  The serivce value is the same one used in ARNs (and probably the same one in most URLs).

[previous post]: ./12023-05-27-curl-aws-sts-assumerolewithwebidentity.md
[header]: https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-auth-using-authorization-header.html
[query param]: https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html

```sh
curl \
  -X POST \
  -H 'X-Amz-Target: AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken' \
  -H "X-Amz-Security-Token: ${AWS_SESSION_TOKEN}" \
  -H 'Content-Type: application/x-amz-json-1.1' \
  --user "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" \
  --aws-sigv4 "aws:amz:${AWS_REGION}:ecr" \
  -d '{}' \
  "https://ecr.${AWS_REGION}.amazonaws.com"
```
