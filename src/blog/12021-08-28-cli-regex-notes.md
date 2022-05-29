# cli regex notes

## which flavour of "regex" are we talking about?

### _cli_ tools

The unix way: lots of tiny tools.
Unfortunately this also means the same thing is implemented many times,
with differing results.
Like regex

#### _regex_

Thankfully these mostly fall into 2 groups:

- Basic regex where almost everything needs to be escaped to have special meaning
- Extended regex where the special characters are on by default

both `sed` and `grep` take `-E` to switch to extended mode

```
            sed     vim        grep    awk        ripgrep    sd
grouping    \(\|\)  \(\|\)     \(\|\)  (|)        (|)        (|)
list        []      []         []      []         []         []
classes     [[:c:]] [[:c:]] \w [[:c:]] [[:c:]] \w [[:c:]] \w [[:c:]] \w
0+          *       *          *       *          *          *
0+ ungreedy                                       *?         *?
1+          \+      \+         \+      +          +          +
0,1         \?      \?         \?      ?          ?          ?
count       \{x,y\} \{x,y\}    \{x,y\} {x,y}      {x,y}      {x,y}
```

#### _other_

Here's a [gist](https://gist.github.com/CMCDragonkai/6c933f4a7d713ef712145c5eb94a1816)
on a some regex engines,
and [wikipedia](https://en.wikipedia.org/wiki/Comparison_of_regular-expression_engines).
