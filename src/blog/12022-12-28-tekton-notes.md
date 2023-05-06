# tekton notes

## run my own ci...?

### tekton pipelines

[Tekton] sits somewhere on the spectrum between a building block and a product of a CI system.
Or maybe not a CI system, a generalized graph of arbitrary code execution.

#### _cloud_ build

There was a build task I wanted to move over from [Google Cloud Build]:
a nightly build of [Go] (plus some extra tools).
This was setup as a Dockerfile in a git repo subdirectory,
a Cloud Build config file,
and a [Google Cloud Scheduler] to trigger the build.

Dockerfile:

```dockerfile
FROM golang:alpine AS build
ENV CGO_ENABLED=0 \
    GOFLAGS=-trimpath
RUN apk add --no-cache bash curl gcc git musl-dev && \
    go install golang.org/dl/gotip@latest && \
    gotip download && \
    rm -rf /root/sdk/gotip/pkg/linux_* && \
    curl -Lo /usr/local/bin/skaffold https://storage.googleapis.com/skaffold/builds/latest/skaffold-linux-amd64 && \
    chmod +x /usr/local/bin/skaffold

FROM alpine
RUN apk add --no-cache git
ENV CGO_ENABLED=0 \
    GOFLAGS=-trimpath
ENV PATH=/root/sdk/gotip/bin:/root/go/bin:$PATH
COPY --from=build /usr/local/bin/skaffold /usr/local/bin/skaffold
COPY --from=build /root/sdk/gotip /root/sdk/gotip
WORKDIR /workspace
ENTRYPOINT [ "go" ]
```

cloudbuild.yaml:

```yaml
steps:
  - id: build-push-gotip
    name: "gcr.io/kaniko-project/executor"
    args:
      - "--context=gotip"
      - "--destination=${_REGISTRY}/gotip:latest"
      - "--image-name-with-digest-file=.image.gotip.txt"
      - "--reproducible"
      - "--single-snapshot"
      - "--snapshot-mode=redo"
      - "--ignore-var-run"

  - id: sign-gotip
    name: "gcr.io/projectsigstore/cosign"
    entrypoint: sh
    env:
      - "TUF_ROOT=/tmp" # cosign tries to create $HOME/.sigstore
      - "COSIGN_EXPERIMENTAL=1"
      - "GOOGLE_SERVICE_ACCOUNT_NAME=cosign-signer@com-seankhliao.iam.gserviceaccount.com"
    args:
      - "-c"
      - "cosign sign --force $(head -n 1 .image.gotip.txt)"

substitutions:
  _REGISTRY: us-central1-docker.pkg.dev/com-seankhliao/build

options:
  env:
    - GOGC=400

timeout: "1800s" # 30m gotip build is slow
```

#### _tekton_ build

Moving over to Tekton, I went with inlining the entire build config into a [TriggerTemplate].
No more cloning a repo first just for a file.
I think I could have done this with Cloud Build too,
but I haven't been consistent in managing my config as code consistently...

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerTemplate
metadata:
  name: gotip-trigger
spec:
  resourcetemplates:
    - apiVersion: tekton.dev/v1beta1
      kind: TaskRun
      metadata:
        generateName: build-gotip-tr-
      spec:
        taskSpec:
          params:
            - name: image-ref
              type: string
              default: us-central1-docker.pkg.dev/com-seankhliao/build/gotip:latest
          results:
            - name: image-digest
          steps:
            - name: write-dockerfile
              image: busybox
              script: |
                cat << EOF > /workspace/src/Dockerfile
                FROM golang:alpine AS build
                ENV CGO_ENABLED=0 \
                    GOFLAGS=-trimpath
                RUN apk add --no-cache bash curl gcc git musl-dev && \
                    go install golang.org/dl/gotip@latest && \
                    gotip download && \
                    rm -rf /root/sdk/gotip/pkg/linux_* && \
                    curl -Lo /usr/local/bin/skaffold https://storage.googleapis.com/skaffold/builds/latest/skaffold-linux-amd64 && \
                    chmod +x /usr/local/bin/skaffold

                FROM alpine
                RUN apk add --no-cache git
                ENV CGO_ENABLED=0 \
                    GOFLAGS=-trimpath
                ENV PATH=/root/sdk/gotip/bin:/root/go/bin:$PATH
                COPY --from=build /usr/local/bin/skaffold /usr/local/bin/skaffold
                COPY --from=build /root/sdk/gotip /root/sdk/gotip
                WORKDIR /workspace
                ENTRYPOINT [ "go" ]
                EOF
              volumeMounts:
                - name: src
                  mountPath: /workspace/src
            - name: build-gotip
              image: "gcr.io/kaniko-project/executor"
              args:
                - "--context=/workspace/src"
                - "--destination=$(params.image-ref)"
                - "--image-name-with-digest-file=$(results.image-digest.path)"
                - "--reproducible"
                - "--single-snapshot"
                - "--snapshot-mode=redo"
                - "--ignore-var-run"
                - "--ignore-path=/product_uuid" # kind specific? https://github.com/GoogleContainerTools/kaniko/issues/2164
              volumeMounts:
                - name: src
                  mountPath: /workspace/src
                - name: docker-auth
                  mountPath: /kaniko/.docker/config.json
                  subPath: .dockerconfigjson
          volumes:
            - name: src
              emptyDir: {}
            - name: docker-auth
              secret:
                secretName: gcp-ar-docker
```

Next up, an [EventListener] to turn HTTP requests into TaskRuns:

```yaml
apiVersion: triggers.tekton.dev/v1beta1
kind: EventListener
metadata:
  name: gotip-event
spec:
  serviceAccountName: tekton-triggers
  triggers:
    - name: default
      template:
        ref: gotip-trigger
```

And a CronJob to make the HTTP requests:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: trigger-gotip
spec:
  schedule: "*/30 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: trigger
              image: curlimages/curl:latest
              args:
                - --data
                - "{}"
                - http://el-gotip-event.default.svc.cluster.local:8080
          restartPolicy: OnFailure
```

[Tekton]: https://tekton.dev/
[Go]: https://go.dev/
[Google Cloud Build]: https://cloud.google.com/build
[Google Cloud Scheduler]: https://cloud.google.com/scheduler
[TriggerTemplate]: https://tekton.dev/docs/triggers/triggertemplates/
[EventListener]: https://tekton.dev/docs/triggers/eventlisteners/
