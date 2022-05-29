# Google Cloud Storage Access Control

## one bucket two systems


### _Google_ Cloud Storage

You get a bucket, you can put things in.

#### _access_ control

When you setup a bucket you get 2 options:
- Fine grained
- Uniform

##### _fine_ grained

In this mode, permissions are granted through both IAM and ACLs.

ACLs consist of pairs of role (`READER`, `WRITER`, `OWNER`) and entity,
attached to either the bucket or an object.
This is by default quite lax.

In this mode the iam  `roles/storage.legacy*` roles are special,
turning IAM roles into bucket level ACLs,
you'll see an ACL entry for each IAM role grant.


##### _uniform_

Here, permissions are granted as roles via IAM
Pretty straightforward.
