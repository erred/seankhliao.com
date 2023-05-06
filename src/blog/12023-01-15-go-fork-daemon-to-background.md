# go fork daemon to background

## sometimes you just need a persistent server

### _fork_ to background in Go

So, you want to execute a process,
forking it to the background and keep it running after the parent process exits.

First.... try not to do this,
mysterious persistent daemons is a management nightmare.

But if you need to do it:

```go
package main

import (
        "fmt"
        "os/exec"
        "syscall"
)

func main() {
        cmd := exec.Command("./background-process")
        cmd.SysProcAttr = &syscall.SysProcAttr{
                Setsid: true,
        }
        cmd.Start()
        fmt.Println("run, exit")
}
```

This makes use of [`setsid`],
starting a new process group disassociated with the current tree.
In Go, [`syscall.SysProcAttr.Setsid`] with a zero `Pgid` (parent group ID) starts a new group.
And [`os/exec.Cmd.Start`] doesn't wait for the process to complete.

[`setsid`]: https://man.archlinux.org/man/setsid.2.en
[`syscall.SysProcAttr.Setsid`]: https://pkg.go.dev/syscall#SysProcAttr
[`os/exec.Cmd.Start`]: https://pkg.go.dev/os/exec#Cmd.Start
