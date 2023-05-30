# shell loop structured data

## json all the things

### _shell_ loop with structured data

So, again I've found a need to loop over a set of instances
with multiple pieces of metadata for each instance in a shell script.
In a proper programming language,
I'd just define a list of objects,
and loop over that.
Example (in Go):

```go
func f(){
  tasks := []struct{
    name string
    url string
    account_id int
  }{
    {
      "instance1", "https://a.example", 1,
    }, {
      "instance2", "https://b.example", 2,
    }
  }
  for _, task := range tasks {
    // do the things here
    _ = task.url
  }
}
```

#### _jq_ to the rescue

Bash and most other shells don't have high dimensional data structures.
You get lists, hashmaps and that's it.
You could sort of fake it with weird key structures,
but I'd rather not.

So why not just use json and jq....
Of course, replace json+jq with yaml+yq or xml+yq or...

```bash
cat << EOF > data.json
[{
  "name": "instance1",
  "url": "https://a.example",
  "account_id": 1
},{
  "name": "instance2",
  "url": "https://b.example",
  "account_id": 2
}]
EOF

for name in $(jq '.[] | .name' data.json); do
  # do the things here
  url=$(jq --arg name "${name}" '.[] | select(.name == "\($name)") | .url' data.json)
done
```
