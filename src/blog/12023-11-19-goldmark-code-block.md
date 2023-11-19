# goldmark code blocks

## syntax highlighting, line numbers, copy button

### _goldmark_ code blocks

I use [github.com/yuin/goldmark](https://pkg.go.dev/github.com/yuin/goldmark)
as the markdown renderer for my blog.
Until recently, I hadn't bothered to do syntax highlighting,
but the day has come!
Anyway, there's the
[github.com/yuin/goldmark-highlighting/v2](https://pkg.go.dev/github.com/yuin/goldmark-highlighting/v2)
extension for syntax highlighting,
which uses [github.com/alecthomas/chroma/v2](https://pkg.go.dev/github.com/alecthomas/chroma/v2).

#### _linkable_ line numbers

Theres the `WithLinkableLineNumbers(b bool, prefix string)` option,
but I was a bit confused about how to generate unique links for each block of code.
That was until I realized I could create a new instance of the highlighting extension
and markdown renderer for each page
and close over an incrememting counter.

```go
var block int
hl := highlighting.NewHighlighting(
        highlighting.WithFormatOptions(
                chromahtml.WithLineNumbers(true),
        ),
        highlighting.WithCodeBlockOptions(func(c highlighting.CodeBlockContext) []chromahtml.Option {
                block++
                return []chromahtml.Option{
                        chromahtml.WithLinkableLineNumbers(true, fmt.Sprintf("block%d-", block)),
                }
        }),
)
```

#### _copy_ button

Now I wanted a copy button for the text.
In the generated html, each line looked like:

```html
</span></span>
<span class="line"><span class="ln" id="block1-2"><a class="lnlinks" href="#block1-2"> 2</a></span>
<span class="cl">  <span class="nt">&#34;after&#34;</span><span class="p">:</span> <span class="s2">&#34;cf2d3c9bb11e17eca797d8ab0d80aaef68f19b99&#34;</span><span class="p">,</span>
```

Some fiddling with js later,
I had some js to progressively enhance the blocks and copy out the text
by just joining the `cl` (code line?) elements.

```js
document.querySelectorAll(".chroma").forEach((block) => {
  if (!navigator.clipboard) {
    return;
  }

  let button = document.createElement("button");
  button.innerText = "Copy";
  block.appendChild(button);

  button.addEventListener("click", async () => {
    let codeText = [...block.querySelectorAll(".cl")]
      .map((n) => n.innerText)
      .join("");
    await navigator.clipboard.writeText(codeText);

    button.innerText = "Copied";

    setTimeout(() => {
      button.innerText = "Copy";
    }, 2000);
  });
});
```
