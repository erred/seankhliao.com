# go error handling proposals

## overview of error handling proposals in go

_note:_ updated 12022-12-02

### _error_ handling

```go
if err != nil {
        // handle error
}
```

Error handling seems to be a recurring theme in go,
but most proposals get nowhere.

- [Go2ErrorHandlingFeedback](https://github.com/golang/go/wiki/Go2ErrorHandlingFeedback)
- [label:error-handling](https://go.dev/issue?q=is%3Aissue+label%3Aerror-handling)

#### _proposals_

baseline code

```go
x, err := foo()
if err != nil {
        return nil, wrap(err)
}
```

##### _handling_

_note:_ almost all the ones that claim to use "plain functions" as error handlers have an implicit nonlocal return

###### _predeclared_ handlers

- [`handle err { return _, wrap(err) }`<br>`x := check foo()`](https://go.googlesource.com/proposal/+/master/design/go2draft-error-handling.md): block scoped
- [`handle err { return _, wrap(err) }`<br>`x, # := foo()`](https://gist.github.com/oktalz/f04f36a3c2f61af22c7a6e06095d18eb)
- [`handle func(err error) (T, error) { return _, wrap(err) }`<br>`x, ? := foo()`](https://github.com/rockmenjack/go-2-proposals/blob/master/error_handling.md)
- [`watch err { if err != nil { return _, wrap(err) } }`<br>`x, err != foo()`](https://go.dev/issue/40821)
- [`expect err != nil { return _, wrap(err) }`<br>`x, err := foo()`](https://go.dev/issue/32804)
- [`with { return _, wrap(err) }`<br>`handle err { x, err := foo() }`](https://go.dev/issue/32795)

###### _call_ specific handler

- [`x, #err := foo()`<br>`catch err { return _, wrap(err) }`](https://go.dev/issue/27519): tagged error handlers
- [`x, @err := foo()`<br>`err: return _, wrap(err)`](https://gist.github.com/dpremus/3b141157e7e47418ca6ccb1fc0210fc7): goto label
- [`grab err() { if err != nil { return _, wrap(err) } }`<br>`x, err() := foo()`](https://didenko.github.io/grab/grab_worth_it_0.1.1.html#12): assign to handler
- [`err := inline(err error){ if err != nil { return _, wrap(err) } }`<br>`x, err := foo()`](https://github.com/gooid/gonotes/blob/master/inline_style_error_handle.md): assign to handler
- [`err := func(err error) (T, error) { return _, wrap(err) }`<br>`x, #err := foo()`](https://gist.github.com/the-gigi/3c1acfc521d7991309eec140f40ccc2b): block scoped
- [`_check = func(err error) (T, error) { return _, wrap(err) }`<br>`x, ?err := foo()`](https://gist.github.com/8lall0/cb43e1fa4aae42bc709b138bda02284e): not fully formed idea on return
- [`handler := func(err error) (T, error) { return _, wrap(err) }`<br>`x, #handler(_) := foo()`](https://go.dev/issue/57052): implicit nil check
- [`handler := func(err error) (T, error) { return^2 _, wrap(err) }`<br>`x, handler(err) := foo()`](https://go.dev/issue/32473): note nonlocal return
- [`handler := func(err error) (T, error) { eject _, wrap(err) }`<br>`x, err := foo()`<br>`inject handler(err)`](https://groups.google.com/g/golang-nuts/c/ZwQ1WV1-9_4/m/y6uP8jRyEgAJ)
- [`x, !err := foo() throw handler`<br>`catch handler { return wrap(err) }`](https://go.dev/issue/48896)
- [`goto x, err := foo()`<br>`r:`<br>`return _, wrap(err)`](https://go.dev/issue/53074)
- [`trap func(err2 error) { err = wrap(err2) }`<br>`x, _ := foo()`](https://go.dev/issue/56258): like defer, triggers on every error

##### _wrapping_

some rely on `wrap` being smart and passing through `nil` (so not `fmt.Errorf`),

- [`x, err := foo()`<br>`reflow _, wrap(err)`](https://go.dev/issue/21146): implicit `err != nil` and return
- [`x, err := foo()`<br>`refuse _, wrap(err)`](https://gist.github.com/alexhornbake/6a4c1c6a0f2a063da6dda1bf6ec0f5f3)
- [`x, err := foo()`<br>`pass _, wrap(err)`](https://go.dev/issue/37141)
- [`x, err := foo()`<br>`ereturn _, wrap(err)`](https://go.dev/issue/38349)
- [`x, err := foo()`<br>`err ?: return _, wrap(err)`](https://go.dev/issue/32946)
- [`x, err := foo()`<br>`on err, return _, wrap(err)`](https://go.dev/issue/32611)
- [`x, err := foo()`<br>`on err return handler()`](https://go.dev/issue/48855)
- [`x, err := foo()`<br>`err ? { return _, wrap(err) }`](https://go.dev/issue/33067)
- [`x, err := foo()`<br>`onErr { return _, wrap(err) }`](https://go.dev/issue/32946)
- [`x, err := foo()`<br>`try err: _, wrap(err)`](https://go.dev/issue/56159)
- [`x, err := foo()`<br>`try err, wrap`](https://go.dev/issue/56165)
- [`x, err := foo()`<br>`if err != nil { return _, wrap(err) }`](https://go.dev/issue/33113), [also](https://go.dev/issue/27135): if ... on 1 line
- [`x, err := foo()`<br>`if err != nil { return wrap(err) }`](https://go.dev/issue/56628): implicit zero values for other returns
- [`x, err := foo()`<br>`if !err { return _, wrap(err) }`](https://gist.github.com/fedir/50158bc351b43378b829948290102470)
- [`x, err := foo()`<br>`if err { return _, wrap(err) }`](https://go.dev/issue/26712)
- [`x, err := foo()`<br>`if err? { return _, wrap(err) }`](https://go.dev/issue/32845)
- [`x, err := foo()`<br>`return wrap(err) if err != nil`](https://go.dev/issue/27794), [also](https://go.dev/issue/32860)
- [`x, err := foo()`<br>`return if err != nil { _, wrap(err) }`](https://go.dev/issue/52977), [also](https://go.dev/issue/53017)
- [`x, err := foo()`<br>`return(err) wrap(err)`](https://go.dev/issue/28229)
- [`x, err := foo(); if err != nil { return _, wrap(err) }`](https://gist.github.com/jozef-slezak/93a7d9d3d18d3fce3f8c3990c031f8d0), [also](https://go.dev/issue/27450): everything on 1 line
- [`x, err := foo() ?? { return _, wrap(err) }`](https://go.dev/issue/37243)
- [`x, err := foo() else { return _, wrap(err) }`](https://go.dev/issue/56895)
- [`x, err := foo() /* err */ { return _, wrap(err) }`](https://github.com/gooid/gonotes/blob/master/inline_style_error_handle.md), 
- [`x, err := foo() { return _, wrap(err) }`](https://go.dev/issue/41908), [also](https://go.dev/issue/54686)
- [`x, err := foo(); err.return wrap(err)`](https://go.dev/issue/39372)
- [`x, wrap() := foo()`](https://go.dev/issue/43644)
- [`x, wrap(err) := foo()`](https://go.dev/issue/52416)
- [`x := foo() or err: return _, wrap(err)`](https://go.dev/issue/33029)
- [`x := foo() ?err return _, wrap(err)`](https://go.dev/issue/33074)
- [`x := check wrap() foo()`](https://gist.github.com/jozef-slezak/93a7d9d3d18d3fce3f8c3990c031f8d0), [also](https://gist.github.com/morikuni/bbe4b2b0384507b42e6a79d4eca5fc61)
- [`x := check foo() with wrap(err)`](https://go.dev/issue/49091)
- [`x := foo() ? wrap()`](https://gist.github.com/gregwebs/02479eeef8082cd199d9e6461cd1dab3)
- [`x := foo() or wrap()`](https://go.dev/issue/36338)
- [`x := foo() || wrap(err)`](https://go.dev/issue/21161)
- [`x := foo() on_error err fail wrap(err)`](https://medium.com/@peter.gtz/thinking-about-new-ways-of-error-handling-in-go-2-e56d116952f1)
- [`x := foo() onerr return _, wrap(err)`](https://go.dev/issue/32848)
- [`x := foo() // error: err => wrap(err)`](https://go.dev/issue/47934) error handling in comments
- [`x := try(foo(), wrap)`](https://go.dev/issue/32853)
- [`x := try foo() or return _err`](https://go.dev/issue/52175)
- [`x := try foo(), wrap`](https://go.dev/issue/55026)
- [`x := collect(&err, foo(), wrap)`](https://go.dev/issue/32880)
- [`if x, err := foo(); err != nil then return _, wrap(err)`](https://go.dev/issue/46717)
- [`try x, err := foo() { return _, wrap(err) }`](https://go.dev/issue/39890)

##### _return_

can use `defer` for wrapping

- [`x := try(foo())`](https://go.googlesource.com/proposal/+/master/design/32437-try-builtin.md)
- [`x := must(foo())`](https://go.dev/issue/32219): panic instead of return
- [`x := handle foo()`](https://go.dev/issue/54677)
- [`x := guard foo()`](https://go.dev/issue/31442)
- [`x := must foo()`](https://gist.github.com/VictoriaRaymond/d70663a6ec6cdc59816b8806dccf7826)
- [`x := foo!()`](https://go.dev/issue/21155)
- [`x := foo()?`](https://gist.github.com/yaxinlx/1e013fec0e3c2469f97074dbf5d2e2c0), [also](https://go.dev/issue/39451), [also](https://go.dev/issue/51146)
- [`x := #foo()`](https://go.dev/issue/18721)
- [`x, # := foo()`](https://go.dev/issue/22122): panic instead of return
- [`x, ~ := foo()`](https://go.dev/issue/50207): wrap with stacktraces
- [`x, - := foo()`](https://go.dev/issue/52415)
- [`x, ? := foo()`](https://go.dev/issue/42214), [also](https://go.dev/issue/32601), [also](https://go.dev/issue/56355)
- [`x, ! := foo()`](https://gist.github.com/lldld/bf93ca94c24f172e95baf8c123427ace), [also](https://go.dev/issue/33150), [panic](https://go.dev/issue/35644)
- [`x, !! := foo()`](https://go.dev/issue/32884)
- [`x, !err := foo()`](https://go.dev/issue/14066)
- [`x, ^err := foo()`](https://go.dev/issue/42318)
- [`x, err? := foo()`](https://go.dev/issue/36390)
- [`x, err := foo() throws err`](https://go.dev/issue/32852)
- [`x, check err := foo()`](https://go.dev/issue/46655)
- [`tryfunc func(...){ x := foo() }`](https://go.dev/issue/32964)
- [`x, err := foo()`<br>`check(err)`](https://go.dev/issue/33233): builtin `if err != nil { return ..., err }` macro
- [`x, err := foo()`<br>`catch(err)`](https://go.dev/issue/32811): builtin `if err != nil { return ..., err }` macro
- [`x := foo().handleErr()`](https://go.dev/issue/56126):  builtin `if err != nil { return ..., err }` macro
- [`x := foo() -> throw err`](https://go.dev/issue/51415)

##### _try..catch_

- [`try { x := foo() } catch(e Exception) { ??? }`](https://www.netroby.com/view/3910), [also](https://go.dev/issue/43777): literally try catch
- [`try err != nil { x, err := foo() } except { return _, wrap(err) }`](https://go.dev/issue/33387)
- [`try { x := foo(); if err != nil { return _, wrap(err) } }`](https://go.dev/issue/35179)
- [`try { x, $ := foo() } catch(err) { return _, wrap(err) }`](https://go.dev/issue/46433)
- [`until err != nil { check x, err := foo() } else { return _, wrap(err) }`](https://gist.github.com/coquebg/afe44e410f883a313dc849da3e1ff34c): insert after every `check`
- [`break err != nil { step: x, err := foo() }`](https://go.dev/issue/27075): insert after every repeatable label
- [`break err != nil { try x, err := foo() }`](https://go.dev/issue/27075): insert after every `try`
- [`if x, err := foo(); err != nil { return _, wrap(err) } else { ... } undo { ??? } done { ??? } defer { ??? }`](https://gist.github.com/jansemmelink/235228a0fb56d0eeba8085ab5f8178f3)
- [`handler := func(err error) error { return wrap(err) }`<br>`check(handler){ x := foo() }`](https://devmethodologies.blogspot.com/2018/10/go-error-handling-using-closures.html)
- [`check { x := check foo() } handle err { return _, wrap(err) }`](https://gist.github.com/mathieudevos/2bdae70596aca711e50d1f2ff6d7b7cb)
- [`check { x, err1 := foo() } catch err { return _, wrap(err) }`](https://gist.github.com/eau-de-la-seine/9e2e74d6369aef4a76aa50976e34de6d)
- [`check { x, err := foo()`<br>`catch: return _, wrap(err) }`](https://go.dev/issue/32968)
- [`x, err := foo() !!!`<br>`fail: return _, wrap(err)`](https://go.dev/issue/34140): goto label
- [`handle err { x, err := foo()`<br>`case err != nil: return _, wrap(err) }`](https://go.dev/issue/35086)
- [`throw "err"`<br>`catch func(err error) { return _, wrap(err) }`]()

##### _others_

- [`x, (err) := foo()`](https://go.dev/issue/21732): only assign to LHS if `()` content is not currently `nil`
- [`collect err { x, _! := foo() }`<br>`if err != nil { return _, wrap(err) }`](https://go.dev/issue/25626): err is an value that accumulates errors? does it continue?
- [`errorhandling(err){ x, err := foo() }`](https://github.com/Konstantin8105/Go2ErrorTree): err is an accumulator? messes with types
- [`x, err := foo()`<br>`handle err1 || err2 || err3 { return _, wrap(err) }`](https://gist.github.com/Kiura/4826db047e22b7720d378ac9ac642027): shorter if chain?
- [nonlocal return](https://go.dev/issue/35093)
- [nonlocal return with return type](https://go.dev/issue/42811)
- [`returnfrom label, err`](https://gist.github.com/spakin/86ea86ca48aefc78b672636914f4fc23): nonlocal return
- [result type](https://go.dev/issue/19991): box of `value|err` allows passthrough
- [`if x, err := foo().bar().baz(); err != nil { return _, wrap(err) }`](https://go.dev/issue/44928): chaining method calls with return type `(T, error)`
- [`func foo() (return, string)`](https://go.dev/issue/42811): return is a type of bool that does... something
- [`ErrorOr[T]`](https://go.dev/issue/51931): new convention instead of `return T, err`
- [`x := foo()`<br>`if x@error != nil { ... }`](https://gist.github.com/Space-Tide/e96284861434b46c6c730f9c73024373)
