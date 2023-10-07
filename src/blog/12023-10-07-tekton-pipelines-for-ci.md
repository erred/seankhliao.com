# tekton pipelines for ci

## k8s yaml all the things

### _tekton_ pipelines for ci

I was using [Buildkite](https://buildkite.com/) for my CI.
And there wasn't much wrong with it,
besides the somewhat janky docker builder support.
I even figured out how to make it just pull from a
[central pipeline repo](https://github.com/erred/buildkite-pipelines)
so I don't have to update every repo's pipeline definition every time I thought of an improvement.

But I wanted something I fully controlled,
and decided it would be [Tekton](https://tekton.dev/).

#### _tekton_ pipeline

In Tekton, you have `Task` as a linear sequence of steps,
and `Pipeline` as a DAG of `Task`.
Each step is container image with optionally injected scripts.
`TaskRun` and `PipelineRun` are instances of `Task` and `Pipeline`,
with `TaskRun` mapping to an actual Kubernetes `Pod`.

This feels ok...
until when you realize that you can only parallelize across `Task`,
but because `Task` are different pods,
you can't easily share a previous workspace,
like a checkout of your source repo.
Also, because everything is K8s flavoured YAML,
it's quite verbose and takes up a lot of vertical space.

#### _tekton_ triggers

The Triggers subproject is essentially a pod listening on HTTP
and a lot of YAML to turn an incoming request into a `TaskRun` or `PipelineRun`.
An `EventListener` will create a `Deployment` and a `Service`,
and will watch for associated `Trigger` resources to decide how to process incoming requests.
Each `Trigger` is composed of `Interceptor` to filter out requests or add attributes,
`TriggerBinding` to map request attributes to short names (params),
and `TriggerTemplate` to take those short names and template out the actual resource.
I can't help but feel there's too many layers just to pass an incoming request attribute to a task:
once in interceptor (if it needs preprocessing),
once in `TriggerBinding`,
twice in `TriggerTemplate` (declared and actual use site),
and with a referenced `Pipeline` twice more to reference and use, and twice more in the actual `Task`.

Anyway, my current setup is at [seankhliao/k8s-infra/ihwa/tekton-builds](https://github.com/seankhliao/k8s-infra/tree/42e6ad460e5ae702aa6a279350ceac95c03ffcc1/ihwa/tekton-builds),
triggered by a [custom post-receive git hook](https://github.com/seankhliao/githook/tree/9c793d7a6515ecd2b99781584027d8ef987540e2/cmd/post-receive)

I can't help but feel like it could all be simpler as just a DAG of steps,
triggered directly from the incoming object?
