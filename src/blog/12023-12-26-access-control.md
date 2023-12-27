# access control models

## XAC access control and authorization model word salad.

### _Authz_ Authorization and access control

For context: there are _resources_ (things that can be accessed),
and _subjects_ (things that do the accessing).
Resources may be grouped together (e.g. all files in a directory),
Subjects may be grouped together (e.g. all users with a particular job title).

#### _DAC_ Discretionary Access Control

DAC doesn't really say much about how access control is defined,
it just means that if a subject has a certain level of access to a resource,
it can be passed on to a different subject.
Like an owner manage the permissions of a resource.

#### _MAC_ Mandatory Access Control

Like DAC, MAC also doesn't say much about how access control is defined,
more that every action is checked against some set of rules/policies.

#### _ACL_ Access Control Lists

We start with the most simple of models:
each resource has a list of subjects and their allowed permissions.

It could get fancier where the subjects are instead groups of subjects,
and we get RBAC.

#### _RBAC_ Role Based Access Control

Like mentioned in ACLs,
RBAC defines permissions based on groups of subjects,
where the groups a preferably defined as a deeper level of who they are,
rather than what they're trying to do
(so groups like: Active Oncall vs Database Editors).

#### _ReBAC_ Relationship Based Access Control

If you think about the above,
everything is built on relations
(user is a member of a group, file is a member of a directory, group is editor of a directory, etc.).
So we get ReBAC, where you describe everything in terms of relations to each other,
and a permission check is a graph search to see if a resource is reachable through various relations from a subject.

Most of the more complicated RBAC systems appear to be based on ReBAC,
but are presented to users as RBAC in combination with constraints on the resource side.

#### _ABAC_ Attribute Based Access Control

We can look at more than just who the subject is,
this is ABAC:
extra information is attached as attributes to the subject,
the resource, the check itself, and the execution environment,
and all of it is used to determine a pass/fail for a permission check.

Sometimes, vendors call it _PBAC_ Policy Based Access Control,
but it's just an emphasis on the policy vs the attributes the policy looks at.

We see RBAC/ReBAC systems growing ABAC features,
like [GCP IAM Conditions](https://cloud.google.com/iam/docs/conditions-overview),
[AWS IAM Conditions](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html),
[Authzed/SpiceDB Caveats](https://authzed.com/docs/reference/caveats).
