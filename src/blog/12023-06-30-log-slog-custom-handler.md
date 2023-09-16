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
package jsonlog

import (
        "context"
        "encoding/json"
        "io"
        "log/slog"
        "slices"
        "strconv"
        "sync"
        "time"
        "unicode/utf8"

        "go.opentelemetry.io/otel/trace"
)

const (
        // magic numbers to reduce number of slice resizes
        // slog holds 5 attrs
        stateBufferSize = 1024

        // used by appendString
        hex = "0123456789abcdef"
)

var (

        // shared
        globalSep = []byte(",")

        // assert it is a handler
        _ slog.Handler = new(handler)

        // reduce allocations in steady state
        pool = &sync.Pool{
                New: func() any {
                        s := make([]byte, 0, stateBufferSize)
                        return &s
                },
        }

        // used by appendString
        safeSet = [utf8.RuneSelf]bool{
                ' ':      true,
                '!':      true,
                '"':      false,
                '#':      true,
                '$':      true,
                '%':      true,
                '&':      true,
                '\'':     true,
                '(':      true,
                ')':      true,
                '*':      true,
                '+':      true,
                ',':      true,
                '-':      true,
                '.':      true,
                '/':      true,
                '0':      true,
                '1':      true,
                '2':      true,
                '3':      true,
                '4':      true,
                '5':      true,
                '6':      true,
                '7':      true,
                '8':      true,
                '9':      true,
                ':':      true,
                ';':      true,
                '<':      true,
                '=':      true,
                '>':      true,
                '?':      true,
                '@':      true,
                'A':      true,
                'B':      true,
                'C':      true,
                'D':      true,
                'E':      true,
                'F':      true,
                'G':      true,
                'H':      true,
                'I':      true,
                'J':      true,
                'K':      true,
                'L':      true,
                'M':      true,
                'N':      true,
                'O':      true,
                'P':      true,
                'Q':      true,
                'R':      true,
                'S':      true,
                'T':      true,
                'U':      true,
                'V':      true,
                'W':      true,
                'X':      true,
                'Y':      true,
                'Z':      true,
                '[':      true,
                '\\':     false,
                ']':      true,
                '^':      true,
                '_':      true,
                '`':      true,
                'a':      true,
                'b':      true,
                'c':      true,
                'd':      true,
                'e':      true,
                'f':      true,
                'g':      true,
                'h':      true,
                'i':      true,
                'j':      true,
                'k':      true,
                'l':      true,
                'm':      true,
                'n':      true,
                'o':      true,
                'p':      true,
                'q':      true,
                'r':      true,
                's':      true,
                't':      true,
                'u':      true,
                'v':      true,
                'w':      true,
                'x':      true,
                'y':      true,
                'z':      true,
                '{':      true,
                '|':      true,
                '}':      true,
                '~':      true,
                '\u007f': true,
        }
)

func New(level slog.Level, out io.Writer) slog.Handler {
        return &handler{
                minLevel: level,
                state:    new(state),
                mu:       new(sync.Mutex),
                w:        out,
        }
}

type handler struct {
        minLevel slog.Level
        state    *state
        mu       *sync.Mutex
        w        io.Writer
}

