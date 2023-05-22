# alerts in yaml

## weird apis

### _alerts_ in yaml

For unfortunate reasons,
I've had to come up with an interface for configuring alerts through yaml
(that gets templated through helm, then terraform, then datadog messaging dsl).

This was the structure I ended up with:

- all object based to allow easy threshold overrides in different files
- a single source of truth for id (the alert title)
- canned alerts for common stuff

```yaml
alert-config:
  metric_based_alerts:
    "alert 1":
      query:
        predefined: "type-1"
        threshold: 55
      message: |
        oops stuff broke

    "alert 2":
      query:
        raw: "sum(last_5m):sum:my.metric{instance:INSTACE}"
        threshold: 22
      message: |
        another thing broke

  alert_based_slos:
    "slo 1":
      metric_alerts:
        - "alert 1"
        - "alert 2"
      target: 99.9
```
