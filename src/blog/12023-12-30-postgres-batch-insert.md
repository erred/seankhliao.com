# postgres batch insert

## inserting lots of values into postgres from go

### _inserting_ lots of values into postgres

So how do you insert a bunch of values into a postgres database?
You could call `insert` a bunch of times.
You could do the same thing but in a transaction.
There's also the `unnest` function (which is sadly not portable to sqlite),
or there's the magic `CopyFrom` function which goes zoom.

```go
package main

import (
        "context"
        "crypto/rand"
        "encoding/hex"
        mathrand "math/rand"
        "os"
        "testing"

        "github.com/jackc/pgx/v5"
)

func BenchmarkBatchInsert(b *testing.B) {
        dataStrings := make([]string, 1048576)
        dataInt := make([]int, 1048576)
        for i := 0; i < len(dataStrings); i++ {
                dataInt[i] = mathrand.Int()
                buf := make([]byte, 16)
                rand.Read(buf)
                dataStrings[i] = hex.EncodeToString(buf)
        }

        b.Run("separate", func(b *testing.B) {
                ctx, conn := getConn("separate")
                b.ResetTimer()

                for i := 0; i < b.N; i++ {
                        _, err := conn.Exec(ctx, `insert into separate (a, b) values ($1, $2)`, dataStrings[i], dataInt[i])
                        if err != nil {
                                panic(err)
                        }
                }
        })
        b.Run("single_tx", func(b *testing.B) {
                ctx, conn := getConn("single_tx")
                b.ResetTimer()

                tx, err := conn.BeginTx(ctx, pgx.TxOptions{})
                if err != nil {
                        panic(err)
                }
                defer tx.Commit(ctx)

                for i := 0; i < b.N; i++ {
                        _, err := tx.Exec(ctx, `insert into single_tx (a, b) values ($1, $2)`, dataStrings[i], dataInt[i])
                        if err != nil {
                                panic(err)
                        }
                }
        })
        b.Run("unnest", func(b *testing.B) {
                ctx, conn := getConn("unnest")
                b.ResetTimer()
                _, err := conn.Exec(ctx, `insert into unnest select * from unnest($1::text[], $2::numeric[]);`, dataStrings[:b.N], dataInt[:b.N])
                if err != nil {
                        panic(err)
                }
        })
        b.Run("copy", func(b *testing.B) {
                ctx, conn := getConn("copy")

                rows := make([][]any, 0, len(dataStrings))
                for i := 0; i < len(dataStrings); i++ {
                        rows = append(rows, []any{dataStrings[i], dataInt[i]})
                }

                b.ResetTimer()
                _, err := conn.CopyFrom(ctx, pgx.Identifier{"copy"}, []string{"a", "b"}, pgx.CopyFromRows(rows[:b.N]))
                if err != nil {
                        panic(err)
                }
        })
}

func getConn(name string) (context.Context, *pgx.Conn) {
        ctx := context.Background()
        conn, err := pgx.Connect(ctx, os.Getenv("DATABASE_URL"))
        if err != nil {
                panic(err)
        }

        _, err = conn.Exec(ctx, `drop table if exists `+name+`;`)
        if err != nil {
                panic(err)
        }
        _, err = conn.Exec(ctx, `create table `+name+` ( a text, b numeric);`)
        if err != nil {
                panic(err)
        }

        return ctx, conn
}
```

Benchmark results:

```sh
$ go test -bench=. -benchtime=100000x
goos: linux
goarch: amd64
pkg: go.seankhliao.com/testrepo0482
cpu: 12th Gen Intel(R) Core(TM) i7-1260P
BenchmarkBatchInsert/separate-16                  100000           253591 ns/op
BenchmarkBatchInsert/single_tx-16                 100000            26578 ns/op
BenchmarkBatchInsert/unnest-16                    100000             1267 ns/op
BenchmarkBatchInsert/copy-16                      100000              352.2 ns/op
PASS
ok          go.seankhliao.com/testrepo0482        28.838s
```
