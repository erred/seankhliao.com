# failed: k8s crd jsonschema

## too much yaml

### yaml-language-server k8s manifests

My editor of choice is [neovim](https://neovim.io/)
and when editing yaml files,
I make use of language servers,
specifically [yaml-language-server](https://github.com/redhat-developer/yaml-language-server).
When working with kubernetes manifests specifically,
I have the following config,
making use of the versioned kuberentes json schemas available in
[yannh/kubernetes-json-schema](https://github.com/yannh/kubernetes-json-schema).

```lua
local lspconfig = require("lspconfig")
lspconfig.yamlls.setup({
    settings = {
        yaml = {
             schemas = {
                ["file:///home/user/third_party/kubernetes-json-schema/default/v1.27.3-standalone/all.json"] = {"*.k8s.yaml"},
                kubernetes = "",
             },
        },
    },
})
```

But now there's an issue:
that `all.json` only references the builtin kubernetes types,
meaning it doesn't include any CRDs.
Apparently, VS Code can connect to a running K8s cluster and grab CRDs from there,
mentioned [in an issue for content based schema matching](https://github.com/redhat-developer/yaml-language-server/issues/605)
but the rest of us don't have that.

Kubernetes serves openapi v2.0 over on `/openapi/v2`,
retrievable with `kubectl get --raw /openapi/v2` or `kubectl proxy --port 8001 & ; curl localhost:8001/openapi/v2`.
There's also openapi v3.0 on `/openapi/v3`,
but v3 is a bunch of linked documents rather than one big one like v2.
I thought I could use the same tooling as `kubernetes-json-schema`,
specifically [openapi2jsonschema](https://github.com/instrumenta/openapi2jsonschema)
and generate a new `all.json` refeencing all the types i have in my cluster,
but I think that might be too many types,
and `yaml-language-server` just ends up confused:
it kept thinking my Gateway should be something ValidatingWebhookConfiguration.

For now,
I think just using modelines might be the most reliable way for schema validation.
