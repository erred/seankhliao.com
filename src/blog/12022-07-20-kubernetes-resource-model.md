# kubernetes resource model

## KRM: apiVersion all the things

### _kubenetes_ resource model

Kuberenetes has been a driving force behind a lot of new APIs looking very similar,
even if they aren't resources that will be handled by Kubernete's apiserver.
Under all of that is the
[kubernetes resource model (KRM)](https://github.com/kubernetes/design-proposals-archive/blob/main/architecture/resource-management.md):
as an end user the most observable effect is that every resource has the same metadata config,
but there are more [semantics](https://github.com/kubernetes/design-proposals-archive/blob/main/architecture/resource-management.md#resource-semantics-and-lifecycle)
that are expected of implementations,
which all tie in to a consistent experience.

#### _configuration_ as data

_ClickOps_: click through every vendor provided ui to configure things.
Usually fast and easy, setting sensible defaults for a lot of things,
but ultimately not very reproducible or scalable.

_Infrastructure as Code_ (IaC): some enterprising sysadmins wrote some bash/python/something else
to automate their job, and now we need a trendy phrase to get everyone to adopt it,
or at the very least the mindset.
At the very basic level: I don't care how you do it,
just record it as code, preferably in a git repo somewhere so someone down the line can figure out what happened.

_Configuration as Data_ (CaD): With a giant pile of code to represent your giant pile of infrastructure,
you realise the situation is untenable.
Full blown programming languages are complicated,
and some bored programmer is going to stuff in more complexity.
Linting, static analysis and refactoring tools will only get you so far without executing the code,
and good luck executing it in your mind as you try to read it.
Instead we go _declarative_,
declaring our desired state for other components to reconcile.
We will instead codegen our way out of duplication,
with the added benefit that there's a shared, typed model
that many tools can understand and be chained together in.

#### _shift_ left in config

In a typical flow chart `a -> b -> c`,
the left is where things start,
and a shift left means to do things earlier in the process.
With CaD, this gives a more direct mapping between "thing you wrote/generated/reviewed"
and "thing that infrastructure automation tries to create/manage/destroy".
Less room for interpretation, less runtime magic.
