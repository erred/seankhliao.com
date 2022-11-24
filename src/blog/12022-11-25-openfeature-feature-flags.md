# openfeature feature flags

## what does it actually standardize

### _OpenFeature_

[OpenFeature](https://openfeature.dev/)
appears to be the feature flagging industry's attempt at some standardization.
It claims "unified API and SDK",
from what I can tell, that API is library API within the SDK, 
and not any particular network protocol.

#### _Using_ it

The spec and API are deceptively simple,
"just" make a library call to get a value,
and there will always be one because it will fall back to the default value,
and go on your merry way.

```go
package main

import (
	"context"

	fromenv "github.com/open-feature/go-sdk-contrib/providers/from-env/pkg"
	"github.com/open-feature/go-sdk/pkg/openfeature"
)

const (
        FlagA = "flag_a"
        FlagADefault = "a default value"
)

func main() {
	var ffProvider fromenv.FromEnvProvider
	openfeature.SetProvider(&ffProvider)

	ffClient := openfeature.NewClient("client-1")

	// while doing something
	f, err := ffClient.StringValue(context.Background(), FlagA, FlagADefault, openfeature.NewEvaluationContext("", nil))
	if err != nil {
	        // log it?
	        // will always return a value, even if default
	}
	// do something with f
}
```

#### _spec?_

While there is a [spec](https://docs.openfeature.dev/docs/specification/)
it only seems to specify the API and not the expected behaviour of the providers.
For example, you pass each evaluation an EvaluationContext,
but I didn't find any clear indication of how the values passed in would be used,
and this (imo) limits the usefulness,
because you're never sure what you're getting out of the evaluation,
and you have to code defensively against it.

#### _flagd_

[flagd](https://github.com/open-feature/flagd) 
looks to be their attempt at a server / network protocol for flags that can actually change values.
It takes in config from different sources (files, k8s CRD, etc),
and exposes them over multiple protocols using buf's connect-go library
with a gRPC based API.
The [api spec](https://buf.build/open-feature/flagd/docs/main:schema.v1) 
seems to only be available via buf.build.

The file based configuration exposes more people to the horrors of
[JsonLogic](https://jsonlogic.com/).
Have you ever wanted to program in an AST, in JSON?
Well now you can.
