# packer docker build

## building docker images with packer


### _packer_ docker build

I spy with my little eye:
another way to build docker images.

Except not really,
[packer](https://www.packer.io/)
just shells out to a local instance of docker to do the docker building,
and it doesn't even have a way to replicate multistage builds
(no way to pull data out of an image).
Oh, and no layer caching (or any other caching for that matter).

This means it's basically only good for adding some stuff to a base image.

#### _how_

If you still think this is a good idea:

```hcl
source "docker" "base" {
  image = "golang:alpine"
  export_path = "single.tar"
}

build {
  name = "singlestage"
  sources = [
    "source.docker.base",
  ]

  # alternatively have everything in a subdirectory
  # and provision the entire dir instead
  provisioner "shell" {
    inline = [
      "mkdir /workspace",
    ]
  }

  provisioner "file" {
    sources = [
      "go.mod",
      "main.go",
    ]
    destination = "/workspace/"
  }

  provisioner "shell" {
    inline = [
      "cd /workspace",
      "CGO_ENABLED=0 go build -o /usr/local/bin/app",
    ]
  }

  post-processor "docker-import" {
    repository = "seankhliao/packer-test01"
    tag = "t0"
    changes = [
      "ENTRYPOINT [\"/usr/local/bin/app\"]",
    ]
  }
}
```
