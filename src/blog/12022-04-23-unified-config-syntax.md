# unified config syntax

## one config language to rule them all?


### _unified_ config

If you've written any amount of deployment config for a moderately complex app,
you might be familiar with the pattern of:
the deployment config being structured,
the app config being structured,
but embedded as a string within the deployment config.
This is unfortunate,
since you lose syntax checking etc.

Example, yaml in yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: map1
data:
  config.yaml: |
    foo: bar
    structured:
      config:
        - in
        - a
        - string
```

Example: json in hcl
```terraform
resource "aws_iam_policy" "policy" {
  name = "foo"
  policy = <<EOF
    {
      "Version": "1"
      "Statement": [{
        "Action": [
          "ec2:Describe*"
        ]
      }]
    }
  EOF
}
```

#### _breakout_ into a file

One solution would be to break things out into their own files,
and include the result,
each one gets its own filetype,
but that doesn't compose well,
and if you need templating within the nested config,
you now have an incomplete config with invalid syntax.
Also, this is very much tied to the tool you're using

Example: helm
```helm
apiVersion: v1
kind: ConfigMap
metadata:
  name: map1
data:
  config.yaml: {{ $.Files.Get "config.yaml" }}
```

Example: terraform
```terraform
resource "aws_iam_policy" "policy" {
  name = "foo"
  policy = file("policy.json")
}
```

#### _config_ conversion

So, if your config language supports it,
you can do the conversions inline:

```terraform
resource "aws_iam_policy" "policy" {
  name = "foo"
  policy = jsonencode({
    Version = "1"
    Statement = [{
      Action = [
        "ec2:Describe*",
      ]
    }]
  })
}
```

#### _cue_

So what do you do?
Thankfully, most config tools accept json as input,
so instead of writing the
You add a level of indirection with [cue](https://cuelang.org/).

```cue
resource: aws_iam_policy: policy: {
  name: "foo"
  policy: json.Marshal({
    Version: "1"
    Action: [
      "ec2:Describe*",
    ]
  })
}
```

```
apiVersion: v1
kind: ConfigMap
metadata: name: foo
data: config.yaml: yaml.Marshal({
  foo: bar
  structured: config: [
    "in",
    "a",
    "string",
  ]
})
```
