# workspaces with git worktree

## SVN, but with git?

### checking out code

At a previous role,
I checked out a copy of every git repo in our organization.
This was a great productivity booster,
as I could easily run [ripgrep](https://github.com/BurntSushi/ripgrep) over all of our code,
searching for references to things.
It also meant a slightly lower barrier to entry in jumping in to help people.
On disk this looked something like:

```
.
└── github
   ├── repo-1
   │  └── README.md
   ├── repo-2
   │  └── README.md
   └── repo-3
      └── README.md
```

I worked in short lived branches:
`git branch -n ticket-desc`, work, `git commit -m ...`, `git push`.
But this layout of repos meant on some days I was constantly switching branches
as I context switched between tasks,
common when helping people or fixing up for pull request reviews.
Not infrequently, I would end up with work on the wrong branch,
and have to resort to copy-pasting or git cherrypicking to fix the situation.

Occasionally, I would either copy or reclone an entire repository for some long lived work.

#### worktree

Inspired by my brief experiments with [svn](https://subversion.apache.org/),
and my discovery of [git worktree](https://git-scm.com/docs/git-worktree),
my current code layout looks like:

```
.
└── github
   ├── repo-1
   │  └── main
   │     └── README.md
   ├── repo-2
   │  ├── main
   │  │  └── README.md
   │  └── ticket-desc
   │     └── README.md
   └── repo-3
      └── main
         └── README.md
```

There's a single copy of the full repo history, usually in `main` or `master`,
and each work in progress gets its own checkout, with `git workree add ../ticket-desc`.
The entire log is still connected, so I can easily see and manage the state of all the repos,
I have a "clean" copy to refer to when I make changes,
and context switching is much faster.

The main downsides have been retraining muscle memory for the longer paths,
and needing to exclude the work in progress trees during searches
(or they end up cluttering results with duplicate entries).
