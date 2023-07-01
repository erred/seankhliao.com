# log/slog custom handler

## harder than it looks

### _log/slog_ custom handler

So [Go 1.21] gets a new package:
[log/slog] for structured logging.

Even though there's a single package,
it is actually multiple things:

- a standard frontend api using in application code: [log/slog.Logger](https://pkg.go.dev/log/slog#Logger)
- a standard backend api for creating log output: [log/slog.Handler](https://pkg.go.dev/log/slog#Handler)
- 2.5 implementations of logging backends (.5 for the default but not exposed `log` compatible logger):
  [log/slog.JSONHandler](https://pkg.go.dev/log/slog#JSONHandler) and [log/slog.TextHandler](https://pkg.go.dev/log/slog#TextHandler)

I think of these, `slog.Handler` is the most important.
You might not like `slog.Logger` for reasons,
like not being context first, or allowing unstructured ("sugared") attributes,
and you might need features not available in the builtin handlers,
like special case processing of particular keys, or just a different output format.
This leaves `slog.Handler` as the standard interchange between your favorite
frontend API and backend API.

[go 1.21]: https://go.dev/doc/go1.21
[log/slog]: https://pkg.go.dev/log/slog

Anyway, I had need of a custom implementation.
But one thing tripped me up:
"If a group has no Attrs (even if it has a non-empty key), ignore it.".
For JSON, (or any other format with nested/deduped prefixes),
this wasn't as easy to do.
At first, I thought this required building up a tree,
doing a depth first walk to prune out empty groups,
then writing the result.
Later, I realized I could instead optimistically write the keys,
and roll back as needed if there ended up being no attributes in the group.

Below is my implementation,
modify as appropriate to handle your special needs.

```go
package main

import (
    "bytes"
    "context"
    "encoding/json"
    "io"
    "log/slog"
    "os"
    "slices"
)

func main() {
    h := &handler{
        w:     os.Stdout,
        state: &state{},
    }
    l := slog.New(h)
    l.InfoCtx(context.Background(), "hello world", slog.Group("a"), slog.Group("b"))
    l.InfoCtx(context.Background(), "hello world", slog.Group("a", slog.Group("b")), slog.Group("c"))
    l.InfoCtx(context.Background(), "hello world", slog.Group("a", slog.Group("b", slog.String("x", "x"))), slog.Group("c", slog.String("y", "y")), slog.String("z", "z"))
    l.With(slog.String("x", "x")).Info("foo")
    l.WithGroup("a").Info("foo")
    l.WithGroup("a").Info("foo", slog.String("x", "x"))
    l.WithGroup("a").Info("foo", slog.Group("b"))
    l.WithGroup("a").Info("foo", slog.Group("b", slog.String("x", "x")))
    l.WithGroup("a").Info("foo", slog.Group("b"), slog.String("x", "x"))
    l.WithGroup("a").WithGroup("f").Info("foo")
    l.WithGroup("a").WithGroup("f").Info("foo", slog.String("x", "x"))
    l.WithGroup("a").WithGroup("f").Info("foo", slog.Group("b"))
    l.WithGroup("a").WithGroup("f").Info("foo", slog.Group("b", slog.String("x", "x")))
    l.WithGroup("a").WithGroup("f").Info("foo", slog.Group("b"), slog.String("x", "x"))
}

const (
    // magic numbers to reduce number of slice resizes
    specialCaseSize = 256
    stateBufferSize = 1024
)

type handler struct {
    minLevel slog.Level
    state    *state
    w        io.Writer
}

func (h *handler) clone() *handler {
    return &handler{
        minLevel: h.minLevel,
        state:    h.state.clone(),
        w:        h.w,
    }
}

func (h *handler) Enabled(ctx context.Context, l slog.Level) bool {
    return l >= h.minLevel
}

func (h *handler) WithAttrs(attrs []slog.Attr) slog.Handler {
    if len(attrs) == 0 {
        return h
    }
    h2 := h.clone()
    for _, a := range attrs {
        h2.state.attr(a)
    }
    return h2
}

func (h *handler) WithGroup(name string) slog.Handler {
    if name == "" {
        return h
    }
    h2 := h.clone()
    h2.state.openGroup(name)
    return h2
}

func (h *handler) Handle(ctx context.Context, r slog.Record) error {
    if r.Level < h.minLevel {
        return nil
    }

    // attrs
    state := h.state.clone()
    r.Attrs(func(a slog.Attr) bool {
        state.attr(a)
        return true
    })
    state.closeAll()

    buf := new(bytes.Buffer)
    buf.Grow(specialCaseSize + len(state.buf))
    buf.WriteString(`{`)

    // time
    if !r.Time.IsZero() {
        buf.WriteString(`"time":`)
        buf.Write(jsonBytes(r.Time))
        buf.WriteString(`,`)
    }
    // level
    buf.WriteString(`"level":`)
    buf.Write(jsonBytes(r.Level))

    // message
    buf.WriteString(`,"message":`)
    buf.Write(jsonBytes(r.Message))

    // any other special keys
    // e.g. file:line, attrs from ctx or extracted during attr processing by state.attr

    // attrs
    if len(state.buf) > 0 {
        buf.WriteString(`,`)
        buf.Write(state.buf)
    }
    buf.WriteString("}\n")

    _, err := h.w.Write(buf.Bytes())
    return err
}

func jsonBytes(v any) []byte {
    b, _ := json.Marshal(v)
    return b
}

// state holds preformatted attributes
type state struct {
    confirmedLast int    // length of buf when we last wrote a complete attr
    groupOpenIdx  []int  // indexes before open groups, allows rollback on empty groups
    separator     []byte // separator to write before an attr or group
    buf           []byte // buffer of preformatted contents
    // TODO hold special keys to be placed in top level (eg error)
}

func (h *state) clone() *state {
    buf := make([]byte, len(h.buf), max(stateBufferSize, cap(h.buf)))
    copy(buf, h.buf)
    return &state{
        h.confirmedLast,
        slices.Clone(h.groupOpenIdx),
        slices.Clone(h.separator),
        buf,
    }
}

func (h *state) openGroup(n string) {
    h.groupOpenIdx = append(h.groupOpenIdx, len(h.buf)) // record rollback point
    h.buf = append(h.buf, h.separator...)               // maybe need a separator
    h.buf = append(h.buf, jsonBytes(n)...)              // key name
    h.buf = append(h.buf, []byte(":{")...)              // open group
    h.separator = nil                                   // no separator for first attr
}

func (h *state) closeGroup() {
    lastGroupIdx := h.groupOpenIdx[len(h.groupOpenIdx)-1] // pop off the rollback point for current group
    h.groupOpenIdx = h.groupOpenIdx[:len(h.groupOpenIdx)-1]
    if h.confirmedLast > lastGroupIdx { // group was non empty
        h.buf = append(h.buf, []byte("}")...) // close off the group
        h.confirmedLast = len(h.buf)          // record new last point
        return
    }
    h.buf = h.buf[:lastGroupIdx] // all open subgroups were empty, rollback
}

func (h *state) closeAll() {
    for range h.groupOpenIdx {
        h.closeGroup()
    }
    h.groupOpenIdx = nil
}

func (h *state) attr(attr slog.Attr) {
    if attr.Equal(slog.Attr{}) { // drop empty attr
        return
    } else if attr.Value.Kind() == slog.KindGroup { // recurse into group
        g := attr.Value.Group()
        if len(g) == 0 {
            return
        } else if attr.Key != "" { // inline empty keys
            h.openGroup(attr.Key)
        }
        for _, a := range attr.Value.Group() {
            h.attr(a)
        }
        if attr.Key != "" {
            h.closeGroup()
        }
        return
    } else if attr.Key == "" {
        return
    }
    // TODO: grab any special keys

    val := attr.Value.Resolve() // handle logvaluer
    h.buf = append(h.buf, h.separator...)
    h.separator = []byte(",")
    h.buf = append(h.buf, jsonBytes(attr.Key)...)
    h.buf = append(h.buf, []byte(":")...)
    h.buf = append(h.buf, jsonBytes(val.Any())...)
    h.confirmedLast = len(h.buf)
}
```
