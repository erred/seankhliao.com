# soft-serve webhooks

## builr in triggers at last

### _webhooks_ for soft-serve

[charmbracelet/soft-serve](https://github.com/charmbracelet/soft-serve)
is my current choice for git hosting and in
[release v0.7.1](https://github.com/charmbracelet/soft-serve/releases)
we finally get webhooks.

Previously, we could (had to)
[write our own webhook generator](https://github.com/seankhliao/githook/blob/main/cmd/pre-commit/main.go)
which would be run on git post-receive.
A slightly less nice thing about the new webhooks feature is that it needs per repo config.

Anyway, payloads look like:

```json
{
  "after": "cf2d3c9bb11e17eca797d8ab0d80aaef68f19b99",
  "before": "b10f0188155ec8643b2ad8d28ded62b0d99febe8",
  "commits": [
    {
      "author": {
        "date": "2023-11-13T20:34:44Z",
        "email": "sean+git@liao.dev",
        "name": "Sean Liao"
      },
      "committer": {
        "date": "2023-11-13T20:34:44Z",
        "email": "sean+git@liao.dev",
        "name": "Sean Liao"
      },
      "id": "cf2d3c9bb11e17eca797d8ab0d80aaef68f19b99",
      "message": "unused",
      "timestamp": "2023-11-13T20:34:44Z",
      "title": "unused"
    }
  ],
  "event": "push",
  "ref": "refs/heads/main",
  "repository": {
    "created_at": "2023-11-06T21:41:14Z",
    "default_branch": "main",
    "description": "",
    "git_url": "git://localhost/mono.git",
    "http_url": "https://softserve.ihwa.liao.dev/mono.git",
    "id": 35,
    "name": "mono",
    "owner": {
      "id": 2,
      "username": "arccy"
    },
    "private": false,
    "project_name": "",
    "ssh_url": "ssh://ihwa.liao.dev:23231/mono.git",
    "updated_at": "2023-11-13T20:26:10Z"
  },
  "sender": {
    "id": 2,
    "username": "arccy"
  }
}
```

For me, that means mapping it into a tekton pipeline
with a `Trigger` looks something like:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: Trigger
metadata:
  labels:
    app.kubernetes.io/name: tekton-builds
    event-listener: listener
  name: softserve
  namespace: tekton-builds
spec:
  interceptors:
    - ref:
        name: cel
      params:
        - name: filter
          value: requestURL.parseURL().path.startsWith("/softserve")
        - name: overlays
          value:
            - expression: body.after.truncate(7)
              key: truncated_sha
            - expression: '"git+ssh://tekton-ihwa@softserve.softserve.svc/REPO.git".replace("REPO", body.repository.name)'
              key: repo_url
            - expression: requestURL.parseURL().path.split("/")[2]
              key: pipeline
  bindings:
    - name: repo_name
      value: $(body.repository.name)
    - name: revision
      value: $(body.after)
    - name: truncated_sha
      value: $(extensions.truncated_sha)
    - name: repo_url
      value: $(extensions.repo_url)
    - name: pipeline
      value: $(extensions.pipeline)
  template:
    spec:
      params:
        - name: repo_name
        - name: revision
        - name: truncated_sha
        - name: repo_url
        - name: pipeline
      resourcetemplates:
        - apiVersion: tekton.dev/v1
          kind: PipelineRun
          metadata:
            generateName: $(tt.params.repo_name)-$(tt.params.truncated_sha)-
          spec:
            params:
              - name: revision
                value: $(tt.params.revision)
              - name: url
                value: $(tt.params.repo_url)
            pipelineRef:
              name: $(tt.params.pipeline)
            taskRunSpecs:
              - pipelineTaskName: fetch-source
                serviceAccountName: softserve-clone
            workspaces:
              - name: cloned-repo
                volumeClaimTemplate:
                  spec:
                    accessModes:
                      - ReadWriteOnce
                    resources:
                      requests:
                        storage: 1Gi
```
