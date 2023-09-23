# k8s ordered container execution

## run your steps in order

### _k8s_ ordered container execution

In kubernetes, pods have 2 places where you can specify containers to run:
`initContainers` and `containers`.
`initContainers` start in the order they're specified
and only after the previous has finished
(unless it's a 1.28 sidecar with `restartPolicy: Always`).
Once that's done,
`containers` start in the order they're specified (is this an implementation detail leaking?)
without depending on each other for lifecycle.

So if you're creating a task runner
and have an ordered list of steps to execute,
you might think: oh i'll just put it all in `initContainers`.
Which might be fine...
until you decide that what you actually need is an graph (DAG) of steps,
rather than a linear list.

This is where something like the tekton project's
[`entrypoint`](https://github.com/tektoncd/pipeline/tree/main/cmd/entrypoint)
come in.
An executor command is copied / mounted into every step,
and wraps the actual command.
It writes to a specified file when the actual command exits,
and waits for files from previous steps to be present before starting its command.
This does have a slight disadvantage:
after the first step is complete,
the container exits (remember to set `restartPolicy: Never`),
and the pod enters into `NotReady` state,
even though for our purposes,
it's executing as expected.

Usage is slightly verbose:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tekton-ordered-0
  namespace: default
  labels:
    experiment: ordered
spec:
  restartPolicy: Never
  initContainers:
    # copy itself to a volume that can be mounted in every container
    - name: copy-entry
      image: gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/entrypoint:v0.52.0
      command:
        - /ko-app/entrypoint
        - cp
        - /ko-app/entrypoint
        - /ordered/bin/entrypoint
      volumeMounts:
        - name: bin # shared volume with executor
          mountPath: /ordered/bin
  containers:
    - name: one
      image: alpine
      command:
        - /ordered/bin/entrypoint # our entrypoint command
        - -post_file=/ordered/steps/one # write to here on exit
        - -termination_path=/ordered/steps/termintaion # termination log, nicer k8s status
        - -entrypoint=sh # actual thing to be executed
        - -- # everything after this is passed to the subprocess
        - -c
        - |
          echo step one
          echo hello world
      terminationMessagePath: /ordered/steps/termination # termination log
      terminationMessagePolicy: File
      volumeMounts:
        - name: bin # shared volume with executor
          mountPath: /ordered/bin
        - name: steps # shared volume for step status
          mountPath: /ordered/stepsered/steps

    - name: two
      image: alpine
      command:
        - /ordered/bin/entrypoint
        - -wait_file=/ordered/steps/one # wait for file from previous step to be present before proceeding
        - -post_file=/ordered/steps/two
        - -termination_path=/ordered/steps/termintaion
        - -entrypoint=sh
        - --
        - -c
        - |
          echo step two
          echo fizz buzz
      terminationMessagePath: /ordered/steps/termination
      terminationMessagePolicy: File
      volumeMounts:
        - name: bin
          mountPath: /ordered/bin
        - name: steps
          mountPath: /ord

    - name: three
      image: alpine
      command:
        - /ordered/bin/entrypoint
        - -wait_file=/ordered/steps/two
        - -post_file=/ordered/steps/three
        - -termination_path=/ordered/steps/termintaion
        - -entrypoint=sh
        - --
        - -c
        - |
          echo step three
          echo lorem ipsum
      terminationMessagePath: /ordered/steps/termination
      terminationMessagePolicy: File
      volumeMounts:
        - name: bin
          mountPath: /ordered/bin
        - name: steps
          mountPath: /ordered/steps
  volumes:
    - name: bin
      emptyDir: {}
    - name: steps
      emptyDir: {}
```
