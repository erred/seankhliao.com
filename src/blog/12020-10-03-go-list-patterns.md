# go list patterns

## go list pattern coverage


### _list_

The "I know it lists things but I don't remember what" command.

reference repo: [erred/go-list-ex](https://github.com/erred/go-list-ex)

#### _dependency_ graph

This is everything:

![graph of everything](/static/go-list-base.svg)

#### _module_ mode

listing modules

##### go list -m

![go list -m](/static/go-list-m.svg)

##### go list -m all

![go list -m all](/static/go-list-mall.svg)

#### _package_ mode

##### go list ./...

![go list ./...](/static/go-list-dotdotdot.svg)

##### go list -deps ./...

![go list -deps ./...](/static/go-list-dotdotdotdeps.svg)

##### go list -deps -test ./...

![go list -deps -test ./...](/static/go-list-dotdotdotdepstest.svg)

##### go list all

_all_ changed meaning between 1.15 and 1.16

###### go1.16+

![1.16 go list all](/static/go-list-all.svg)

###### go1.15 or earlier

![1.15 go list all](/static/go-list-all115.svg)
