# mono lith/repo vs micro...

## the modern softare architectural version of tabs vs spaces?

### _mono_ ?

Do you lump all your code together in 1 big repo?
or split them out into a lot of small ones?
Should your services be parts of a monolith
or broken up into a constellation of microservices?

#### _repos_

So far,
my thoughts are that from a long term maintenance point of view,
monorepos are better.
All your code is together,
it's easier to find uses of libraries,
it's harder to leave parts stale (since they break builds),
and actions affecting large swaths of the codebase only need to be applied once,
instead of across every repo.
This does come with the caveat that I haven't yet felt the need for sparse checkouts and such,
maybe the tooling surrounding that is still lacking?

#### _services_

Here I think monoliths are less great.
Everything is bundled together, which means everything also fails together.
Also, having barely related things munged together just doesn't seem to work,
there's very little they can share.
Sure, your deployment code might be duplicated a few times,
but I think that's a worthwhile tradeoff for limiting the blast radius of individual apps.
Of course, how "micro" should a microservice be still seems to be up for debate...
