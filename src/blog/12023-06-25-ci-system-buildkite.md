# ci system buildkite

## change ci like i change wardrobes?

### _new_ ci system

I ~~needed~~ wanted a new CI setup.
I was on [Google Cloud Build],
which I actually like most of the time,
but I wanted off the cloud.

Before I've used:

- [Github Actions]: too flaky / janky ui
- [Jenkins]: just no
- [CircleCI]: weird...
- [Gitlab runner]: don't want to run gitlab
- [AWS Codepipelines]: another weird one
- [Azure Devops]: not touching azure again
- [Travis]: is it dead yet?

Oh, and I just got a newish ARM server,
I want to be able to run self-hosted runners on.

Looking through a few more product pages,
I landed on [Buildkite].
they offer the control plane,
you supply the runners.
Plus, it comes with a decent free tier (5k min/month, ~166min / day).

I had considered running [Tekton] for a truly self hosted setup,
but I think I'll defer that to when I have some extra infrastructure stable.

#### _dedupe_ configuration

Migrating my config over from Cloud Build,
I realized once again that I had a lot of the same manifests spread across a bunch of repos.
I had a standard, preferred way of
testing a library, building a container, publishing a website, etc.

After 4 rounds of: modify every repo's `.buildkite/pipeline.yaml` file when i need to improve something,
a flash of inspiration struck.
Buildkite's pipelines are stored in the cloud,
it's just that their first and only step is to upload the config in your repo and continue from there.
Instead of uploading a local ppipeline file,
I could instead grab a standard remote file and upload that.
Every time I come up with an improvement, I'd only have to update the remote file once,
and every pipeline will pick up the change the next time they run.

So now I have one repo to rule the masses:
[seankhliao/buildkite-pipelines](https://github.com/seankhliao/buildkite-pipelines),
and no ci configuration in the repos at all.

[Google Cloud Build]: https://cloud.google.com/build
[Github actions]: https://github.com/features/actions
[Jenkins]: https://www.jenkins.io/
[CircleCI]: https://circleci.com/
[gitlab runner]: https://docs.gitlab.com/runner/
[aws Codepipelines]: https://aws.amazon.com/codepipeline/
[azure devops]: https://azure.microsoft.com/en-gb/products/devops
[travis]: https://www.travis-ci.com/
[buildkite]: https://buildkite.com/
[tekton]: https://tekton.dev/
