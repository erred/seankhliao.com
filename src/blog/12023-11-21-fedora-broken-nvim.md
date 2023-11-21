# fedora broken nvim

## weird lua errors

### _neovim_ on fedora is broken

I use [neovim](https://neovim.io/) as my editor,
because lua is slightly nicer than vimscript.
Anyway, I recently noticed that my previous depenency manager
[packer.nvim](https://github.com/wbthomason/packer.nvim) went unmaintained,
so off I went to replace it.

The first recommendation was [lazy.nvim](https://github.com/folke/lazy.nvim),
but... I think the laziness breaks too much stuff,
or I was too lazy to go figure out which plugins I needed not lazy load.

The other recommendation as [pckr.nvim](https://github.com/lewis6991/pckr.nvim),
which worked on my personal laptop running Arch.
The next day as I was updating my work laptop running Fedora (38),
I ran into an issue on startup:

```txt
Error detected while processing /root/.config/nvim/init.lua:
E5113: Error while calling lua chunk: /root/.local/share/nvim/pckr/pckr.nvim/lua/pckr/actions.lua:331: attempt to yield acro
ss C-call boundary
stack traceback:
        [C]: in function 'main'
        /root/.local/share/nvim/pckr/pckr.nvim/lua/pckr/actions.lua:331: in function 'install'
        /root/.local/share/nvim/pckr/pckr.nvim/lua/pckr.lua:55: in function 'add'
        /root/.config/nvim/init.lua:120: in main chunk
```

I'm still quite confused about how this could happen,
besides maybe neovim being built against a different lua version?
The version info wasn't too enlightening:

```
[root@63dcc201f703 nvim]# nvim --version
NVIM v0.9.4
Build type: RelWithDebInfo
LuaJIT 2.1.1692716794
Compilation: /usr/bin/gcc -O2 -g -Og -g -Wall -Wextra -pedantic -Wno-unused-parameter -Wstrict-prototypes -std=gnu99 -Wshadow -Wconversion -Wvla -Wdouble-promotion -Wmissing-noreturn -Wmissing-format-attribute -Wmissing-prototypes -fno-common -Wno-unused-result -Wimplicit-fallthrough -fdiagnostics-color=auto -fstack-protector-strong -DUNIT_TESTING -DINCLUDE_GENERATED_DECLARATIONS -D_GNU_SOURCE -DUSING_UV_SHARED=1 -I/usr/include/luajit-2.1 -I/usr/include -I/usr/include/luv -I/builddir/build/BUILD/neovim-0.9.4/redhat-linux-build/src/nvim/auto -I/builddir/build/BUILD/neovim-0.9.4/redhat-linux-build/include -I/builddir/build/BUILD/neovim-0.9.4/redhat-linux-build/cmake.config -I/builddir/build/BUILD/neovim-0.9.4/src -I/usr/include -I/usr/include -I/usr/include -I/usr/include -I/usr/include -I/usr/include -I/usr/include

   system vimrc file: "$VIM/sysinit.vim"
  fall-back for $VIM: "/usr/share/nvim"

Run :checkhealth for more info
```

Attempting to follow instructions to build from source:
[neovim/wiki/Building Neovim](https://github.com/neovim/neovim/wiki/Building-Neovim)
resulted in more errors:

```txt
FAILED: src/nvim/po/cs.mo /root/neovim/build/src/nvim/po/cs.mo
cd /root/neovim/build/src/nvim/po && /usr/bin/msgfmt -o /root/neovim/build/src/nvim/po/cs.mo /root/neovim/src/nvim/po/cs.po
/root/neovim/src/nvim/po/cs.po: warning: Charset "ISO-8859-2" is not supported. msgfmt relies on iconv(),
                                         and iconv() does not support "ISO-8859-2".
                                         Installing GNU libiconv and then reinstalling GNU gettext
                                         would fix this problem.
                                         Continuing anyway.
/usr/bin/msgfmt: Cannot convert from "ISO-8859-2" to "UTF-8". msgfmt relies on iconv(), and iconv() does not support this conversion.
[3/16] Generating cs.cp1250.mo
FAILED: src/nvim/po/cs.cp1250.mo /root/neovim/build/src/nvim/po/cs.cp1250.mo
cd /root/neovim/build/src/nvim/po && /usr/bin/msgfmt -o /root/neovim/build/src/nvim/po/cs.cp1250.mo /root/neovim/src/nvim/po/cs.cp1250.po
/root/neovim/src/nvim/po/cs.cp1250.po: warning: Charset "CP1250" is not supported. msgfmt relies on iconv(),
                                                and iconv() does not support "CP1250".
                                                Installing GNU libiconv and then reinstalling GNU gettext
                                                would fix this problem.
                                                Continuing anyway.
/usr/bin/msgfmt: Cannot convert from "CP1250" to "UTF-8". msgfmt relies on iconv(), and iconv() does not support this conversion.
[4/16] Generating ja.euc-jp.mo
FAILED: src/nvim/po/ja.euc-jp.mo /root/neovim/build/src/nvim/po/ja.euc-jp.mo
cd /root/neovim/build/src/nvim/po && /usr/bin/msgfmt -o /root/neovim/build/src/nvim/po/ja.euc-jp.mo /root/neovim/src/nvim/po/ja.euc-jp.po
/root/neovim/src/nvim/po/ja.euc-jp.po: warning: Charset "EUC-JP" is not supported. msgfmt relies on iconv(),
                                                and iconv() does not support "EUC-JP".
                                                Installing GNU libiconv and then reinstalling GNU gettext
                                                would fix this problem.
                                                Continuing anyway.
/usr/bin/msgfmt: Cannot convert from "EUC-JP" to "UTF-8". msgfmt relies on iconv(), and iconv() does not support this conversion.
[5/16] Generating sk.cp1250.mo
FAILED: src/nvim/po/sk.cp1250.mo /root/neovim/build/src/nvim/po/sk.cp1250.mo
cd /root/neovim/build/src/nvim/po && /usr/bin/msgfmt -o /root/neovim/build/src/nvim/po/sk.cp1250.mo /root/neovim/src/nvim/po/sk.cp1250.po
/root/neovim/src/nvim/po/sk.cp1250.po: warning: Charset "CP1250" is not supported. msgfmt relies on iconv(),
                                                and iconv() does not support "CP1250".
                                                Installing GNU libiconv and then reinstalling GNU gettext
                                                would fix this problem.
                                                Continuing anyway.
/usr/bin/msgfmt: Cannot convert from "CP1250" to "UTF-8". msgfmt relies on iconv(), and iconv() does not support this conversion.
[6/16] Generating sk.mo
FAILED: src/nvim/po/sk.mo /root/neovim/build/src/nvim/po/sk.mo
cd /root/neovim/build/src/nvim/po && /usr/bin/msgfmt -o /root/neovim/build/src/nvim/po/sk.mo /root/neovim/src/nvim/po/sk.po
/root/neovim/src/nvim/po/sk.po: warning: Charset "ISO-8859-2" is not supported. msgfmt relies on iconv(),
                                         and iconv() does not support "ISO-8859-2".
                                         Installing GNU libiconv and then reinstalling GNU gettext
                                         would fix this problem.
                                         Continuing anyway.
/usr/bin/msgfmt: Cannot convert from "ISO-8859-2" to "UTF-8". msgfmt relies on iconv(), and iconv() does not support this conversion.
[16/16] Generating ru.mo
ninja: build stopped: subcommand failed.
make: *** [Makefile:84: nvim] Error 1
```

Though this was resolved with:

```sh
$ yum install glibc-gconv-extra
```

And the custom build version worked with `pckr.nvim`.
So I still don't know why the packaged version is bad.
Also the tarballed releases from [neovim/releases](https://github.com/neovim/neovim/releases)
work too.
