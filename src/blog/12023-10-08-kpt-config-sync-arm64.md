# kpt-config-sync on arm16

## another gitops controller

### _config-sync_

[config-sync](https://cloud.google.com/anthos-config-management/docs/config-sync-overview)
is a gitops controller made by Google as part of Anthos.
There's an open source variant available at
[GoogleContainerTools/kpt-config-sync](https://github.com/GoogleContainerTools/kpt-config-sync).

So I tried installing it.
First problem: the images are only linux/amd64,
but my server is arm64.
Well the source is there,
I'll build it myself... except the build process hardcodes amd64
and pulls in amd64 prebuilt binaries.
Hacking around that isn't too hard, see appendix.

Next up is the issue of images that aren't part of the repo.
Namely `gcr.io/config-management-release/git-sync:v3.6.9-gke.1__linux_amd64`
and `gcr.io/config-management-release/resource-group-controller:v1.0.16`.
`git-sync` turns out to be a repackaged [kubernetes/git-sync](https://github.com/kubernetes/git-sync)
which has arm64 images we can pull directly.
I was stuck on `resource-group-controller` for a few weeks before I realized it was
[GoogleContainerTools/kpt-resource-group](https://github.com/GoogleContainerTools/kpt-resource-group).

Now just to strip out some unused things like
otel collectors, helm and oci sync, amd gce askpass,
and the thing finally works
(a `RootSync` can take code and apply it to a cluster).
Further experiments with using it to come later.

#### Appendix: kpt-config-sync diff

build with `make build-images`

```diff
diff --git a/Makefile.build b/Makefile.build
index 11e91123..73ad37dd 100644
--- a/Makefile.build
+++ b/Makefile.build
@@ -56,55 +56,69 @@ build-junit-report-cli: pull-buildenv buildenv-dirs

 # Build Config Sync docker images
 .PHONY: build-images
-build-images: install-helm install-kustomize
+build-images:
 	@echo "+++ Building the Reconciler image: $(RECONCILER_TAG)"
 	@docker buildx build $(DOCKER_BUILD_QUIET) \
+		--platform linux/arm64 \
 		--target $(RECONCILER_IMAGE) \
 		-t $(RECONCILER_TAG) \
 		-f build/all/Dockerfile \
 		--build-arg VERSION=${VERSION} \
+		--load \
 		.
 	@echo "+++ Building the Reconciler Manager image: $(RECONCILER_MANAGER_TAG)"
 	@docker buildx build $(DOCKER_BUILD_QUIET) \
+		--platform linux/arm64 \
 		--target $(RECONCILER_MANAGER_IMAGE) \
 		-t $(RECONCILER_MANAGER_TAG) \
 		-f build/all/Dockerfile \
 		--build-arg VERSION=${VERSION} \
+		--load \
 		.
 	@echo "+++ Building the Admission Webhook image: $(ADMISSION_WEBHOOK_TAG)"
 	@docker buildx build $(DOCKER_BUILD_QUIET) \
+		--platform linux/arm64 \
 		--target $(ADMISSION_WEBHOOK_IMAGE) \
 		-t $(ADMISSION_WEBHOOK_TAG) \
 		-f build/all/Dockerfile \
 		--build-arg VERSION=${VERSION} \
+		--load \
 		.
 	@echo "+++ Building the Hydration Controller image: $(HYDRATION_CONTROLLER_TAG)"
 	@docker buildx build $(DOCKER_BUILD_QUIET) \
+		--platform linux/arm64 \
 		--target $(HYDRATION_CONTROLLER_IMAGE) \
 		-t $(HYDRATION_CONTROLLER_TAG) \
 		-f build/all/Dockerfile \
 		--build-arg VERSION=${VERSION} \
+		--load \
 		.
 	@echo "+++ Building the Hydration Controller image with shell: $(HYDRATION_CONTROLLER_WITH_SHELL_TAG)"
 	@docker buildx build $(DOCKER_BUILD_QUIET) \
+		--platform linux/arm64 \
 		--target $(HYDRATION_CONTROLLER_WITH_SHELL_IMAGE) \
 		-t $(HYDRATION_CONTROLLER_WITH_SHELL_TAG) \
 		-f build/all/Dockerfile \
 		--build-arg VERSION=${VERSION} \
+		--load \
 		.
 	@echo "+++ Building the OCI-sync image: $(OCI_SYNC_TAG)"
 	@docker buildx build $(DOCKER_BUILD_QUIET) \
+		--platform linux/arm64 \
 		--target $(OCI_SYNC_IMAGE) \
 		-t $(OCI_SYNC_TAG) \
 		-f build/all/Dockerfile \
 		--build-arg VERSION=${VERSION} \
+		--load \
 		.
 	@echo "+++ Building the Helm-sync image: $(HELM_SYNC_TAG)"
 	@docker buildx build $(DOCKER_BUILD_QUIET) \
+		--platform linux/arm64 \
 		--target $(HELM_SYNC_IMAGE) \
 		-t $(HELM_SYNC_TAG) \
 		-f build/all/Dockerfile \
 		--build-arg VERSION=${VERSION} \
+		--load \
 		.
 	@echo "+++ Building the Askpass image: $(ASKPASS_TAG)"
 	@docker buildx build $(DOCKER_BUILD_QUIET) \
@@ -115,10 +129,12 @@ build-images: install-helm install-kustomize
 		.
 	@echo "+++ Building the Nomos image: $(NOMOS_TAG)"
 	@docker buildx build $(DOCKER_BUILD_QUIET) \
+		--platform linux/arm64 \
 		--target $(NOMOS_IMAGE) \
 		-t $(NOMOS_TAG) \
 		-f build/all/Dockerfile \
 		--build-arg VERSION=${VERSION} \
+		--load \
 		.

 # Deprecated alias of build-images. Remove this once unused.
diff --git a/Makefile.oss.prow b/Makefile.oss.prow
index 91b19fc2..b39ba7fa 100644
--- a/Makefile.oss.prow
+++ b/Makefile.oss.prow
@@ -124,4 +124,4 @@ set-up-workload-identity-test:

 .PHONY: push-test-helm-charts-to-ar
 push-test-helm-charts-to-ar: install-helm
-	GCP_PROJECT=$(GCP_PROJECT) ./scripts/push-test-helm-charts-to-ar.sh
\ No newline at end of file
+	GCP_PROJECT=$(GCP_PROJECT) ./scripts/push-test-helm-charts-to-ar.sh
diff --git a/build/all/Dockerfile b/build/all/Dockerfile
index d112d1a0..56388ad3 100644
--- a/build/all/Dockerfile
+++ b/build/all/Dockerfile
@@ -13,7 +13,7 @@
 # limitations under the License.

 # Build all Config Sync go binaries
-FROM golang:1.20.8 as bins
+FROM golang:1.21.1 as bins

 WORKDIR /workspace

@@ -23,7 +23,9 @@ COPY . .
 ARG VERSION

 # Build all our stuff.
-RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GO111MODULE=on \
+RUN --mount=type=cache,target=/root/.cache/go-build \
+    --mount=type=cache,target=/go/pkg/mod \
+  CGO_ENABLED=0 GOOS=linux GO111MODULE=on \
   go install \
     -mod=vendor \
     -ldflags "-X kpt.dev/configsync/pkg/version.VERSION=${VERSION}" \
@@ -56,9 +58,7 @@ FROM gcr.io/distroless/static:nonroot as hydration-controller
 WORKDIR /
 COPY --from=bins /go/bin/hydration-controller .
 COPY --from=bins /workspace/.output/third_party/helm/helm /usr/local/bin/helm
-COPY --from=bins /workspace/.output/third_party/helm/NOTICES /third_party/helm/NOTICES
 COPY --from=bins /workspace/.output/third_party/kustomize/kustomize /usr/local/bin/kustomize
-COPY --from=bins /workspace/.output/third_party/kustomize/NOTICES /third_party/kustomize/NOTICES
 COPY --from=bins /workspace/LICENSE LICENSE
 COPY --from=bins /workspace/LICENSES.txt LICENSES.txt
 USER nonroot:nonroot
@@ -82,7 +82,6 @@ ENV HOME=/tmp
 WORKDIR /
 COPY --from=bins /go/bin/helm-sync .
 COPY --from=bins /workspace/.output/third_party/helm/helm /usr/local/bin/helm
-COPY --from=bins /workspace/.output/third_party/helm/NOTICES /third_party/helm/NOTICES
 COPY --from=bins /workspace/LICENSE LICENSE
 COPY --from=bins /workspace/LICENSES.txt LICENSES.txt
 USER nonroot:nonroot
@@ -94,9 +93,7 @@ WORKDIR /
 USER root
 COPY --from=bins /go/bin/hydration-controller .
 COPY --from=bins /workspace/.output/third_party/helm/helm /usr/local/bin/helm
-COPY --from=bins /workspace/.output/third_party/helm/NOTICES /third_party/helm/NOTICES
 COPY --from=bins /workspace/.output/third_party/kustomize/kustomize /usr/local/bin/kustomize
-COPY --from=bins /workspace/.output/third_party/kustomize/NOTICES /third_party/kustomize/NOTICES
 COPY --from=bins /workspace/LICENSE LICENSE
 COPY --from=bins /workspace/LICENSES.txt LICENSES.txt
 RUN apt-get update && apt-get install -y git
@@ -153,9 +150,7 @@ RUN mkdir -p /opt/nomos/bin
 WORKDIR /opt/nomos/bin
 COPY --from=bins /go/bin/nomos nomos
 COPY --from=bins /workspace/.output/third_party/helm/helm /usr/local/bin/helm
-COPY --from=bins /workspace/.output/third_party/helm/NOTICES /third_party/helm/NOTICES
 COPY --from=bins /workspace/.output/third_party/kustomize/kustomize /usr/local/bin/kustomize
-COPY --from=bins /workspace/.output/third_party/kustomize/NOTICES /third_party/kustomize/NOTICES
 COPY --from=bins /workspace/LICENSE LICENSE
 COPY --from=bins /workspace/LICENSES.txt LICENSES.txt

```