func (h *handler) clone() *handler {
        b0 := pool.Get().(*[]byte)
        return &handler{
                minLevel: h.minLevel,
                state:    h.state.clone(*b0),
                mu:       h.mu,
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
        // add attrs to state
        b0 := pool.Get().(*[]byte)
        defer func() { pool.Put(b0) }()
        state := h.state.clone(*b0)
        r.Attrs(func(a slog.Attr) bool {
                state.attr(a)
                return true
        })
        state.closeAll()

        // initialize write buffer
        var buf []byte
        if cap(state.buf)-len(state.buf) < 160+len(r.Message) {
                buf = make([]byte, 0, len(state.buf)+160+len(r.Message))
        } else {
                b1 := pool.Get().(*[]byte)
                defer func() { pool.Put(b1) }()
                buf = (*b1)[:0]
        }

        buf = append(buf, `{`...)

        // time
        if !r.Time.IsZero() {
                buf = append(buf, `"time":"`...)
                buf = r.Time.AppendFormat(buf, time.RFC3339Nano)
                buf = append(buf, `",`...)
        }
        // level
        buf = append(buf, `"level":"`...)
        buf = append(buf, r.Level.String()...)
        buf = append(buf, `"`...)

        // trace
        spanCtx := trace.SpanContextFromContext(ctx)
        if spanCtx.IsValid() {
                buf = append(buf, `,"trace_id":"`...)
                buf = append(buf, spanCtx.TraceID().String()...)
                buf = append(buf, `","span_id":"`...)
                buf = append(buf, spanCtx.SpanID().String()...)
                buf = append(buf, `"`...)

        }
        // any other special keys
        // e.g. file:line, attrs from ctx or extracted during attr processing by state.attr

        // message
        buf = append(buf, `,"message":`...)
        buf = appendString(buf, r.Message)

        // attrs
        if len(state.buf) > 0 {
                buf = append(buf, `,`...)
                buf = append(buf, state.buf...)
        }
        buf = append(buf, "}\n"...)

        h.mu.Lock()
        defer h.mu.Unlock()
        _, err := h.w.Write(buf)
        return err
}

// state holds preformatted attributes
type state struct {
        confirmedLast int    // length of buf when we last wrote a complete attr
        groupOpenIdx  []int  // indexes before open groups, allows rollback on empty groups
        separator     []byte // separator to write before an attr or group
        buf           []byte // buffer of preformatted contents
        // TODO hold special keys to be placed in top level (eg error)
}

func (h *state) clone(buf []byte) *state {
        if cap(h.buf) > stateBufferSize {
                buf = slices.Clone(h.buf)
        } else {
                buf = buf[:len(h.buf)]
                copy(buf, h.buf)
        }
        s := &state{
                h.confirmedLast,
                slices.Clone(h.groupOpenIdx),
                slices.Clone(h.separator),
                buf,
        }
        return s
}

func (h *state) openGroup(n string) {
        h.groupOpenIdx = append(h.groupOpenIdx, len(h.buf)) // record rollback point
        h.buf = append(h.buf, h.separator...)               // maybe need a separator
        h.buf = appendString(h.buf, n)                      // key name
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
        val := attr.Value.Resolve()  // handle logvaluer
        if attr.Equal(slog.Attr{}) { // drop empty attr
                return
        } else if val.Kind() == slog.KindGroup { // recurse into group
                g := val.Group()
                if len(g) == 0 {
                        return
                } else if attr.Key != "" { // inline empty keys
                        h.openGroup(attr.Key)
                }
                for _, a := range val.Group() {
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

        h.buf = append(h.buf, h.separator...)
        h.separator = globalSep
        h.buf = appendString(h.buf, attr.Key)
        h.buf = append(h.buf, []byte(":")...)
        switch val.Kind() {
        case slog.KindAny:
                b, _ := json.Marshal(val.Any())
                h.buf = append(h.buf, b...)
        case slog.KindBool:
                h.buf = strconv.AppendBool(h.buf, val.Bool())
        case slog.KindDuration:
                h.buf = append(h.buf, `"`...)
                h.buf = append(h.buf, val.Duration().String()...)
                h.buf = append(h.buf, `"`...)
        case slog.KindFloat64:
                h.buf = strconv.AppendFloat(h.buf, val.Float64(), 'f', -1, 64)
        case slog.KindInt64:
                h.buf = strconv.AppendInt(h.buf, val.Int64(), 10)
        case slog.KindString:
                h.buf = appendString(h.buf, val.String())
        case slog.KindTime:
                h.buf = append(h.buf, `"`...)
                h.buf = val.Time().AppendFormat(h.buf, time.RFC3339Nano)
                h.buf = append(h.buf, `"`...)
        case slog.KindUint64:
                h.buf = strconv.AppendUint(h.buf, val.Uint64(), 10)
        default:
                panic("unhandled kind" + val.Kind().String())
        }
        h.confirmedLast = len(h.buf)
}

// json string encoder copied from encoding/json

func appendString[Bytes []byte | string](dst []byte, src Bytes) []byte {
        dst = append(dst, '"')
        start := 0
        for i := 0; i < len(src); {
                if b := src[i]; b < utf8.RuneSelf {
                        if safeSet[b] {
                                i++
                                continue
                        }
                        dst = append(dst, src[start:i]...)
                        switch b {
                        case '\\', '"':
                                dst = append(dst, '\\', b)
                        case '\b':
                                dst = append(dst, '\\', 'b')
                        case '\f':
                                dst = append(dst, '\\', 'f')
                        case '\n':
                                dst = append(dst, '\\', 'n')
                        case '\r':
                                dst = append(dst, '\\', 'r')
                        case '\t':
                                dst = append(dst, '\\', 't')
                        default:
                                // This encodes bytes < 0x20 except for \b, \f, \n, \r and \t.
                                // If escapeHTML is set, it also escapes <, >, and &
                                // because they can lead to security holes when
                                // user-controlled strings are rendered into JSON
                                // and served to some browsers.
                                dst = append(dst, '\\', 'u', '0', '0', hex[b>>4], hex[b&0xF])
                        }
                        i++
                        start = i
                        continue
                }
                // TODO(https://go.dev/issue/56948): Use generic utf8 functionality.
                // For now, cast only a small portion of byte slices to a string
                // so that it can be stack allocated. This slows down []byte slightly
                // due to the extra copy, but keeps string performance roughly the same.
                n := len(src) - i
                if n > utf8.UTFMax {
                        n = utf8.UTFMax
                }
                c, size := utf8.DecodeRuneInString(string(src[i : i+n]))
                if c == utf8.RuneError && size == 1 {
                        dst = append(dst, src[start:i]...)
                        dst = append(dst, `\ufffd`...)
                        i += size
                        start = i
                        continue
                }
                // U+2028 is LINE SEPARATOR.
                // U+2029 is PARAGRAPH SEPARATOR.
                // They are both technically valid characters in JSON strings,
                // but don't work in JSONP, which has to be evaluated as JavaScript,
                // and can lead to security holes there. It is valid JSON to
                // escape them, so we do so unconditionally.
                // See https://en.wikipedia.org/wiki/JSON#Safety.
                if c == '\u2028' || c == '\u2029' {
                        dst = append(dst, src[start:i]...)
                        dst = append(dst, '\\', 'u', '2', '0', '2', hex[c&0xF])
                        i += size
                        start = i
                        continue
                }
                i += size
        }
        dst = append(dst, src[start:]...)
        dst = append(dst, '"')
        return dst
}
```
