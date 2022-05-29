# dockerfile uncached actions

## when the layer cache annoys you

### _docker_ caching

`docker build`'s way of working relies heavily on caches and layers to speed things up.
If no inputs change, it reuses the results of a previous run.
Usually this is a good thing,
unless you've decided you want to run CI tooling as part of your docker build process,
and of course those should never be cached.

#### _cachebust_ arg

Today I saw a dockerfile that did:

```Dockerfile
FROM index.docker.io/alpine:3.15.2 AS image
RUN apk add bash

FROM image AS scan
COPY --from=index.docker.io/aquasec/trivy:latest /usr/local/bin/trivy /usr/local/bin/trivy
ARG CACHEBUST=1
RUN trivy filesystem --ignore-unfixed --exit-code 1 /
```

and you built it with something like `docker build --build-arg CACHEBUST=$(date) .`.

Interesting way to run tools that shouldn't be cached,
but now you have extra cruft in your final images,
and no fine grained control over the tooling.

#### _no-cache_

The more "correct" way would be something like:

```Dockerfile
FROM index.docker.io/alpine:3.15.2 AS main
RUN apk add bash

FROM scratch AS scan
COPY --from=output-image / /
COPY --from=index.docker.io/aquasec/trivy:latest /usr/local/bin/trivy /usr/local/bin/trivy
RUN trivy filesystem --ignore-unfixed --exit-code 1 /
```

and built with:

```sh
docker build --target main -t output-image .
docker build --target scan --no-cache .
```

This keeps your output image clean from any CI only tools,
while ensuring they always run fresh.
With this pattern, multiple tools can be run in parallel too
(using multiple docker build commands with different targets).
