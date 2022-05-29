# buildkite first impressions

## Yet another CI SaaS


### _buildkite_

[buildkite](https://buildkite.com/) is a CI system where you provide the runners,
and it (the SaaS) hosts the dashboards and schedulers.
Builds can be triggered via webhook integration with a few code hosts,
manually, cron, or via api.

#### _agents_

[Agents](https://buildkite.com/docs/agent/v3)
are what you run to run your builds.
By themselves, they aren't isolated, relying on tools configured on the host.
The build steps are just that, commands run on the host,
which makes it awkward to do versioned / isolated tools.

#### _pipeline_ config

The build pipeline is more interesting:
the first pass of the pipeline is in the dashboard
(configurable via api, eg [terraform provider](https://registry.terraform.io/providers/buildkite/buildkite/latest/docs)).
Once running, the pipeline can then be extended/modified by uploading new parts.

In the dashboard:

```yaml
steps:
  - label: ":pipeline: Pipeline upload"
    command: buildkite-agent pipeline upload .buildkite/pipeline.yaml
```

Then in your repo's .buildkite/pipeline.yaml you can configure your builds
in a way that's source controlled (and modifiable in prs...).

```yaml
steps:
  - command: |
      docker run --rm -it \
        -v ${GOMODCACHE}:/go/pkg/mod \
        -v ${GOCACHE}:/root/.cache/go-build \
        -v ${BUILDKITE_BUILD_CHECKOUT_PATH}:/workspace \
        -w /workspace \
        $GOIMAGE \
        go build ./...
```
