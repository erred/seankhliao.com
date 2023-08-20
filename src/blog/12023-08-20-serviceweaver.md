# serviceweaver

## first impressions

### _serviceweaver_ first impressions

[Service Weaver](https://serviceweaver.dev/)
is an fascinating framework for building Go applications
that blur the line between monolish and microservices.
The following are my thoughts on why adopting it might be difficult,
based on version 0.19.0.

#### _positioning_

The headline for Service Weaver is:
_"Write your application as a modular binary. Deploy it as a set of microservices."_
Which makes me wonder who the audience is?

##### _monolith?_ monorepo?

Most people don't set out to build a monolith,
they end up with one that has grown organically which they need to break up later.
As for microservices,
they're deployed not just as a technical boundary,
but I think more commonly as a team/political boundary layer as well.
It requires a significant level of foresight to choose the right abstraction boundaries up front
that will make the benefits of multi component deploys apparent later.

As for development model,
I think it's sort of implied that you'd develop it in a monorepo?
Even though it doesn't seem necessary.
Monorepos... have a severe tooling issue in the open source and commercial space:
not just git itself (doesn't scale too well to checking out large repos),
but also the development lifecycle surrounding it,
like ownership, reviews (not enough granularity on permissions),
CI (blaze/bazel is uncommon, new places can do the caching optimizations well),
so everyone just ends up with a pile of repos.

##### _product_ teams? platform teams?

It feels like it's for a mostly pure development team
that just wants to run stuff,
but then which deployer would you use that fits this usecase?
I would've expected Cloud Run as the lowest touch option.
Anywhere with the scale of a dedicated platform / infrastructure team
will have tried to standardize on specific deployment / rollout processes,
and it's hard to see how a tool like `eeaver` which wraps up so much of the processes
without much documentation can integrate well into the environment.

#### _operational_ concerns

Stuff I'd need to think about if it were to run in production.

##### _custom_ protocol

Part of the magic is the seemless communication between components,
but the part of me that would have to run it wonders what the (undocumented) protocol is.
It looks like some protobuf based TCP protocol,
which leaves me questioning:
How do I debug / inspect it?
Does it integrate (or work) at all with gateways, service meshes, Cloud Run, Functions/Lambda, etc?
And why not gRPC (which already requires load balancer support)?

##### _logger_ format

The default format seems to be glog inspired?
but then it's also not structured klog/v2 and I'm not sure how I'd parse it without the message part being quoted.
I also don't see a way to pass in a handler of choice that does formatting in a way I'd like
(or more commonly, to conform to organizational requirements).

##### _logger_ spanid

I don't think the span ID extraction is correct:
It takes the span from when the logger is created,
not at the point the log call was made,
which was why `slog` added all the `*Context()` and `LogAttrs(ctx, ...)` methods.
This matters for the more complicated functions where you'd start internal spans.
As for why not get a new logger every time?
that breaks sharing common keys / prefixes using `logger.With` and `logger.WithGroup`.

##### _metrics_

The docs jump around between saying it supports Google Cloud Metrics and prometheus (more implied),
but it wasn't clear how I'd explicitly choose which one to use,
especially since I might run on GKE without using Cloud Monitoring (it is quite expensive...).

Also, some native opentelemetry support here would be nice too,
operationally it is the easiest format to trasform **correctly**
through the opentelemetry collector to support whichever backend I may be running.

##### _kubernetes_ deployment

You can generate kubernetes manifests,
but those things have a lot of settings I'd potentially need to customize:
security controls, namespacing, resource allocation, labels/annotations, etc.
How do manage that going forward?
Do I need something like kustomize to apply patches/merges on top of the generated manifest?
Or should I expect something more like ko which just modifies image references in existing manifests.

Also, just how much logic is tied up in the `weaver` cli deployers to support versioned routing?
Supporting the use of an imperative deployment tool in a world moving towards declarative state
is a whole can of worms.

#### _other_

Stuff that didn't really fit anywhere.

##### _go_ mod init hello

This is just to pick on the tutorial,
which starts with `go mod init hello`.
Go technically [reserves non-domain like import paths](https://github.com/golang/go/issues/32819),
and produces slightly worse errors if you do use them.
