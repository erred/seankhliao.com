# renovate bot custom versioning

## understanding what your coworker copy and pasted into the Dockerfile


### _renovate_

We run [renovate](https://github.com/renovatebot/renovate) to watch upstream sources
and file PRs that automatically bump dependency versions for us.
A lot of standard things will work out of the box (more or less).
But sometimes just have custom stuff.

#### _dockerfile_

Our most common example is in Dockerfiles:

```Dockerfile
FROM xxx/yyy:zzz

ARG FOO_VERSION=1.2.3
ARG BAR_VERSION=v2.0.1

RUN curl -fsL -O https://example.com/${FOO_VERSION}/foo.tar.gz
RUN curl -fsL -O https://bar.example/${BAR_VERSION}/bar_v${BAR_VERSION}.tar.gz

...
```

#### _custom_ manager

ref: [regex manager](https://docs.renovatebot.com/modules/manager/regex/)

Instead of defining a new rule for every dependency centrally in your `renovate.json` config,
you could instead define a custom / meta manager:

```json
{
  "regexManagers": [
    {
      "fileMatch": ["^Dockerfile$"],
      "matchStrings": [
        "datasource=(?<datasource>.*?) depName=(?<depName>.*?)( versioning=(?<versioning>.*?))?\\sARG .*?_VERSION=(?<currentValue>.*)\\s"
      ],
      "versioningTemplate": "{{#if versioning}}{{{versioning}}}{{else}}semver{{/if}}"
    }
  ]
}
```

What's happening is you're declaring a regex that captures all the information
needed to update a dependency from comments as well as the value to update.

##### _fields_

ref: [regexManagers](https://docs.renovatebot.com/configuration-options/#regexmanagers)

Using `lookupName` (defaults to `depName`),
renovate searches `datasource` for version strings.
This is passed through `extractVersion` to pull out the actual versions
and compared to `currentValue` with the `versioning` strategy to determine if an update is needed.

Ex:

```
# renovate: datasource=github-tags depName=jenkinsci/remoting extractVersion=^remoting-(?<version>.*)$ versioning=regex:^(?<major>\d+)\.(?<minor>\d+)$
ARG JENKINS_AGENT_VERSION=4.10
```

renovate searches github tags (which are `remoting-4.1`, `remoting-4.2` ...),
extracts the version number out (`4.1`, `4.2`)
and compares them with major.minor
