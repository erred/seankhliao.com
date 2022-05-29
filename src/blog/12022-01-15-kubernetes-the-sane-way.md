# kubernetes the sane way

## throw away all the abstractions, do it all by hand


### _kubernetes_

Sure, [kubernetes](https://kubernetes.io/) is complicated,
and there are all in one distributions like
[rancher k3s](https://k3s.io/)
or [k0s](https://k0sproject.io/)
that make it easier to run.
But part of the reason k8s is complicated is all the options it provides,
and part of how it's simplified by the distributions is by making decisions for you.
If you happen to have different opinions on what should happen,
then you're sort of out of luck.

[kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
is in theory the standard tool for installing k8s.
It depends only on kubelet on the host,
and runs everything as containers in the cluster itself.
Sounds great, but my biggest stumbling block with it has been networking.
You're supposed to install a pod networking addon yourself afterwards,
but whatever I installed never seemed to stabilize,
causing issues like intermittent connectivity and a circular ring of crashing components,
likely because networking was down for the `kube-apiserver` in the cluster,
and so the networking addon failed to talk to it...

If you think about it,
nothing about the control plane needs to run in the cluster,
they'll happily run outside, like all the all-in-one distros do it.
And that's indeed what Kelsey Hightower's
[Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
does, and I posit that it's the only sane way of working.
The first time I went through it,
it was more copy-paste and yay, you have a working cluster,
but it becomes more interesting when you try to change things to suit your needs and it breaks.

Side note on certificates:
when I first went through kubernetes the hard way,
my eyes glazed over all the certificates and `cfssl` CSRs,
but the [certificates best practices](https://kubernetes.io/docs/setup/best-practices/certificates/)
should be more like _required reading_ as the `CN` and `O` have special values they need to be set to.

And so I finally have a stable cluster running with cilium...
