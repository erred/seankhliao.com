# knative scale to zero

## but there's nothing there?

### _knative_

[knative](https://knative.dev/) is interesting,
giving you a fairly concise deployment config
and more interestingly to me,
[scale to zero](https://knative.dev/docs/serving/autoscaling/scale-to-zero/).
It does this by making use of retries and queue buffers.

If you just did `k get svc` on a Knative owned service,
you might be very confused on what it points to (nothing).
Instead, you have to look at the Endpoints object backing the service,
which will point to the internal load balancer.

#### _scale_ to zero

Scaling to zero really relies on your load balancer to buffer requests.
It also means the calling code can't be too smart
and decide to peek at the Service's backing pods directly,
(because they might not exist).

An example is [contour](https://projectcontour.io/)
and its [external authorization](https://projectcontour.io/guides/external-authorization/) setup.
You give it a Service and it tries (and fails) to connect.
It doesn't really work with knative.
If only I could just give it an url to connect to.

#### _loosely_ connected world

While having everything be kubernetes native objects
and referencing each other might sound like a good idea,
I think Knative is much more suited to a loosely connected world via urls,
and each service exists in isolation from each other
and the rest of kubernetes.
