# krm functions

## unix tools for the cloud

### _composing_ tools

The pipe operator `|` is one of the great inventions of shells.
Tools didn't have to expand to cover every possible usecase,
they can be focused on their core usecase, output as text,
and leave it to the user to compose tools together
to suit their needs.
A weekness of the unix model has been that the output is typically
an unstructured stream of bytes (usually text).

This introduces some complexity as users now need to preprocess each output format,
before passing it to the next (a lot of `grep`, `cut`, `sed`, `awk` ...).
[PowerShell](https://docs.microsoft.com/en-us/powershell/) on Windows
has native structured objects,
while unix land has sort of settled on
[line delimited json](https://en.wikipedia.org/wiki/JSON_streaming#Line-delimited_JSON_2)
as the thing everyone can implement (hope you're good with `jq`).

#### _krm_ functions

For the brave new world of cloud native - kubernetes ecosystem,
we've tried helm (template engine) and all found it horrible,
so Config as Data is now in vogue,
especially the Kubernetes Resource Model variant
(see [previous post](12022-07-20-kubernetes-resource-model.md)).
This gives us the common structured object model that each tool needs to understand.

The other missing piece is the orchestrator to combine them all in a pipeline.
[kustomize](https://github.com/kubernetes-sigs/kustomize)
first came up with
[krm functions](https://github.com/kubernetes-sigs/kustomize/blob/master/cmd/config/docs/api-conventions/functions-spec.md)
as a way to specify custom intermediate processors.
They would just need to run in docker, take stdin and write to stdout.
Unfortunately, kustomize has quite some legacy:
all its options are generators/transormers,
but with an implicit builtin ordering that you just have to internalize.
There has been a new proposal for a
[Composition](https://github.com/kubernetes/enhancements/tree/master/keps/sig-cli/2299-kustomize-plugin-composition)
which becomes much more plugin centric.

The other major driver of KRM functions right now is [kpt](https://kpt.dev/).
Running docker containers is annoying, especially in a containerized environment,
so there are investigations into alternative
[function runtimes](https://github.com/GoogleContainerTools/kpt/issues/2567).
They also have a
[function catalog](https://catalog.kpt.dev/?id=curated-functions-catalog),
possibly before standardization of
[krm functions registry](https://github.com/kubernetes/enhancements/tree/master/keps/sig-cli/2985-public-krm-functions-registry).
