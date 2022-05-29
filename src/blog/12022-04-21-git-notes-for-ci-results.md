# git notes for ci results

## storing builds with git


### _git_ notes

[git-notes](https://git-scm.com/docs/git-notes)
allows us to attach arbitrary metadata (actually just an unstructured file) to commits.
This is great, since we're not modifying commits,
we're not going to be invalidating hashes.

What can we do with this?
We could store the build results (or any other results) in these metadata files.
Though it does mean giving your CI write access to your repo...

Why would you want to do this anyway?
I wanted to look at my `git log --graph --oneline` and see the build results of each commit.
Unfortunately,
even though `git log` has support for structured key-values via
[trailers](https://git-scm.com/docs/git-interpret-trailers),
that is only valid for the commit message itself.
It's all or nothing for git notes in the formatting,
the closest you can get is `%<(4,trunc)%N` to get the first few characters
(maybe `PASS` / `FAIL`).
