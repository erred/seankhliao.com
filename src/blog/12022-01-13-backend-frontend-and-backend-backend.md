# backend-frontend and backend-backend

## multilayer backends


### _backend_ frontend

Usually when people say frontend they think things that go in the web browser,
and everything else that serves that to be the backend.
But the backend can be a complex beast
and sometimes it can be worth splitting them into frontends and backends too.

#### _all_ in one

For the basic crud app, you have data stored somewhere,
some intermediate processing, and rendering it to the end user.
Here it's perfectly reasonable to squash it all in a single process.

As your needs get more complex, such as serving both web and api,
things get messy.
I suppose this is where the something like the MVC pattern comes in.

#### _rpc_

Why bother with simple function calls
when you can serialize everything over the network?
Within your backend,
your _backend_ is responsible handling data
and exposing a pure api,
while your _frontend_ can just call it like it calls any other function,
and assemble the final response.

Maybe your frontend renders a web page,
or is a GraphQL server that aggregates multiple backend services.
Either way, you now have 2 simple services instead of a mildly complex one.

_Note:_ the operator in me sort of dislikes having more components to manage,
but it also means better-ish scaling opportunities.

#### _framework_

Sometimes I think the differences in experience comes from my choice of library.
Go's [`net/http`](https://pkg.go.dev/net/http) is fairly barebones,
you have to parse input out of path/query/body yourself and marshal the response yourself.
Compare that to [gRPC](https://pkg.go.dev/google.golang.org/grpc),
where the API is defined and codegen-ed,
your input/output are just data.

Having the base layer be just data really is something
that makes you feel like you have a solid footing to base further things on top of.
