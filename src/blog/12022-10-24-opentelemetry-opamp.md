# OpenTelemetry OpAMP

## Open Agent Management Protocol

### _OpAMP_

So you've deployed a fleet of observability agents in to the field,
but now you need to update their configuration.
If you have an existing channel to push out config changes,
great.
But what if that's a bit too cumbersome,
or if you have different agents which require different config file changes?
[OpAMP](https://github.com/open-telemetry/opamp-spec)
aims to be the protocol for managing them,
allowing remote config and status reporting capabilities over HTTP 
(agent polls control plane)
or WebSockets.

#### _example?_

There's an [announcement blog post](https://opentelemetry.io/blog/2022/opamp/),
and [opamp-go](https://github.com/open-telemetry/opamp-go) repo with examples.
The example appears to show remote config management via changing a config file
and restarting the process.
Maybe there will be deaper integration with the SDKs in the future?
