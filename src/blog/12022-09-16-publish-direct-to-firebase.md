# publish direct to firebase hosting

## who needs to download a cli tool when you can make API calls

### _firebase_ hosting

[Firebase](https://firebase.google.com/) is an "app development platform",
or in other words, a specialized set of cloud services linked with Google Cloud Platform.
[Hosting](https://firebase.google.com/products/hosting)
is their static site hosting solution.
At some point, I used them,
liked their URL cleanup behavior (enforce trailing slash),
moved around to different hosts as I experimented with things,
and now I'm back there.

#### _render_ and upload

[Firebase has a CLI](https://firebase.google.com/docs/cli)
that they tell you to use for most things,
including uploading your static site.
For the longest time, I did that:

- run a nightly CI build to package the cli as a container (used with Google Cloud Build)
- run a CI job on push:
  - renders my site into a directory
  - uploads the directory

This took somewhere between 30s and a minute,
not too bad but a lot of the time seemed to be in downloading containers...
Also, why bother writing to the disk anyway?

#### _upload_ from memory

Thankfully, firebase provides [API access](https://firebase.google.com/docs/hosting/api-deploy),
So no need to download their node.js based cli
with a bunch of features you're not going to use,
just render into an in memory file system,
check which files you need to send,
and upload.

These days my CI runs take between 10-15s.
Barely enought time to context switch away.
[Current blog engine](https://github.com/seankhliao/blogengine).
