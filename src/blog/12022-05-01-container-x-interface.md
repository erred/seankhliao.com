# container x interface

## 


### _container_ interfaces

These days [Kubernetes](https://kubernetes.io/)
can be best described as an API driven interface
to a distributed system,
with in tree support for orchestrating containerized workloads.
Following its big tent model of supporting a variety of vendors,
it has broken out integrated support for container runtimes,
storage and networking into interfaces that can be implemented
by various solutions.

#### _CRI_

The Container Runtime Interface
[spec](https://github.com/kubernetes/cri-api/blob/c75ef5b/pkg/apis/runtime/v1/api.proto)
defines a gRPC service for kubelet to talk to to manage containers.
While this is intended to be run per node,
I don't think there's anything stopping you
from actually running the containers elsewhere.

#### _CSI_

The Container Storage Interface
[spec](https://github.com/container-storage-interface/spec/blob/master/spec.md)
follows a similar model,
but with an optional controller component.
This looks primarily usef to attach volumes to nodes,
and then the runtime can mount it into a container.

#### _CNI_

The Container Networking Interface
[spec](https://github.com/containernetworking/cni/blob/main/SPEC.md)
has a different model more like unix cli tools.
Plugins are executed on a host to configure networking (namespaces)
directly, and they can execute each other if necessary.
