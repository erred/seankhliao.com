# vector agent

## fluentd++

### _vector_ dot dev

[vector](https://vector.dev/)
is a telemetry agent, now owned by [datadog](https://www.datadoghq.com/).
Telemetry agent as in: collects data from your platform/services,
does some level of processing on it before shipping it off to some storage/query backend.

For the past few weeks,
my attention has been on getting it to collect and process logs.

#### _fluentd_

Our old setup uses [fluentd](https://www.fluentd.org/).
That has a more or less linear flow of events,
if an event matches a transformation, it's processed,
otherwise the transform is bypassed and everything continues on the nest stage.

Fluentd has a new setup based on
[labels](https://docs.fluentd.org/quickstart/life-of-a-fluentd-event#labels),
where you point to the next grouping of processors.
This allows you to build out a directed acyclic graph (DAG) of transformations,
but we don't use it.

#### _vector_

Vector also works by building out a DAG of transformations,
but instead of pointing to the next step,
each step points to its inputs.
So like fluentd labels, but in reverse order.
Using it for logs,
it really feels like somebody looked at fluentd and fluentbit,
and thought: "let's do the same thing, but in Rust".

It supports a smattering of of protocols,
but feature parity between similar sources is lacking:
the file source supports end-to-end acknowledgements,
but the kubernetes source based on it doesn't,
the Kubernetes metadata association is only available as part of a logging source,
the GCP Cloud Storage source doesn't make use of notifications unlike S3.
It also comes with questionable design choices,
like using a healthcheck that's unrelated to the actual data flow,
and a patch version bump can break your VRL (their processing DSL) transformations
as their type checking changes and decides something can either fail or not.
Also their docs are often inconsistent (or plain wrong).

It does come with good things,
like the ability to tap into a running pipeline
(if it hasn't decided to reload its configuration while running....),
and a testing framework built in,
though it is verbose beyond belief.
