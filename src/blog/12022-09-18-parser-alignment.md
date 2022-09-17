# parser alignment

## when your standards aren't really standards

### _parser_ alignment

The idea that you can have standards,
and different parser implementations will agree on how to process inputs.
In Go, there have been at least 2 security issues with parser alignment,
[#25192 net/url: don't parse ';' as a separator in query string](https://go.dev/issue/25192)
[#30999 net: reject leading zeros in IP address parsers](https://go.dev/issue/30999).
While the Go parsers were internally consistent,
these process inputs that are also processed by other systems
(Kernels, C libraries, proxy servers, etc...)
and security checks implemented at one layer may be ineffective
due to different parsing rules of what is ostenibly a standard representation of data.

This has been front of mind recently due to dealing with
[vector](https://vector.dev/).
Vector parses json as it's represented on the wire:
`{"foo.bar": 1}` is an object with a single key of `foo.bar`.
However, the backends we deal with (elasticsearch, datadog)
look at it differently:
`{"foo.bar": 1}` is equivalent to `{"foo": {"bar": 1}}`.
Now you have 2 keys, one nested under the other.

So comes the problem,
for example, if you want to enforce an object has at most 128 keys,
this can be gamed, just by different representations of the wire format,
and if you want to enforce a particular value has a given pattern,
changing the key representation could hide it from any validation functions.
