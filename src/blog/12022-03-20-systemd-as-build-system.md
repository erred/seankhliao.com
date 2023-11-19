# systemd as a build system

## systemd eats the world

### _build_ system

So a build system (for a CI process) is usually a collection of program executions
that have various dependency requirements,
which come out to be a directed acyclic gragh (DAG).
You know what manages processes and has a rich dependency graph solver?
_systemd_.

#### _notes_

##### _execution_

`Type=oneshot` most processes in CI run a single execution,
ie they aren't persistently running in the background.
Using oneshot also means you can have multiple `ExecStart=` lines,
running one after the other (replacing `&&` in shell scripting).

`ExecStart=/path/to/exe` where your main processes go.
`-/path/to/exe` ignores failures.
`ExecStartPre=` isn't very useful in the oneshot scenario.

`ExecStartPost=` only runs on successful completion,
while `ExecStopPost=` always runs.

##### _ordering_

There are 2 main ways to order dependencies:

`OnSuccess=`, `OnFailure=`: This way you start with a root unit,
and say which ones to trigger afterwards in a feed forward manner.
It's an imperative chain that limits the possibility of reuse.

`After=` + `Requires`: Using these 2 you specify the end target,
and the dependencies it has on previous units.
works out which ones it needs to run to get to the end result.
`Requires=` triggers a service to start successfully,
while `After=` waits for a service to complete.
`Wants=` doesn't enforce successful exit of the dependency.

There are also the inverse `Before=`, `RequiredBy`, and `WantedBy`,
but they really only have an effect when everything is installed+enabled.

`.target` files are useful when since with the graph method you need to know the end state,
and it's unlikely your last step is very memorable.
It's also a good place to attach the notification handlers with `OnSuccess=` and `OnFailure`.
Unfortunately, they only run once (unless explicitly targeted by a `systemctl start` command,
so you may want to consider replacing them with a dummy service that just echos something).

##### _passing_ values

Sometimes you need to pass values between the different steps.
You could: write out config files for later programs or
write key=value environment values to be passed in via `EnvironmentFile`
(and optionally used as flags/args via `ExecStart=/bin/exe $SOME_ENV`).

##### _instances_

While you may think that you can reuse config with `unit@.service`
and template common executions,
it may be less useful than it appears, as you have no good way of specifying the dependencies before it.

##### _isolation_

Unfortunately, there's no way to say "run all these units in a single chroot".
So your options are probably:

- create a dedicated user/instance and use user services
- create a base image, enable the end target and run with ephemeral systemd-nspawn containers.

#### _example_

```systemd
# clone.service
[Unit]
Description=clone git repo
[Service]
Type=oneshot
WorkingDirectory=/tmp
ExecStart=/usr/bin/git clone https://github.com/example/repo

# setup.target
[Unit]
Description=setup
Requires=clone.service
After=clone.service

---
# build.service
[Unit]
Description=build code
Requires=setup.target
After=setup.target
[Service]
Type=oneshot
WorkingDirectory=/tmp/repo
ExecStart=/usr/bin/mkdir -p bin
ExecStart=/usr/bin/go build -o bin/ ./...

---
# test.service
[Unit]
Description=test code
[Service]
Type=oneshot
WorkingDirectory=/tmp/repo
ExecStart=/usr/bin/go test ./...

---
# vet.service
[Unit]
Description=vet code
[Service]
Type=oneshot
WorkingDirectory=/tmp/repo
ExecStart=/usr/bin/go vet ./...

---
# build.target
[Unit]
Description=build and test
Requires=build.service vet.service test.service
After=build.service vet.service test.service
OnSucess=post-success.service
OnFailure=notify-failure.service

---
# post-success.service
[Unit]
Description=notify on success
[Servuce]
ExecStart=/usr/bin/curl ...

---
# notify-failure.service
[Unit]
Description=notify on failure
[Service]
ExecStart=/usr/bin/slack-notify ...
```
