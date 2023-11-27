# go safer html

## html generation from code

### _safer_ html generation

Recently, I was working on one of my internal sites,
and encountered a broken link in a table.
I scratched my head very hard until I realized it was because of the way I generated the table:
The link had a text like `foo | bar`,
which i put into a markdown link (I was reusing my blog's markdown renderer): `[foo | bar](https://example.com)`,
which is then put into a table and it breaks, because `|` is read as the end of the table column.

:facepalm:

Fo the moment,
I bodged it with `strings.NewReplacer("|", "¦").Replace(s)`,
but that left me thinking of what better ways I have to safely generate html.
Also, after having written a lot of helm templates for my day job,
I felt like I really wanted something that could leverage existing language tooling support,
so no DSLs.
That meant things like [html/template](https://pkg.go.dev/html/template),
[github.com/google/safehtml/template](https://pkg.go.dev/github.com/google/safehtml/template),
and [github.com/a-h/templ](https://pkg.go.dev/github.com/a-h/templ)
weren't really up for consideration.

Looking around I saw 2 projects with similar goals:
[github.com/maragudk/gomponents](https://pkg.go.dev/github.com/maragudk/gomponents)
and [github.com/theplant/htmlgo](https://pkg.go.dev/github.com/theplant/htmlgo).

Both look very similar in both how their api other than args vs fluid chaining for attrs.

#### _gomponents_

Good: compact html output, more go style (args), project more active/responsive?

Bad: mixing of attributes and elements.

```go
package main

import (
    "bytes"
    "fmt"
    "log"

    "github.com/maragudk/gomponents"
    "github.com/maragudk/gomponents/html"
)

func main() {
    page := html.HTML(
        html.Lang("en"),
        html.Head(
            html.TitleEl(gomponents.Text("Hello World")),
            html.Meta(html.Name("description"), html.Content("This is a page")),
            html.Meta(html.Charset("utf8")),
            html.Meta(html.Name("viewport"), html.Content("width=device-width, initial-scale=1")),
            html.Link(html.Rel("me"), html.Href("http://example.com")),
        ),
        html.Body(
            html.Table(
                html.THead(
                    html.Tr(
                        html.Td(gomponents.Text("head0")),
                        html.Td(gomponents.Text("head1")),
                        html.Td(gomponents.Text("head2")),
                    ),
                ),
                html.TBody(
                    html.H1(gomponents.Text("hello world")),
                    html.P(gomponents.Text("this is some text")),
                    html.P(gomponents.Text("<script>alert(‘XSS’)</script>")),
                    html.Tr(
                        html.Td(gomponents.Text("row1")),
                        html.Td(gomponents.Text("row1")),
                        html.Td(gomponents.Text("row1")),
                    ),
                    html.Tr(
                        html.Td(gomponents.Text("row2")),
                        html.Td(gomponents.Text("row2")),
                        html.Td(gomponents.Text("row2")),
                    ),
                    html.Script(gomponents.Raw("alert(‘script’)")),
                ),
            ),
        ),
    )
    var buf bytes.Buffer
    err := page.Render(&buf)
    if err != nil {
        log.Fatalln(err)
    }
    fmt.Println(buf.String())
}
```

#### _htmlgo_

Good: separation of elements and attributes, better completion?

Bad: messy (lots of newlines) output, html element is obscured, not very active project.

```go
package main

import (
    "context"
    "fmt"
    "log"

    "github.com/theplant/htmlgo"
)

func main() {
    page := htmlgo.HTML(
        htmlgo.Head(
            htmlgo.Meta().Charset("utf8"),
            htmlgo.Meta().Name("viewport").Content("width=device-width, initial-scale=1"),
            htmlgo.Meta().Name("description").Content("This is a page"),
            htmlgo.Title("Hello World"),
            htmlgo.Link("http://example.com").Rel("me"),
        ),
        htmlgo.Body(
            htmlgo.H1("hello world"),
            htmlgo.P(htmlgo.Text("this is some text")),
            htmlgo.P(htmlgo.Text("<script>alert(‘XSS’)</script>")),
            htmlgo.Table(
                htmlgo.Thead(
                    htmlgo.Tr(
                        htmlgo.Td(htmlgo.Text("head0")),
                        htmlgo.Td(htmlgo.Text("head1")),
                        htmlgo.Td(htmlgo.Text("head2")),
                    ),
                ),
                htmlgo.Tbody(
                    htmlgo.Tr(
                        htmlgo.Td(htmlgo.Text("row1")),
                        htmlgo.Td(htmlgo.Text("row1")),
                        htmlgo.Td(htmlgo.Text("row1")),
                    ),
                    htmlgo.Tr().AppendChildren(
                        htmlgo.Td(htmlgo.Text("row2")),
                        htmlgo.Td(htmlgo.Text("row2")),
                        htmlgo.Td(htmlgo.Text("row2")),
                    ),
                    htmlgo.Script("alert(‘script’)"),
                ),
            ),
        ),
    ).(htmlgo.HTMLComponents)[1].(*htmlgo.HTMLTagBuilder).Attr("lang", "en")

    b, err := page.MarshalHTML(context.Background())
    if err != nil {
        log.Fatalln(err)
    }
    fmt.Println(string(b))
}
```
