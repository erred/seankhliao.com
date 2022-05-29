# Envoy ExtAuth gRPC service with Go

## pushing auth to the network


### envoy

[envoy](https://www.envoyproxy.io/)
can do [external authorization](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/ext_authz_filter#config-http-filters-ext-authz)
(checking each request if it should be allowed to continue)
over http or grpc.

So naturally, i wanted to try it.
The raw proto files are in [envoyproxy/envoy](https://github.com/envoyproxy/envoy/blob/main/api/envoy/extensions/filters/http/ext_authz/v3/ext_authz.proto),
there's a read only mirror of just the protos in [envoyproxy/data-plane-api](https://github.com/envoyproxy/data-plane-api/blob/main/envoy/service/auth/v3/external_auth.proto)
and there's [envoyproxy/go-control-plane](https://github.com/envoyproxy/go-control-plane/tree/main/envoy/service/auth/v3)
which has other stuff, but more importantly, pregenerated protobuf/grpc Go code that we can import.

So a very simple partial implementation would look like:

```go
package authd

import (
        "context"
        "net/http"

        envoy_config_core_v3 "github.com/envoyproxy/go-control-plane/envoy/config/core/v3"
        envoy_service_auth_v3 "github.com/envoyproxy/go-control-plane/envoy/service/auth/v3"
        envoy_type_v3 "github.com/envoyproxy/go-control-plane/envoy/type/v3"
        "google.golang.org/genproto/googleapis/rpc/status"
        "google.golang.org/grpc/codes"
)

type sessionStore interface {
        GetUser(string) string
}

type GServer struct {
        authURL      string
        cookieName   string
        sessionStore sessionStore

        envoy_service_auth_v3.UnimplementedAuthorizationServer
}

func (s *GServer) Check(ctx context.Context, req *envoy_service_auth_v3.CheckRequest) (*envoy_service_auth_v3.CheckResponse, error) {
        sess := s.extractSession(req)
        if sess == "" {
                return s.unauthorized("no session"), nil
        }
        user := s.sessionStore.GetUser(sess)
        if user == "" {
                return s.unauthorized("no user"), nil
        }
        return s.ok(user), nil
}

func (s *GServer) ok(user string) *envoy_service_auth_v3.CheckResponse {
        return &envoy_service_auth_v3.CheckResponse{
                Status: &status.Status{
                        Code: int32(codes.OK),
                },
                HttpResponse: &envoy_service_auth_v3.CheckResponse_OkResponse{
                        OkResponse: &envoy_service_auth_v3.OkHttpResponse{
                                Headers: []*envoy_config_core_v3.HeaderValueOption{
                                        {
                                                Header: &envoy_config_core_v3.HeaderValue{
                                                        Key:   "authd_user",
                                                        Value: user,
                                                },
                                        },
                                },
                        },
                },
        }
}

func (s *GServer) unauthorized(msg string) *envoy_service_auth_v3.CheckResponse {
        return &envoy_service_auth_v3.CheckResponse{
                Status: &status.Status{
                        Code:    int32(codes.PermissionDenied),
                        Message: msg,
                },
                HttpResponse: &envoy_service_auth_v3.CheckResponse_DeniedResponse{
                        DeniedResponse: &envoy_service_auth_v3.DeniedHttpResponse{
                                Status: &envoy_type_v3.HttpStatus{
                                        Code: envoy_type_v3.StatusCode_Found,
                                },
                                Headers: []*envoy_config_core_v3.HeaderValueOption{
                                        {
                                                Header: &envoy_config_core_v3.HeaderValue{
                                                        Key:   "location",
                                                        Value: s.authURL,
                                                },
                                        },
                                },
                        },
                },
        }
}

func (s *GServer) extractSession(req *envoy_service_auth_v3.CheckRequest) string {
        switch {
        case req == nil:
                return ""
        case req.Attributes == nil:
                return ""
        case req.Attributes.Request == nil:
                return ""
        case req.Attributes.Request.Http == nil:
                return ""
        case req.Attributes.Request.Http.Headers == nil:
                return ""
        }
        rawCookies := req.Attributes.Request.Http.Headers["cookie"]
        httpReq := http.Request{
                Header: map[string][]string{
                        "Cookie": {rawCookies},
                },
        }
        cookie, err := httpReq.Cookie(s.cookieName)
        if err != nil {
                return ""
        }
        return cookie.Value
}
```

and using it in envoy:

```yaml
static_resources:
  listeners:
    - name: https
      address:
        socket_address:
          address: 0.0.0.0
          port_value: 443
      listener_filters:
        - name: "envoy.filters.listener.tls_inspector"
      per_connection_buffer_limit_bytes: 32768 # 32 KiB
      filter_chains:
        - filter_chain_match:
            server_names:
              - auth-test.seankhliao.com
          transport_socket:
            name: envoy.transport_sockets.tls
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.DownstreamTlsContext
              common_tls_context: *commontls
          filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: ingress_http
                use_remote_address: true
                normalize_path: true
                merge_slashes: true
                path_with_escaped_slashes_action: REJECT_REQUEST
                common_http_protocol_options: *commonhttp
                http2_protocol_options:
                  max_concurrent_streams: 100
                  initial_stream_window_size: 65536 # 64 KiB
                  initial_connection_window_size: 1048576 # 1 MiB
                http_filters:
                  - name: envoy.filters.http.ext_authz
                    typed_config:
                      "@type": type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz
                      grpc_service:
                        envoy_grpc:
                          cluster_name: authd
                      transport_api_version: V3
                  - name: envoy.filters.http.router
                route_config:
                  virtual_hosts:
                    - name: auth-test
                      domains:
                        - auth-test.seankhliao.com
                      routes:
                        match:
                          prefix: /
                        route:
                          cluster: medea

  clusters:
    - name: authd
      typed_extension_protocol_options:
        envoy.extensions.upstreams.http.v3.HttpProtocolOptions:
          "@type": type.googleapis.com/envoy.extensions.upstreams.http.v3.HttpProtocolOptions
          explicit_http_config:
            http2_protocol_options: {}
      load_assignment:
        cluster_name: authd
        endpoints:
          lb_endpoints:
            - endpoint:
                address:
                  socket_address:
                    address: 127.0.0.1
                    port_value: 28006
```
