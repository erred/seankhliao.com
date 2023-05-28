# software supply chain tooling

## tools for securing software production

### _software_ supply chain tools

so how do you sign all the stuff

#### _grafeas_

[grafeas](https://grafeas.io/)
is an API server for storing artifact metadata in your own DB.
Eg, store in-toto layout / link files in grafeas and pull from there when you need it,
or store CVEs and occurrences of CVEs in there to query later.

#### _in-toto_

[in-toto](https://in-toto.io/)
is both a metadata standard and set of libraries/tools
to declare the steps in a software supply chain with authorizations
(who is allowed to do what), and verify them.
What you get are signed metadata files:

- `root.layout`: a file defining steps, and authorization,
  [layout file format](https://github.com/in-toto/docs/blob/master/in-toto-spec.md#43-file-formats-layout).
  Parse this file for instructions on verifying that artifacts are properly signed
- `name.prefix.link`: files for each step, containing metadata such as checksums for artifacts,
  [link file format](https://github.com/in-toto/docs/blob/master/in-toto-spec.md#44-file-formats-namekeyid-prefixlink)

#### _sigstore_

[sigstore](https://www.sigstore.dev/)
is a suite of tools for signing/verify artifacts.
What you get:

- `cosign`: tool to sign/verify artifacts, extra integration with containers
- `fulcio`: ca allowing you to exchange an identity you have (eg openid connect),
  for a short lived cert you can use to sign artifacts.
  Proves: the signing identity was valid at that point in time.
- `rekor`: a transparency log of signatures + metadata

#### _the update framework_

[the update framework (TUF)](https://theupdateframework.io/)
is a general process and metadata specs for ensuring you get trusted updates.
You get signed metadata files of the following:

- `timestamp.json`: frequently renewed pointer to snapshots, ensuring you aren't held back from updates.
- `snapshot.json`: version numbers of other files, check to see if you need a newer version
- `targets.json`: list of files + hashes and/or delegations to other files
- `root.json`: root of trust for listing the allowed signers for various roles/delegations
