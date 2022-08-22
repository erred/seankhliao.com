# css select everything of the same class on hover

## hover on element and highlight all elements with the same class with pure CSS

### _select_ everything

You have a lot of elements with the same class
and you want to make them all change when you hover over one of them.
Also known as
[this stackoverflow question](https://stackoverflow.com/questions/12786810/hover-on-element-and-highlight-all-elements-with-the-same-class).

The old way either meant:

- `.foo:hover, .foo:hover ~ .foo`: select yourself, and all the elements after you, but not before you.
- use javacript.

CSS has a new selector: [`:has()`](https://developer.mozilla.org/en-US/docs/Web/CSS/:has)
that though still [experimental on most browsers](https://developer.mozilla.org/en-US/docs/Web/CSS/:has#browser_compatibility)
would allow us to do what we want:

- `body:has(.foo:hover) .foo`: select `.foo` which is a child of `body` when `body` contains a `.foo` in `:hover` state.
