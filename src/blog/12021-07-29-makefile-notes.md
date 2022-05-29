# makefile notes

##

### _make_

`make` and Makefiles,
these days often abused as a generic task runner with an arcane syntax.

#### _zsh_ completion

zsh has built in support for extracting targets from Makefiles for autocompletion.
Unfortunately, it can more or less only extract the statically defined targets.
If you use patterns, wildcards, etc.,
you'll have to actually execute `make` to generate targets.
Also, you'll likely want to skip the builtin make variables as autocomplete targets.

```zsh
zstyle ':completion:*:make:*:targets' call-command true # exec make to get targets
zstyle ':completion:*:make:*' tag-order targets # ignore make variables
```

#### _macros_ or variables

Variables are the wrong name.
Think of them as _macros_ that can be expanded later.
Since you can't define variables inside targets,
define them outside, expanding to whatever you need inside,
you'll still have access to all the special vars.
Also a list is just space separated strings.

```
# := expands immediately as the file is processed top down and never again
# like variables in any sane programming language
# outputs "some ", env is not defined, trailing spaces are kept
macro1 := some $(env)

# = recursively expands at the time the macro is used
# output depends on the value of $(env) when macro2 is executed
macro2 = some $(env)

# ?= sets only if LHS is undefined
macro2 ?= some $(env)

# name of the current executing target
$@

# list of dependencies of current target
$^
```

#### _targets_

basics

```
# simple target
foo:
        @echo hello world

# target with dependency
bar: foo
        # output "bar"
        @echo $@
        # output "foo"
        @echo $^
```

dynamic:

```
apps = a b c d

# generates 4 targets "a", "b", "c", "d"
$(apps):
        # output depends on running target
        $@

apps2 = a.x b.x c.x d.x e.x
$(apps2): %.x: %.y
        # output ex: a.x
        @echo $@
        # output ex: a
        @echo $*
```

#### _functions_

There are a few of them, but no advanced string manipulation.

```
# pattern substition, % matches non space,
# pattern to match, pattern to output, input
$(patsubst %_x,%_y,$(somevar))

# variable declaration, input, output
$(foreach x,$(somelist),hello $(x))

# useful for matching a lot of files
# or checking if a file exists
$(wildcard *.yaml)
$(wildcard some.yaml)

# execute a shell command and use the output
# powerful but this exposes you to the environment and differences in command line tools
# ex GNU vs BSD etc.
$(shell ...)
```

#### example

So I have a directory full of apps,
each with helm values files for various environments,
and I want to generate a target for each app+env

##### directory layout

```
workspace/
  vars/
     app1/
        values.yaml
        values.dev.yaml
        values.prod.yaml
        secrets.dev.yaml
        secrets.prod.yaml
    app2/
      values.dev.yaml
      secrets.yaml
    app3/
      ...
```

##### Makefile

```make
# static list of envs
all_envs = dev prd
# dynamic list of apps
all_apps = $(patsubst vars/%,%,$(wildcard vars/*))
# create targets like: app.env
all_targets = $(foreach app,$(all_apps),$(foreach e,$(all_envs),$(a).$(e)))

# macros

# extract env from target name
env = $(subst .,,$(suffix $@))
# extract app from target name
app = $(patsubst %_$(env),%,$@)
# base directory for app
appdir = vars/$(app)
# for the possible filenames, check if they exist
possiblefiles = secrets.yaml secrets.$(env).yaml values.yaml values.$(env).yaml
valuesfiles = $(foreach f,$(possiblefiles),$(wildcard $(appdir)/$(f)))
# turn list of files into list of flags
valuesflags = $(foreach f,$(valuesfiles),-f $(f) )
# command
helmtemplate = helm secrets template $(app)-$(env) . $(valuesflags)

# targets

.PHONY: $(all_targets)
$(all_targets):
        $(helmtemplate)
```
