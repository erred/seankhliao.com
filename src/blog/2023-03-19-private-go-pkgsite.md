# private go pkgsite

## internal deployment of pkg.go.dev

### _pkgsite,_ internally 

[pkgsite] is the code that powers [pkg.go.dev],
serving rendered documentation of versioned Go modules.
It sources data from the Go module proxy at [proxy.golang.org],
so if you have any private code you want docs for,
then you'll have to run your own version.

[pkgsite]: https://go.googlesource.com/pkgsite
[pkg.go.dev]: https://pkg.go.dev/
[proxy.golang.org]: https://proxy.golang.org/

#### _locally_

[cmd/pkgsite] is the tool for running a local (mostly isolated to your computer) version.
It serves from local directories, the local module cache, and the module proxy.

[cmd/pkgsite]: https://go.googlesource.com/pkgsite/+/refs/heads/master/cmd/pkgsite/

#### _service_ mode

[cmd/frontend] is the main stateless entry point.
It serves web pages either directly from a proxy (pull and process on demand)
or from a database (postgres) of pre-processed data.
Search functionality requires the database.
It exposes an endpoint `/fetch/$module/@v/$version` to queue up a fetch if requested,
and runs worker goroutines itself to process the fetches.

[cmd/frontend]: https://go.googlesource.com/pkgsite/+/refs/heads/master/cmd/frontend/

[postgres] is the optional database for storing pre-processed module data.
It is required for the search functionality.
Migrations need to be applied to the database.
Data is inserted by worker goroutines from [cmd/frontend], [cmd/worker], or tools like [devtools/cmd/seeddb].

[postgres]: https://www.postgresql.org/

[redis] is an optional dependency to frontend, 
used for caching rendered versions of web pages.

[redis]: https://redis.io/

[GCP Cloud Tasks] is an optional queue used to distribute (and rate limit) work to workers.
Without this, frontend uses an in memory queue and runs embedded instances of worker to process fetches.

[GCP Cloud Tasks]: https://cloud.google.com/tasks

[cmd/worker] is an optional, stateless worker that pulls from GCP Cloud Tasks to process modules 
(pull from proxy, process, insert into DB).
Locally it also uses an in memory queue with sub-workers.
It exposes an HTTP API to fetch, (re)process, and delete modules.
There's also an API endpoint to poll a module index to enqueue discovered modules to process.
This is the same worker code used elsewhere (frontend embedded mode, seeddb),
it can only fetch using the module proxy protocol.

[cmd/worker]: https://go.googlesource.com/pkgsite/+/refs/heads/master/cmd/worker

[devtools/cmd/seeddb] is a one-shot command that takes a list of module versions
and preemptively processes them.

[devtools/cmd/seeddb]: https://go.googlesource.com/pkgsite/+/refs/heads/master/devtools/cmd/seeddb/

##### _module_ proxy

The worker code in pkgsite only knows how to fetch modules through the proxy protocol.
Thus to process private modules, 
it's necessary to run a module proxy wich will own the credentials to your vcs.

[athens] is one such choice.
While mildly complex, a nice feature is the support of `/index` to list discovered module versions,
which can then be polled by worker.

[athens]: https://docs.gomods.io/
