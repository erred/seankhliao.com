# ensuring e2e tests with cosign

## how to make sure e2e tests are run

### _e2e_ tests

So our setup at $work is a bit questionable,
and the end-to-end tests really only work when deployed to a single environment.
Our CI/CD pipelines are loosely coupled,
so sometimes the only imput it gets is a container image tag,
but we still want to ensure that tests have passed before rolling things out to production.

Thinking long and hard about this:
the information "status of e2e test for this image" has to be stored somewhere,
and the key has to be the container image tag (or preferably image digest which is immutable).
What better place to store it than with the container itself, in the registry.

Now comes the question: what format to store it in?
It can be a label, a file, or something else.
Enter [cosign](https://cosign.dev).

#### _cosign_

`cosign` can sign containers,
giving you a way of recording trust in a way that's not easily forged.
So, run your e2e tests and if it succeeds, sign the image.
Come deploy time and you check for the appropriate signatures before rolling out.

There's also the problem of:
how do you ensure that your e2e test is actually running against the version it wants?
Say for example:

1. `v1` is deployed to staging
2. e2e tests are kicked off with the parameter `v1`
3. `v2` is deployed to staging
4. e2e tests for `v1` are actually run against `v1`
5. `v1` is signed

Right now, the only solution I can think of is having an API gateway
or service mesh that's aware of the multiple versions,
and have `e2e` tests specify addition header keys (maybe through a proxy)
that will ensure it gets routed to the correct revision.
