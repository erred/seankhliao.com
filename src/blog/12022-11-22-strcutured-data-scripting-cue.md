# structured data scripting

## handing structured data to scripts

### _scripting_ with structured data

GitOps and declarative management tools are all fine and good,
until something messes up really bad,
and you're needing to run some imperative command across your fleet of machines/clusters/etc.

#### _shell_ script it

The quick and easy way is just loop over everything in a shell script,
I call mine `yolo`,
and this works well for a while.
It's later when you need to pull in more tools that you start feeling the limits:
you need 2 different tools but they have different cluster config names,
you need extra data associated with the cluster etc.

```sh
#!/bin/zsh

# do this for every cluster
run_one() {
  kubectl get pod
}

# list of clusters, using filenames each having their own kubeconfig file
# comment out clusters to skip
clusters=(
  staging
  dev
  prod1
  prod2
)

# loop over clusters, run_one for each
run_all() {
  for cluster in "${clusters[@]}"; do
    # change the cluster kubectl targets
    export KUBECONFIG="${HOME}/.config/kube/${cluster}"
    # print a pretty header (in bold) for each cluster to separate output
    printf "\n\033[1m%s==========\033[0m\n" "${cluster}"

    # run the things
    run_one
  done
}

run_all
```

#### _shell_ faked array

So now you want to store structured data in a per target way that is accessible to the script.
Shells don't really have multidimensional arrays,
but you can fake one by concatenating the keys together in to a string.
Ex: `data[foo,bar]` accesses an entry with the key `foo,bar`,
But they're not the nicest thing to work with
or even a good way to specify the data.

```sh
#!/bin/zsh

declare -a data
data[staging,desc]="staging-2"
data[staging,kubeconfig]=~/.config/kube/staging
data[staging,argoconfig]=~/.config/argo/staging
data[staging,suffix]="agdb"
# ...

# $1: cluster name
run_one() {
  export KUBECONFIG="${data[$1,kubeconfig]}"
  kubectl get pod "${data[$1,name]}-${data[$1,suffix]}"
}
```

#### _shell_ with csv or json

My next idea was to store th data in CSV,
but I couldn't find a good way to safely parse the data.

Next came JSON, but issuing a hundred `jq` calls to get values didn't seem very efficient.

#### _cue_ wrapped shell script

So what if, you specify the data in CUE,
and use `cue` to execute the script it generates?

CUE the language has decent support for reshaping data,
allowing you to write in a compact representation,
but reshape it to a more machine-friendly, verbose format for consumption
in the same file.
And `cue` the tool has built-in support for user-provided commands.

So in a file called `yolo_tool.cue`:

```cue
package main

import (
	"tool/exec"
)

// list of targets, comment out to skip
run_instances: [
	"staging",
	"dev",
  // prod1
]

// how to specify subcommand execution in cue
// loop over every instance,
// unifying with an exec.Run structure
command: yolo: task: {for _idx, _instance in run_instances {"\(_instance)": exec.Run & {
  // local reference to the data
  let _data = instance_data[_instance]
  // actual script goes here
	let _script = """
	      export KUBECONFIG="\(_data.kubeconfig)"

	      echo instance "\(_instance)"
	      kubectl get pod "\(_data.name)-\(data.suffix)"
        """
  // script execution
	cmd: ["zsh", "-c", _script]
	// sequential runs by forxing a dependency on the previous entry
	if _idx > 0 {
		_req: task[run_instances[_idx-1]].success
	}
}}}

// compact form for data entry
_instance_data: {
  staging: ["staging-2", "~/.config/kube/staging", "~/.config/argo/staging-2", "agbd"]
  dev:     ["dev-3",     "~/.config/kube/dev",     "~/.config/qrgo/dev-3", "hgcb"]
  prod1:   ["..."]
}

// reformat to verbose form
instance_data: {for _instance,_d in _instance_data: {"\(_instance)": {
  name: _d[0]
  kubeconfig: _d[1]
  argoconfig: _d[2]
  suffix: _d[3]
}}}
```
