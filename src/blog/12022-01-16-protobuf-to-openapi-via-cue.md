# protobuf to openapi via cue

## round tripping through cue

### _proto_ to jsonschema / openapi

So you have message definitions declared as
[protocol buffers](https://developers.google.com/protocol-buffers),
and now you them in [JSON Schema](https://json-schema.org/)
or [OpenAPI](https://swagger.io/specification/) format.

You could use google's
[protoc-gen-openapi](https://github.com/google/gnostic/tree/master/cmd/protoc-gen-openapi)
and [protoc-gen-jsonschema](https://github.com/google/gnostic/tree/master/cmd/protoc-gen-jsonschema)
but I think their output is weird (multi files, no output?).
There's also [protoc-gen-openapiv2](https://github.com/grpc-ecosystem/grpc-gateway/tree/master/protoc-gen-openapiv2)
but the output also looks sort of weird (not much content?).

#### _cue_

Now [cue](https://cuelang.org/) is more of its own language
which can handle schema definition, validation and data configuration.
But that's not too important for us:
all we care is that it can import protobuf, converting it to cue,
and export openapi / jsonschema from those cue definitions:

```sh
$ cue mod init
$ cue import example.proto
$ cue export --out openapi .
$ cue export --out jsonschema .
```

The generated schemas look fairly solid:
all in one file, handles maps/oneof properly,
and it can even include validation like regex/pattern
(with cue specific [field options](https://cuelang.org/docs/integrations/protobuf/#field-options),
def in [cue.proto](https://github.com/cue-lang/cue/blob/v0.4.1/encoding/protobuf/cue/cue.proto)).
