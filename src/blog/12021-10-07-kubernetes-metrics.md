# kubernetes metrics

## ever wondered what metrics kubernetes exposes?

### _kubernetes_ metrics

Kubernetes generates quite a bit of metrics, but do you actually make use of them?
Do you know what that boilerplate you copy into every prometheus scrape config actually gathers?

#### _api-server_

`kubectl proxy` is a great way to get local access to the api server, also handles auth for you.

Pulled from 1.19, available on `https://kubernetes.default.svc/metrics`:

(excludes `go_`)

```
# HELP aggregator_openapi_v2_regeneration_count [ALPHA] Counter of OpenAPI v2 spec regeneration count broken down by causing APIService name and reason.
# TYPE aggregator_openapi_v2_regeneration_count counter
# HELP aggregator_openapi_v2_regeneration_duration [ALPHA] Gauge of OpenAPI v2 spec regeneration duration in seconds.
# TYPE aggregator_openapi_v2_regeneration_duration gauge
# HELP aggregator_unavailable_apiservice [ALPHA] Gauge of APIServices which are marked as unavailable broken down by APIService name.
# TYPE aggregator_unavailable_apiservice gauge
# HELP aggregator_unavailable_apiservice_total [ALPHA] Counter of APIServices which are marked as unavailable broken down by APIService name and reason.
# TYPE aggregator_unavailable_apiservice_total counter
# HELP apiextensions_openapi_v2_regeneration_count [ALPHA] Counter of OpenAPI v2 spec regeneration count broken down by causing CRD name and reason.
# TYPE apiextensions_openapi_v2_regeneration_count counter
# HELP apiserver_admission_controller_admission_duration_seconds [ALPHA] Admission controller latency histogram in seconds, identified by name and broken out for each operation and API resource and type (validate or admit).
# TYPE apiserver_admission_controller_admission_duration_seconds histogram
# HELP apiserver_admission_step_admission_duration_seconds [ALPHA] Admission sub-step latency histogram in seconds, broken out for each operation and API resource and step type (validate or admit).
# TYPE apiserver_admission_step_admission_duration_seconds histogram
# HELP apiserver_admission_step_admission_duration_seconds_summary [ALPHA] Admission sub-step latency summary in seconds, broken out for each operation and API resource and step type (validate or admit).
# TYPE apiserver_admission_step_admission_duration_seconds_summary summary
# HELP apiserver_admission_webhook_admission_duration_seconds [ALPHA] Admission webhook latency histogram in seconds, identified by name and broken out for each operation and API resource and type (validate or admit).
# TYPE apiserver_admission_webhook_admission_duration_seconds histogram
# HELP apiserver_admission_webhook_rejection_count [ALPHA] Admission webhook rejection count, identified by name and broken out for each admission type (validating or admit) and operation. Additional labels specify an error type (calling_webhook_error or apiserver_internal_error if an error occurred; no_error otherwise) and optionally a non-zero rejection code if the webhook rejects the request with an HTTP status code (honored by the apiserver when the code is greater or equal to 400). Codes greater than 600 are truncated to 600, to keep the metrics cardinality bounded.
# TYPE apiserver_admission_webhook_rejection_count counter
# HELP apiserver_audit_error_total [ALPHA] Counter of audit events that failed to be audited properly. Plugin identifies the plugin affected by the error.
# TYPE apiserver_audit_error_total counter
# HELP apiserver_audit_event_total [ALPHA] Counter of audit events generated and sent to the audit backend.
# TYPE apiserver_audit_event_total counter
# HELP apiserver_audit_level_total [ALPHA] Counter of policy levels for audit events (1 per request).
# TYPE apiserver_audit_level_total counter
# HELP apiserver_audit_requests_rejected_total [ALPHA] Counter of apiserver requests rejected due to an error in audit logging backend.
# TYPE apiserver_audit_requests_rejected_total counter
# HELP apiserver_client_certificate_expiration_seconds [ALPHA] Distribution of the remaining lifetime on the certificate used to authenticate a request.
# TYPE apiserver_client_certificate_expiration_seconds histogram
# HELP apiserver_crd_webhook_conversion_duration_seconds [ALPHA] CRD webhook conversion duration in seconds
# TYPE apiserver_crd_webhook_conversion_duration_seconds histogram
# HELP apiserver_current_inflight_requests [ALPHA] Maximal number of currently used inflight request limit of this apiserver per request kind in last second.
# TYPE apiserver_current_inflight_requests gauge
# HELP apiserver_envelope_encryption_dek_cache_fill_percent [ALPHA] Percent of the cache slots currently occupied by cached DEKs.
# TYPE apiserver_envelope_encryption_dek_cache_fill_percent gauge
# HELP apiserver_flowcontrol_read_vs_write_request_count_samples [ALPHA] Periodic observations of the number of requests
# TYPE apiserver_flowcontrol_read_vs_write_request_count_samples histogram
# HELP apiserver_flowcontrol_read_vs_write_request_count_watermarks [ALPHA] Watermarks of the number of requests
# TYPE apiserver_flowcontrol_read_vs_write_request_count_watermarks histogram
# HELP apiserver_init_events_total [ALPHA] Counter of init events processed in watchcache broken by resource type.
# TYPE apiserver_init_events_total counter
# HELP apiserver_longrunning_gauge [ALPHA] Gauge of all active long-running apiserver requests broken out by verb, group, version, resource, scope and component. Not all requests are tracked this way.
# TYPE apiserver_longrunning_gauge gauge
# HELP apiserver_registered_watchers [ALPHA] Number of currently registered watchers for a given resources
# TYPE apiserver_registered_watchers gauge
# HELP apiserver_request_duration_seconds [ALPHA] Response latency distribution in seconds for each verb, dry run value, group, version, resource, subresource, scope and component.
# TYPE apiserver_request_duration_seconds histogram
# HELP apiserver_request_terminations_total [ALPHA] Number of requests which apiserver terminated in self-defense.
# TYPE apiserver_request_terminations_total counter
# HELP apiserver_request_total [ALPHA] Counter of apiserver requests broken out for each verb, dry run value, group, version, resource, scope, component, and HTTP response contentType and code.
# TYPE apiserver_request_total counter
# HELP apiserver_requested_deprecated_apis [ALPHA] Gauge of deprecated APIs that have been requested, broken out by API group, version, resource, subresource, and removed_release.
# TYPE apiserver_requested_deprecated_apis gauge
# HELP apiserver_response_sizes [ALPHA] Response size distribution in bytes for each group, version, verb, resource, subresource, scope and component.
# TYPE apiserver_response_sizes histogram
# HELP apiserver_storage_data_key_generation_duration_seconds [ALPHA] Latencies in seconds of data encryption key(DEK) generation operations.
# TYPE apiserver_storage_data_key_generation_duration_seconds histogram
# HELP apiserver_storage_data_key_generation_failures_total [ALPHA] Total number of failed data encryption key(DEK) generation operations.
# TYPE apiserver_storage_data_key_generation_failures_total counter
# HELP apiserver_storage_envelope_transformation_cache_misses_total [ALPHA] Total number of cache misses while accessing key decryption key(KEK).
# TYPE apiserver_storage_envelope_transformation_cache_misses_total counter
# HELP apiserver_tls_handshake_errors_total [ALPHA] Number of requests dropped with 'TLS handshake error from' error
# TYPE apiserver_tls_handshake_errors_total counter
# HELP apiserver_watch_events_sizes [ALPHA] Watch event size distribution in bytes
# TYPE apiserver_watch_events_sizes histogram
# HELP apiserver_watch_events_total [ALPHA] Number of events sent in watch clients
# TYPE apiserver_watch_events_total counter
# HELP authenticated_user_requests [ALPHA] Counter of authenticated requests broken out by username.
# TYPE authenticated_user_requests counter
# HELP authentication_attempts [ALPHA] Counter of authenticated attempts.
# TYPE authentication_attempts counter
# HELP authentication_duration_seconds [ALPHA] Authentication duration in seconds broken out by result.
# TYPE authentication_duration_seconds histogram
# HELP authentication_token_cache_active_fetch_count [ALPHA]
# TYPE authentication_token_cache_active_fetch_count gauge
# HELP authentication_token_cache_fetch_total [ALPHA]
# TYPE authentication_token_cache_fetch_total counter
# HELP authentication_token_cache_request_duration_seconds [ALPHA]
# TYPE authentication_token_cache_request_duration_seconds histogram
# HELP authentication_token_cache_request_total [ALPHA]
# TYPE authentication_token_cache_request_total counter
# HELP etcd_db_total_size_in_bytes [ALPHA] Total size of the etcd database file physically allocated in bytes.
# TYPE etcd_db_total_size_in_bytes gauge
# HELP etcd_lease_object_counts [ALPHA] Number of objects attached to a single etcd lease.
# TYPE etcd_lease_object_counts histogram
# HELP etcd_object_counts [ALPHA] Number of stored objects at the time of last check split by kind.
# TYPE etcd_object_counts gauge
# HELP etcd_request_duration_seconds [ALPHA] Etcd request latency in seconds for each operation and object type.
# TYPE etcd_request_duration_seconds histogram
# HELP get_token_count [ALPHA] Counter of total Token() requests to the alternate token source
# TYPE get_token_count counter
# HELP get_token_fail_count [ALPHA] Counter of failed Token() requests to the alternate token source
# TYPE get_token_fail_count counter
# HELP grpc_client_handled_total Total number of RPCs completed by the client, regardless of success or failure.
# TYPE grpc_client_handled_total counter
# HELP grpc_client_msg_received_total Total number of RPC stream messages received by the client.
# TYPE grpc_client_msg_received_total counter
# HELP grpc_client_msg_sent_total Total number of gRPC stream messages sent by the client.
# TYPE grpc_client_msg_sent_total counter
# HELP grpc_client_started_total Total number of RPCs started on the client.
# TYPE grpc_client_started_total counter
# HELP kubernetes_build_info [ALPHA] A metric with a constant '1' value labeled by major, minor, git version, git commit, git tree state, build date, Go version, and compiler from which Kubernetes was built, and platform on which it is running.
# TYPE kubernetes_build_info gauge
# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
# TYPE process_cpu_seconds_total counter
# HELP process_max_fds Maximum number of open file descriptors.
# TYPE process_max_fds gauge
# HELP process_open_fds Number of open file descriptors.
# TYPE process_open_fds gauge
# HELP process_resident_memory_bytes Resident memory size in bytes.
# TYPE process_resident_memory_bytes gauge
# HELP process_start_time_seconds Start time of the process since unix epoch in seconds.
# TYPE process_start_time_seconds gauge
# HELP process_virtual_memory_bytes Virtual memory size in bytes.
# TYPE process_virtual_memory_bytes gauge
# HELP process_virtual_memory_max_bytes Maximum amount of virtual memory available in bytes.
# TYPE process_virtual_memory_max_bytes gauge
# HELP rest_client_exec_plugin_certificate_rotation_age [ALPHA] Histogram of the number of seconds the last auth exec plugin client certificate lived before being rotated. If auth exec plugin client certificates are unused, histogram will contain no data.
# TYPE rest_client_exec_plugin_certificate_rotation_age histogram
# HELP rest_client_exec_plugin_ttl_seconds [ALPHA] Gauge of the shortest TTL (time-to-live) of the client certificate(s) managed by the auth exec plugin. The value is in seconds until certificate expiry (negative if already expired). If auth exec plugins are unused or manage no TLS certificates, the value will be +INF.
# TYPE rest_client_exec_plugin_ttl_seconds gauge
# HELP rest_client_request_duration_seconds [ALPHA] Request latency in seconds. Broken down by verb and URL.
# TYPE rest_client_request_duration_seconds histogram
# HELP rest_client_requests_total [ALPHA] Number of HTTP requests, partitioned by status code, method, and host.
# TYPE rest_client_requests_total counter
# HELP serviceaccount_legacy_tokens_total [ALPHA] Cumulative legacy service account tokens used
# TYPE serviceaccount_legacy_tokens_total counter
# HELP serviceaccount_stale_tokens_total [ALPHA] Cumulative stale projected service account tokens used
# TYPE serviceaccount_stale_tokens_total counter
# HELP serviceaccount_valid_tokens_total [ALPHA] Cumulative valid projected service account tokens used
# TYPE serviceaccount_valid_tokens_total counter
# HELP ssh_tunnel_open_count [ALPHA] Counter of ssh tunnel total open attempts
# TYPE ssh_tunnel_open_count counter
# HELP ssh_tunnel_open_fail_count [ALPHA] Counter of ssh tunnel failed open attempts
# TYPE ssh_tunnel_open_fail_count counter
# HELP watch_cache_capacity_decrease_total [ALPHA] Total number of watch cache capacity decrease events broken by resource type.
# TYPE watch_cache_capacity_decrease_total counter
# HELP watch_cache_capacity_increase_total [ALPHA] Total number of watch cache capacity increase events broken by resource type.
# TYPE watch_cache_capacity_increase_total counter
# HELP workqueue_adds_total [ALPHA] Total number of adds handled by workqueue
# TYPE workqueue_adds_total counter
# HELP workqueue_depth [ALPHA] Current depth of workqueue
# TYPE workqueue_depth gauge
# HELP workqueue_longest_running_processor_seconds [ALPHA] How many seconds has the longest running processor for workqueue been running.
# TYPE workqueue_longest_running_processor_seconds gauge
# HELP workqueue_queue_duration_seconds [ALPHA] How long in seconds an item stays in workqueue before being requested.
# TYPE workqueue_queue_duration_seconds histogram
# HELP workqueue_retries_total [ALPHA] Total number of retries handled by workqueue
# TYPE workqueue_retries_total counter
# HELP workqueue_unfinished_work_seconds [ALPHA] How many seconds of work has done that is in progress and hasn't been observed by work_duration. Large values indicate stuck threads. One can deduce the number of stuck threads by observing the rate at which this increases.
# TYPE workqueue_unfinished_work_seconds gauge
# HELP workqueue_work_duration_seconds [ALPHA] How long in seconds processing an item from workqueue takes.
# TYPE workqueue_work_duration_seconds histogram
```

#### _kubelet_

kubelet exposes metrics on `/metrics`, and also `/metrics/{cadvisor,probes,resource}`.
It can be reached by proxying through the api server
`/api/v1/nodes/$node/proxy/metrics`:

(excludes `process_` and `go_`)

```
# HELP apiserver_audit_event_total [ALPHA] Counter of audit events generated and sent to the audit backend.
# TYPE apiserver_audit_event_total counter
# HELP apiserver_audit_requests_rejected_total [ALPHA] Counter of apiserver requests rejected due to an error in audit logging backend.
# TYPE apiserver_audit_requests_rejected_total counter
# HELP apiserver_client_certificate_expiration_seconds [ALPHA] Distribution of the remaining lifetime on the certificate used to authenticate a request.
# TYPE apiserver_client_certificate_expiration_seconds histogram
# HELP apiserver_storage_data_key_generation_duration_seconds [ALPHA] Latencies in seconds of data encryption key(DEK) generation operations.
# TYPE apiserver_storage_data_key_generation_duration_seconds histogram
# HELP apiserver_storage_data_key_generation_failures_total [ALPHA] Total number of failed data encryption key(DEK) generation operations.
# TYPE apiserver_storage_data_key_generation_failures_total counter
# HELP apiserver_storage_envelope_transformation_cache_misses_total [ALPHA] Total number of cache misses while accessing key decryption key(KEK).
# TYPE apiserver_storage_envelope_transformation_cache_misses_total counter
# HELP get_token_count [ALPHA] Counter of total Token() requests to the alternate token source
# TYPE get_token_count counter
# HELP get_token_fail_count [ALPHA] Counter of failed Token() requests to the alternate token source
# TYPE get_token_fail_count counter
# HELP kubelet_certificate_manager_server_rotation_seconds [ALPHA] Histogram of the number of seconds the previous certificate lived before being rotated.
# TYPE kubelet_certificate_manager_server_rotation_seconds histogram
# HELP kubelet_certificate_manager_server_ttl_seconds [ALPHA] Gauge of the shortest TTL (time-to-live) of the Kubelet's serving certificate. The value is in seconds until certificate expiry (negative if already expired). If serving certificate is invalid or unused, the value will be +INF.
# TYPE kubelet_certificate_manager_server_ttl_seconds gauge
# HELP kubelet_cgroup_manager_duration_seconds [ALPHA] Duration in seconds for cgroup manager operations. Broken down by method.
# TYPE kubelet_cgroup_manager_duration_seconds histogram
# HELP kubelet_container_log_filesystem_used_bytes [ALPHA] Bytes used by the container's logs on the filesystem.
# TYPE kubelet_container_log_filesystem_used_bytes gauge
# HELP kubelet_containers_per_pod_count [ALPHA] The number of containers per pod.
# TYPE kubelet_containers_per_pod_count histogram
# HELP kubelet_http_inflight_requests [ALPHA] Number of the inflight http requests
# TYPE kubelet_http_inflight_requests gauge
# HELP kubelet_http_requests_duration_seconds [ALPHA] Duration in seconds to serve http requests
# TYPE kubelet_http_requests_duration_seconds histogram
# HELP kubelet_http_requests_total [ALPHA] Number of the http requests received since the server started
# TYPE kubelet_http_requests_total counter
# HELP kubelet_node_name [ALPHA] The node's name. The count is always 1.
# TYPE kubelet_node_name gauge
# HELP kubelet_pleg_discard_events [ALPHA] The number of discard events in PLEG.
# TYPE kubelet_pleg_discard_events counter
# HELP kubelet_pleg_last_seen_seconds [ALPHA] Timestamp in seconds when PLEG was last seen active.
# TYPE kubelet_pleg_last_seen_seconds gauge
# HELP kubelet_pleg_relist_duration_seconds [ALPHA] Duration in seconds for relisting pods in PLEG.
# TYPE kubelet_pleg_relist_duration_seconds histogram
# HELP kubelet_pleg_relist_interval_seconds [ALPHA] Interval in seconds between relisting in PLEG.
# TYPE kubelet_pleg_relist_interval_seconds histogram
# HELP kubelet_pod_start_duration_seconds [ALPHA] Duration in seconds for a single pod to go from pending to running.
# TYPE kubelet_pod_start_duration_seconds histogram
# HELP kubelet_pod_worker_duration_seconds [ALPHA] Duration in seconds to sync a single pod. Broken down by operation type: create, update, or sync
# TYPE kubelet_pod_worker_duration_seconds histogram
# HELP kubelet_pod_worker_start_duration_seconds [ALPHA] Duration in seconds from seeing a pod to starting a worker.
# TYPE kubelet_pod_worker_start_duration_seconds histogram
# HELP kubelet_run_podsandbox_duration_seconds [ALPHA] Duration in seconds of the run_podsandbox operations. Broken down by RuntimeClass.Handler.
# TYPE kubelet_run_podsandbox_duration_seconds histogram
# HELP kubelet_running_containers [ALPHA] Number of containers currently running
# TYPE kubelet_running_containers gauge
# HELP kubelet_running_pods [ALPHA] Number of pods currently running
# TYPE kubelet_running_pods gauge
# HELP kubelet_runtime_operations_duration_seconds [ALPHA] Duration in seconds of runtime operations. Broken down by operation type.
# TYPE kubelet_runtime_operations_duration_seconds histogram
# HELP kubelet_runtime_operations_total [ALPHA] Cumulative number of runtime operations by operation type.
# TYPE kubelet_runtime_operations_total counter
# HELP kubelet_server_expiration_renew_errors [ALPHA] Counter of certificate renewal errors.
# TYPE kubelet_server_expiration_renew_errors counter
# HELP kubelet_volume_stats_available_bytes [ALPHA] Number of available bytes in the volume
# TYPE kubelet_volume_stats_available_bytes gauge
# HELP kubelet_volume_stats_capacity_bytes [ALPHA] Capacity in bytes of the volume
# TYPE kubelet_volume_stats_capacity_bytes gauge
# HELP kubelet_volume_stats_inodes [ALPHA] Maximum number of inodes in the volume
# TYPE kubelet_volume_stats_inodes gauge
# HELP kubelet_volume_stats_inodes_free [ALPHA] Number of free inodes in the volume
# TYPE kubelet_volume_stats_inodes_free gauge
# HELP kubelet_volume_stats_inodes_used [ALPHA] Number of used inodes in the volume
# TYPE kubelet_volume_stats_inodes_used gauge
# HELP kubelet_volume_stats_used_bytes [ALPHA] Number of used bytes in the volume
# TYPE kubelet_volume_stats_used_bytes gauge
# HELP kubernetes_build_info [ALPHA] A metric with a constant '1' value labeled by major, minor, git version, git commit, git tree state, build date, Go version, and compiler from which Kubernetes was built, and platform on which it is running.
# TYPE kubernetes_build_info gauge
# HELP rest_client_exec_plugin_certificate_rotation_age [ALPHA] Histogram of the number of seconds the last auth exec plugin client certificate lived before being rotated. If auth exec plugin client certificates are unused, histogram will contain no data.
# TYPE rest_client_exec_plugin_certificate_rotation_age histogram
# HELP rest_client_exec_plugin_ttl_seconds [ALPHA] Gauge of the shortest TTL (time-to-live) of the client certificate(s) managed by the auth exec plugin. The value is in seconds until certificate expiry (negative if already expired). If auth exec plugins are unused or manage no TLS certificates, the value will be +INF.
# TYPE rest_client_exec_plugin_ttl_seconds gauge
# HELP rest_client_request_duration_seconds [ALPHA] Request latency in seconds. Broken down by verb and URL.
# TYPE rest_client_request_duration_seconds histogram
# HELP rest_client_requests_total [ALPHA] Number of HTTP requests, partitioned by status code, method, and host.
# TYPE rest_client_requests_total counter
# HELP storage_operation_duration_seconds [ALPHA] Storage operation duration
# TYPE storage_operation_duration_seconds histogram
# HELP storage_operation_errors_total [ALPHA] Storage operation errors
# TYPE storage_operation_errors_total counter
# HELP storage_operation_status_count [ALPHA] Storage operation return statuses count
# TYPE storage_operation_status_count counter
# HELP volume_manager_total_volumes [ALPHA] Number of volumes in Volume Manager
# TYPE volume_manager_total_volumes gauge
```

##### _kubelet_ cadvisor

An integrated version of [cadvisor](https://github.com/google/cadvisor) into kubelet

```
# HELP cadvisor_version_info A metric with a constant '1' value labeled by kernel version, OS version, docker version, cadvisor version & cadvisor revision.
# TYPE cadvisor_version_info gauge
# HELP container_cpu_cfs_periods_total Number of elapsed enforcement period intervals.
# TYPE container_cpu_cfs_periods_total counter
# HELP container_cpu_cfs_throttled_periods_total Number of throttled period intervals.
# TYPE container_cpu_cfs_throttled_periods_total counter
# HELP container_cpu_cfs_throttled_seconds_total Total time duration the container has been throttled.
# TYPE container_cpu_cfs_throttled_seconds_total counter
# HELP container_cpu_load_average_10s Value of container cpu load average over the last 10 seconds.
# TYPE container_cpu_load_average_10s gauge
# HELP container_cpu_system_seconds_total Cumulative system cpu time consumed in seconds.
# TYPE container_cpu_system_seconds_total counter
# HELP container_cpu_usage_seconds_total Cumulative cpu time consumed in seconds.
# TYPE container_cpu_usage_seconds_total counter
# HELP container_cpu_user_seconds_total Cumulative user cpu time consumed in seconds.
# TYPE container_cpu_user_seconds_total counter
# HELP container_file_descriptors Number of open file descriptors for the container.
# TYPE container_file_descriptors gauge
# HELP container_fs_inodes_free Number of available Inodes
# TYPE container_fs_inodes_free gauge
# HELP container_fs_inodes_total Number of Inodes
# TYPE container_fs_inodes_total gauge
# HELP container_fs_io_current Number of I/Os currently in progress
# TYPE container_fs_io_current gauge
# HELP container_fs_io_time_seconds_total Cumulative count of seconds spent doing I/Os
# TYPE container_fs_io_time_seconds_total counter
# HELP container_fs_io_time_weighted_seconds_total Cumulative weighted I/O time in seconds
# TYPE container_fs_io_time_weighted_seconds_total counter
# HELP container_fs_limit_bytes Number of bytes that can be consumed by the container on this filesystem.
# TYPE container_fs_limit_bytes gauge
# HELP container_fs_read_seconds_total Cumulative count of seconds spent reading
# TYPE container_fs_read_seconds_total counter
# HELP container_fs_reads_bytes_total Cumulative count of bytes read
# TYPE container_fs_reads_bytes_total counter
# HELP container_fs_reads_merged_total Cumulative count of reads merged
# TYPE container_fs_reads_merged_total counter
# HELP container_fs_reads_total Cumulative count of reads completed
# TYPE container_fs_reads_total counter
# HELP container_fs_sector_reads_total Cumulative count of sector reads completed
# TYPE container_fs_sector_reads_total counter
# HELP container_fs_sector_writes_total Cumulative count of sector writes completed
# TYPE container_fs_sector_writes_total counter
# HELP container_fs_usage_bytes Number of bytes that are consumed by the container on this filesystem.
# TYPE container_fs_usage_bytes gauge
# HELP container_fs_write_seconds_total Cumulative count of seconds spent writing
# TYPE container_fs_write_seconds_total counter
# HELP container_fs_writes_bytes_total Cumulative count of bytes written
# TYPE container_fs_writes_bytes_total counter
# HELP container_fs_writes_merged_total Cumulative count of writes merged
# TYPE container_fs_writes_merged_total counter
# HELP container_fs_writes_total Cumulative count of writes completed
# TYPE container_fs_writes_total counter
# HELP container_last_seen Last time a container was seen by the exporter
# TYPE container_last_seen gauge
# HELP container_memory_cache Number of bytes of page cache memory.
# TYPE container_memory_cache gauge
# HELP container_memory_failcnt Number of memory usage hits limits
# TYPE container_memory_failcnt counter
# HELP container_memory_failures_total Cumulative count of memory allocation failures.
# TYPE container_memory_failures_total counter
# HELP container_memory_mapped_file Size of memory mapped files in bytes.
# TYPE container_memory_mapped_file gauge
# HELP container_memory_max_usage_bytes Maximum memory usage recorded in bytes
# TYPE container_memory_max_usage_bytes gauge
# HELP container_memory_rss Size of RSS in bytes.
# TYPE container_memory_rss gauge
# HELP container_memory_swap Container swap usage in bytes.
# TYPE container_memory_swap gauge
# HELP container_memory_usage_bytes Current memory usage in bytes, including all memory regardless of when it was accessed
# TYPE container_memory_usage_bytes gauge
# HELP container_memory_working_set_bytes Current working set in bytes.
# TYPE container_memory_working_set_bytes gauge
# HELP container_network_receive_bytes_total Cumulative count of bytes received
# TYPE container_network_receive_bytes_total counter
# HELP container_network_receive_errors_total Cumulative count of errors encountered while receiving
# TYPE container_network_receive_errors_total counter
# HELP container_network_receive_packets_dropped_total Cumulative count of packets dropped while receiving
# TYPE container_network_receive_packets_dropped_total counter
# HELP container_network_receive_packets_total Cumulative count of packets received
# TYPE container_network_receive_packets_total counter
# HELP container_network_transmit_bytes_total Cumulative count of bytes transmitted
# TYPE container_network_transmit_bytes_total counter
# HELP container_network_transmit_errors_total Cumulative count of errors encountered while transmitting
# TYPE container_network_transmit_errors_total counter
# HELP container_network_transmit_packets_dropped_total Cumulative count of packets dropped while transmitting
# TYPE container_network_transmit_packets_dropped_total counter
# HELP container_network_transmit_packets_total Cumulative count of packets transmitted
# TYPE container_network_transmit_packets_total counter
# HELP container_processes Number of processes running inside the container.
# TYPE container_processes gauge
# HELP container_scrape_error 1 if there was an error while getting container metrics, 0 otherwise
# TYPE container_scrape_error gauge
# HELP container_sockets Number of open sockets for the container.
# TYPE container_sockets gauge
# HELP container_spec_cpu_period CPU period of the container.
# TYPE container_spec_cpu_period gauge
# HELP container_spec_cpu_quota CPU quota of the container.
# TYPE container_spec_cpu_quota gauge
# HELP container_spec_cpu_shares CPU share of the container.
# TYPE container_spec_cpu_shares gauge
# HELP container_spec_memory_limit_bytes Memory limit for the container.
# TYPE container_spec_memory_limit_bytes gauge
# HELP container_spec_memory_reservation_limit_bytes Memory reservation limit for the container.
# TYPE container_spec_memory_reservation_limit_bytes gauge
# HELP container_spec_memory_swap_limit_bytes Memory swap limit for the container.
# TYPE container_spec_memory_swap_limit_bytes gauge
# HELP container_start_time_seconds Start time of the container since unix epoch in seconds.
# TYPE container_start_time_seconds gauge
# HELP container_tasks_state Number of tasks in given state
# TYPE container_tasks_state gauge
# HELP container_threads Number of threads running inside the container
# TYPE container_threads gauge
# HELP container_threads_max Maximum number of threads allowed inside the container, infinity if value is zero
# TYPE container_threads_max gauge
# HELP container_ulimits_soft Soft ulimit values for the container root process. Unlimited if -1, except priority and nice
# TYPE container_ulimits_soft gauge
# HELP machine_cpu_cores Number of logical CPU cores.
# TYPE machine_cpu_cores gauge
# HELP machine_cpu_physical_cores Number of physical CPU cores.
# TYPE machine_cpu_physical_cores gauge
# HELP machine_cpu_sockets Number of CPU sockets.
# TYPE machine_cpu_sockets gauge
# HELP machine_memory_bytes Amount of memory installed on the machine.
# TYPE machine_memory_bytes gauge
# HELP machine_nvm_avg_power_budget_watts NVM power budget.
# TYPE machine_nvm_avg_power_budget_watts gauge
# HELP machine_nvm_capacity NVM capacity value labeled by NVM mode (memory mode or app direct mode).
# TYPE machine_nvm_capacity gauge
# HELP machine_scrape_error 1 if there was an error while getting machine metrics, 0 otherwise.
# TYPE machine_scrape_error gauge
```

##### _kubelet_ probes

```
# HELP prober_probe_total [ALPHA] Cumulative number of a liveness, readiness or startup probe for a container by result.
# TYPE prober_probe_total counter
# HELP process_start_time_seconds [ALPHA] Start time of the process since unix epoch in seconds.
# TYPE process_start_time_seconds gauge
```

##### _kubelet_ resource

```
# HELP container_cpu_usage_seconds_total [ALPHA] Cumulative cpu time consumed by the container in core-seconds
# TYPE container_cpu_usage_seconds_total counter
# HELP container_memory_working_set_bytes [ALPHA] Current working set of the container in bytes
# TYPE container_memory_working_set_bytes gauge
# HELP node_cpu_usage_seconds_total [ALPHA] Cumulative cpu time consumed by the node in core-seconds
# TYPE node_cpu_usage_seconds_total counter
# HELP node_memory_working_set_bytes [ALPHA] Current working set of the node in bytes
# TYPE node_memory_working_set_bytes gauge
# HELP scrape_error [ALPHA] 1 if there was an error while getting container metrics, 0 otherwise
# TYPE scrape_error gauge
```

#### _kube-state-metrics_

There's also [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)
which you can run to generate metrics about the various k8s resources:

```
# HELP kube_certificatesigningrequest_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_certificatesigningrequest_labels gauge
# HELP kube_certificatesigningrequest_created Unix creation timestamp
# TYPE kube_certificatesigningrequest_created gauge
# HELP kube_certificatesigningrequest_condition The number of each certificatesigningrequest condition
# TYPE kube_certificatesigningrequest_condition gauge
# HELP kube_certificatesigningrequest_cert_length Length of the issued cert
# TYPE kube_certificatesigningrequest_cert_length gauge
# HELP kube_configmap_info Information about configmap.
# TYPE kube_configmap_info gauge
# HELP kube_configmap_created Unix creation timestamp
# TYPE kube_configmap_created gauge
# HELP kube_configmap_metadata_resource_version Resource version representing a specific version of the configmap.
# TYPE kube_configmap_metadata_resource_version gauge
# HELP kube_cronjob_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_cronjob_labels gauge
# HELP kube_cronjob_info Info about cronjob.
# TYPE kube_cronjob_info gauge
# HELP kube_cronjob_created Unix creation timestamp
# TYPE kube_cronjob_created gauge
# HELP kube_cronjob_status_active Active holds pointers to currently running jobs.
# TYPE kube_cronjob_status_active gauge
# HELP kube_cronjob_status_last_schedule_time LastScheduleTime keeps information of when was the last time the job was successfully scheduled.
# TYPE kube_cronjob_status_last_schedule_time gauge
# HELP kube_cronjob_spec_suspend Suspend flag tells the controller to suspend subsequent executions.
# TYPE kube_cronjob_spec_suspend gauge
# HELP kube_cronjob_spec_starting_deadline_seconds Deadline in seconds for starting the job if it misses scheduled time for any reason.
# TYPE kube_cronjob_spec_starting_deadline_seconds gauge
# HELP kube_cronjob_next_schedule_time Next time the cronjob should be scheduled. The time after lastScheduleTime, or after the cron job's creation time if it's never been scheduled. Use this to determine if the job is delayed.
# TYPE kube_cronjob_next_schedule_time gauge
# HELP kube_daemonset_created Unix creation timestamp
# TYPE kube_daemonset_created gauge
# HELP kube_daemonset_status_current_number_scheduled The number of nodes running at least one daemon pod and are supposed to.
# TYPE kube_daemonset_status_current_number_scheduled gauge
# HELP kube_daemonset_status_desired_number_scheduled The number of nodes that should be running the daemon pod.
# TYPE kube_daemonset_status_desired_number_scheduled gauge
# HELP kube_daemonset_status_number_available The number of nodes that should be running the daemon pod and have one or more of the daemon pod running and available
# TYPE kube_daemonset_status_number_available gauge
# HELP kube_daemonset_status_number_misscheduled The number of nodes running a daemon pod but are not supposed to.
# TYPE kube_daemonset_status_number_misscheduled gauge
# HELP kube_daemonset_status_number_ready The number of nodes that should be running the daemon pod and have one or more of the daemon pod running and ready.
# TYPE kube_daemonset_status_number_ready gauge
# HELP kube_daemonset_status_number_unavailable The number of nodes that should be running the daemon pod and have none of the daemon pod running and available
# TYPE kube_daemonset_status_number_unavailable gauge
# HELP kube_daemonset_status_observed_generation The most recent generation observed by the daemon set controller.
# TYPE kube_daemonset_status_observed_generation gauge
# HELP kube_daemonset_status_updated_number_scheduled The total number of nodes that are running updated daemon pod
# TYPE kube_daemonset_status_updated_number_scheduled gauge
# HELP kube_daemonset_metadata_generation Sequence number representing a specific generation of the desired state.
# TYPE kube_daemonset_metadata_generation gauge
# HELP kube_daemonset_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_daemonset_labels gauge
# HELP kube_deployment_created Unix creation timestamp
# TYPE kube_deployment_created gauge
# HELP kube_deployment_status_replicas The number of replicas per deployment.
# TYPE kube_deployment_status_replicas gauge
# HELP kube_deployment_status_replicas_available The number of available replicas per deployment.
# TYPE kube_deployment_status_replicas_available gauge
# HELP kube_deployment_status_replicas_unavailable The number of unavailable replicas per deployment.
# TYPE kube_deployment_status_replicas_unavailable gauge
# HELP kube_deployment_status_replicas_updated The number of updated replicas per deployment.
# TYPE kube_deployment_status_replicas_updated gauge
# HELP kube_deployment_status_observed_generation The generation observed by the deployment controller.
# TYPE kube_deployment_status_observed_generation gauge
# HELP kube_deployment_status_condition The current status conditions of a deployment.
# TYPE kube_deployment_status_condition gauge
# HELP kube_deployment_spec_replicas Number of desired pods for a deployment.
# TYPE kube_deployment_spec_replicas gauge
# HELP kube_deployment_spec_paused Whether the deployment is paused and will not be processed by the deployment controller.
# TYPE kube_deployment_spec_paused gauge
# HELP kube_deployment_spec_strategy_rollingupdate_max_unavailable Maximum number of unavailable replicas during a rolling update of a deployment.
# TYPE kube_deployment_spec_strategy_rollingupdate_max_unavailable gauge
# HELP kube_deployment_spec_strategy_rollingupdate_max_surge Maximum number of replicas that can be scheduled above the desired number of replicas during a rolling update of a deployment.
# TYPE kube_deployment_spec_strategy_rollingupdate_max_surge gauge
# HELP kube_deployment_metadata_generation Sequence number representing a specific generation of the desired state.
# TYPE kube_deployment_metadata_generation gauge
# HELP kube_deployment_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_deployment_labels gauge
# HELP kube_endpoint_info Information about endpoint.
# TYPE kube_endpoint_info gauge
# HELP kube_endpoint_created Unix creation timestamp
# TYPE kube_endpoint_created gauge
# HELP kube_endpoint_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_endpoint_labels gauge
# HELP kube_endpoint_address_available Number of addresses available in endpoint.
# TYPE kube_endpoint_address_available gauge
# HELP kube_endpoint_address_not_ready Number of addresses not ready in endpoint
# TYPE kube_endpoint_address_not_ready gauge
# HELP kube_horizontalpodautoscaler_metadata_generation The generation observed by the HorizontalPodAutoscaler controller.
# TYPE kube_horizontalpodautoscaler_metadata_generation gauge
# HELP kube_horizontalpodautoscaler_spec_max_replicas Upper limit for the number of pods that can be set by the autoscaler; cannot be smaller than MinReplicas.
# TYPE kube_horizontalpodautoscaler_spec_max_replicas gauge
# HELP kube_horizontalpodautoscaler_spec_min_replicas Lower limit for the number of pods that can be set by the autoscaler, default 1.
# TYPE kube_horizontalpodautoscaler_spec_min_replicas gauge
# HELP kube_horizontalpodautoscaler_spec_target_metric The metric specifications used by this autoscaler when calculating the desired replica count.
# TYPE kube_horizontalpodautoscaler_spec_target_metric gauge
# HELP kube_horizontalpodautoscaler_status_current_replicas Current number of replicas of pods managed by this autoscaler.
# TYPE kube_horizontalpodautoscaler_status_current_replicas gauge
# HELP kube_horizontalpodautoscaler_status_desired_replicas Desired number of replicas of pods managed by this autoscaler.
# TYPE kube_horizontalpodautoscaler_status_desired_replicas gauge
# HELP kube_horizontalpodautoscaler_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_horizontalpodautoscaler_labels gauge
# HELP kube_horizontalpodautoscaler_status_condition The condition of this autoscaler.
# TYPE kube_horizontalpodautoscaler_status_condition gauge
# HELP kube_ingress_info Information about ingress.
# TYPE kube_ingress_info gauge
# HELP kube_ingress_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_ingress_labels gauge
# HELP kube_ingress_created Unix creation timestamp
# TYPE kube_ingress_created gauge
# HELP kube_ingress_metadata_resource_version Resource version representing a specific version of ingress.
# TYPE kube_ingress_metadata_resource_version gauge
# HELP kube_ingress_path Ingress host, paths and backend service information.
# TYPE kube_ingress_path gauge
# HELP kube_ingress_tls Ingress TLS host and secret information.
# TYPE kube_ingress_tls gauge
# HELP kube_job_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_job_labels gauge
# HELP kube_job_info Information about job.
# TYPE kube_job_info gauge
# HELP kube_job_created Unix creation timestamp
# TYPE kube_job_created gauge
# HELP kube_job_spec_parallelism The maximum desired number of pods the job should run at any given time.
# TYPE kube_job_spec_parallelism gauge
# HELP kube_job_spec_completions The desired number of successfully finished pods the job should be run with.
# TYPE kube_job_spec_completions gauge
# HELP kube_job_spec_active_deadline_seconds The duration in seconds relative to the startTime that the job may be active before the system tries to terminate it.
# TYPE kube_job_spec_active_deadline_seconds gauge
# HELP kube_job_status_succeeded The number of pods which reached Phase Succeeded.
# TYPE kube_job_status_succeeded gauge
# HELP kube_job_status_failed The number of pods which reached Phase Failed and the reason for failure.
# TYPE kube_job_status_failed gauge
# HELP kube_job_status_active The number of actively running pods.
# TYPE kube_job_status_active gauge
# HELP kube_job_complete The job has completed its execution.
# TYPE kube_job_complete gauge
# HELP kube_job_failed The job has failed its execution.
# TYPE kube_job_failed gauge
# HELP kube_job_status_start_time StartTime represents time when the job was acknowledged by the Job Manager.
# TYPE kube_job_status_start_time gauge
# HELP kube_job_status_completion_time CompletionTime represents time when the job was completed.
# TYPE kube_job_status_completion_time gauge
# HELP kube_job_owner Information about the Job's owner.
# TYPE kube_job_owner gauge
# HELP kube_limitrange Information about limit range.
# TYPE kube_limitrange gauge
# HELP kube_limitrange_created Unix creation timestamp
# TYPE kube_limitrange_created gauge
# HELP kube_mutatingwebhookconfiguration_info Information about the MutatingWebhookConfiguration.
# TYPE kube_mutatingwebhookconfiguration_info gauge
# HELP kube_mutatingwebhookconfiguration_created Unix creation timestamp.
# TYPE kube_mutatingwebhookconfiguration_created gauge
# HELP kube_mutatingwebhookconfiguration_metadata_resource_version Resource version representing a specific version of the MutatingWebhookConfiguration.
# TYPE kube_mutatingwebhookconfiguration_metadata_resource_version gauge
# HELP kube_namespace_created Unix creation timestamp
# TYPE kube_namespace_created gauge
# HELP kube_namespace_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_namespace_labels gauge
# HELP kube_namespace_status_phase kubernetes namespace status phase.
# TYPE kube_namespace_status_phase gauge
# HELP kube_namespace_status_condition The condition of a namespace.
# TYPE kube_namespace_status_condition gauge
# HELP kube_networkpolicy_created Unix creation timestamp of network policy
# TYPE kube_networkpolicy_created gauge
# HELP kube_networkpolicy_labels Kubernetes labels converted to Prometheus labels
# TYPE kube_networkpolicy_labels gauge
# HELP kube_networkpolicy_spec_ingress_rules Number of ingress rules on the networkpolicy
# TYPE kube_networkpolicy_spec_ingress_rules gauge
# HELP kube_networkpolicy_spec_egress_rules Number of egress rules on the networkpolicy
# TYPE kube_networkpolicy_spec_egress_rules gauge
# HELP kube_node_info Information about a cluster node.
# TYPE kube_node_info gauge
# HELP kube_node_created Unix creation timestamp
# TYPE kube_node_created gauge
# HELP kube_node_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_node_labels gauge
# HELP kube_node_role The role of a cluster node.
# TYPE kube_node_role gauge
# HELP kube_node_spec_unschedulable Whether a node can schedule new pods.
# TYPE kube_node_spec_unschedulable gauge
# HELP kube_node_spec_taint The taint of a cluster node.
# TYPE kube_node_spec_taint gauge
# HELP kube_node_status_condition The condition of a cluster node.
# TYPE kube_node_status_condition gauge
# HELP kube_node_status_capacity The capacity for different resources of a node.
# TYPE kube_node_status_capacity gauge
# HELP kube_node_status_allocatable The allocatable for different resources of a node that are available for scheduling.
# TYPE kube_node_status_allocatable gauge
# HELP kube_persistentvolumeclaim_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_persistentvolumeclaim_labels gauge
# HELP kube_persistentvolumeclaim_info Information about persistent volume claim.
# TYPE kube_persistentvolumeclaim_info gauge
# HELP kube_persistentvolumeclaim_status_phase The phase the persistent volume claim is currently in.
# TYPE kube_persistentvolumeclaim_status_phase gauge
# HELP kube_persistentvolumeclaim_resource_requests_storage_bytes The capacity of storage requested by the persistent volume claim.
# TYPE kube_persistentvolumeclaim_resource_requests_storage_bytes gauge
# HELP kube_persistentvolumeclaim_access_mode The access mode(s) specified by the persistent volume claim.
# TYPE kube_persistentvolumeclaim_access_mode gauge
# HELP kube_persistentvolumeclaim_status_condition Information about status of different conditions of persistent volume claim.
# TYPE kube_persistentvolumeclaim_status_condition gauge
# HELP kube_persistentvolume_claim_ref Information about the Persitant Volume Claim Reference.
# TYPE kube_persistentvolume_claim_ref gauge
# HELP kube_persistentvolume_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_persistentvolume_labels gauge
# HELP kube_persistentvolume_status_phase The phase indicates if a volume is available, bound to a claim, or released by a claim.
# TYPE kube_persistentvolume_status_phase gauge
# HELP kube_persistentvolume_info Information about persistentvolume.
# TYPE kube_persistentvolume_info gauge
# HELP kube_persistentvolume_capacity_bytes Persistentvolume capacity in bytes.
# TYPE kube_persistentvolume_capacity_bytes gauge
# HELP kube_poddisruptionbudget_created Unix creation timestamp
# TYPE kube_poddisruptionbudget_created gauge
# HELP kube_poddisruptionbudget_status_current_healthy Current number of healthy pods
# TYPE kube_poddisruptionbudget_status_current_healthy gauge
# HELP kube_poddisruptionbudget_status_desired_healthy Minimum desired number of healthy pods
# TYPE kube_poddisruptionbudget_status_desired_healthy gauge
# HELP kube_poddisruptionbudget_status_pod_disruptions_allowed Number of pod disruptions that are currently allowed
# TYPE kube_poddisruptionbudget_status_pod_disruptions_allowed gauge
# HELP kube_poddisruptionbudget_status_expected_pods Total number of pods counted by this disruption budget
# TYPE kube_poddisruptionbudget_status_expected_pods gauge
# HELP kube_poddisruptionbudget_status_observed_generation Most recent generation observed when updating this PDB status
# TYPE kube_poddisruptionbudget_status_observed_generation gauge
# HELP kube_pod_info Information about pod.
# TYPE kube_pod_info gauge
# HELP kube_pod_start_time Start time in unix timestamp for a pod.
# TYPE kube_pod_start_time gauge
# HELP kube_pod_container_state_started Start time in unix timestamp for a pod container.
# TYPE kube_pod_container_state_started gauge
# HELP kube_pod_completion_time Completion time in unix timestamp for a pod.
# TYPE kube_pod_completion_time gauge
# HELP kube_pod_owner Information about the Pod's owner.
# TYPE kube_pod_owner gauge
# HELP kube_pod_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_pod_labels gauge
# HELP kube_pod_created Unix creation timestamp
# TYPE kube_pod_created gauge
# HELP kube_pod_deletion_timestamp Unix deletion timestamp
# TYPE kube_pod_deletion_timestamp gauge
# HELP kube_pod_restart_policy Describes the restart policy in use by this pod.
# TYPE kube_pod_restart_policy gauge
# HELP kube_pod_status_scheduled_time Unix timestamp when pod moved into scheduled status
# TYPE kube_pod_status_scheduled_time gauge
# HELP kube_pod_status_unschedulable Describes the unschedulable status for the pod.
# TYPE kube_pod_status_unschedulable gauge
# HELP kube_pod_status_phase The pods current phase.
# TYPE kube_pod_status_phase gauge
# HELP kube_pod_status_ready Describes whether the pod is ready to serve requests.
# TYPE kube_pod_status_ready gauge
# HELP kube_pod_status_scheduled Describes the status of the scheduling process for the pod.
# TYPE kube_pod_status_scheduled gauge
# HELP kube_pod_status_reason The pod status reasons
# TYPE kube_pod_status_reason gauge
# HELP kube_pod_container_info Information about a container in a pod.
# TYPE kube_pod_container_info gauge
# HELP kube_pod_init_container_info Information about an init container in a pod.
# TYPE kube_pod_init_container_info gauge
# HELP kube_pod_container_status_waiting Describes whether the container is currently in waiting state.
# TYPE kube_pod_container_status_waiting gauge
# HELP kube_pod_init_container_status_waiting Describes whether the init container is currently in waiting state.
# TYPE kube_pod_init_container_status_waiting gauge
# HELP kube_pod_container_status_waiting_reason Describes the reason the container is currently in waiting state.
# TYPE kube_pod_container_status_waiting_reason gauge
# HELP kube_pod_init_container_status_waiting_reason Describes the reason the init container is currently in waiting state.
# TYPE kube_pod_init_container_status_waiting_reason gauge
# HELP kube_pod_container_status_running Describes whether the container is currently in running state.
# TYPE kube_pod_container_status_running gauge
# HELP kube_pod_init_container_status_running Describes whether the init container is currently in running state.
# TYPE kube_pod_init_container_status_running gauge
# HELP kube_pod_container_status_terminated Describes whether the container is currently in terminated state.
# TYPE kube_pod_container_status_terminated gauge
# HELP kube_pod_init_container_status_terminated Describes whether the init container is currently in terminated state.
# TYPE kube_pod_init_container_status_terminated gauge
# HELP kube_pod_container_status_terminated_reason Describes the reason the container is currently in terminated state.
# TYPE kube_pod_container_status_terminated_reason gauge
# HELP kube_pod_init_container_status_terminated_reason Describes the reason the init container is currently in terminated state.
# TYPE kube_pod_init_container_status_terminated_reason gauge
# HELP kube_pod_container_status_last_terminated_reason Describes the last reason the container was in terminated state.
# TYPE kube_pod_container_status_last_terminated_reason gauge
# HELP kube_pod_init_container_status_last_terminated_reason Describes the last reason the init container was in terminated state.
# TYPE kube_pod_init_container_status_last_terminated_reason gauge
# HELP kube_pod_container_status_ready Describes whether the containers readiness check succeeded.
# TYPE kube_pod_container_status_ready gauge
# HELP kube_pod_init_container_status_ready Describes whether the init containers readiness check succeeded.
# TYPE kube_pod_init_container_status_ready gauge
# HELP kube_pod_container_status_restarts_total The number of container restarts per container.
# TYPE kube_pod_container_status_restarts_total counter
# HELP kube_pod_init_container_status_restarts_total The number of restarts for the init container.
# TYPE kube_pod_init_container_status_restarts_total counter
# HELP kube_pod_container_resource_requests The number of requested request resource by a container.
# TYPE kube_pod_container_resource_requests gauge
# HELP kube_pod_container_resource_limits The number of requested limit resource by a container.
# TYPE kube_pod_container_resource_limits gauge
# HELP kube_pod_init_container_resource_requests_cpu_cores The number of CPU cores requested by an init container.
# TYPE kube_pod_init_container_resource_requests_cpu_cores gauge
# HELP kube_pod_init_container_resource_requests_memory_bytes Bytes of memory requested by an init container.
# TYPE kube_pod_init_container_resource_requests_memory_bytes gauge
# HELP kube_pod_init_container_resource_requests_storage_bytes Bytes of storage requested by an init container.
# TYPE kube_pod_init_container_resource_requests_storage_bytes gauge
# HELP kube_pod_init_container_resource_requests_ephemeral_storage_bytes Bytes of ephemeral-storage requested by an init container.
# TYPE kube_pod_init_container_resource_requests_ephemeral_storage_bytes gauge
# HELP kube_pod_init_container_resource_requests The number of requested request resource by an init container.
# TYPE kube_pod_init_container_resource_requests gauge
# HELP kube_pod_init_container_resource_limits_cpu_cores The number of CPU cores requested limit by an init container.
# TYPE kube_pod_init_container_resource_limits_cpu_cores gauge
# HELP kube_pod_init_container_resource_limits_memory_bytes Bytes of memory requested limit by an init container.
# TYPE kube_pod_init_container_resource_limits_memory_bytes gauge
# HELP kube_pod_init_container_resource_limits_storage_bytes Bytes of storage requested limit by an init container.
# TYPE kube_pod_init_container_resource_limits_storage_bytes gauge
# HELP kube_pod_init_container_resource_limits_ephemeral_storage_bytes Bytes of ephemeral-storage requested limit by an init container.
# TYPE kube_pod_init_container_resource_limits_ephemeral_storage_bytes gauge
# HELP kube_pod_init_container_resource_limits The number of requested limit resource by an init container.
# TYPE kube_pod_init_container_resource_limits gauge
# HELP kube_pod_spec_volumes_persistentvolumeclaims_info Information about persistentvolumeclaim volumes in a pod.
# TYPE kube_pod_spec_volumes_persistentvolumeclaims_info gauge
# HELP kube_pod_spec_volumes_persistentvolumeclaims_readonly Describes whether a persistentvolumeclaim is mounted read only.
# TYPE kube_pod_spec_volumes_persistentvolumeclaims_readonly gauge
# HELP kube_pod_overhead_cpu_cores The pod overhead in regards to cpu cores associated with running a pod.
# TYPE kube_pod_overhead_cpu_cores gauge
# HELP kube_pod_overhead_memory_bytes The pod overhead in regards to memory associated with running a pod.
# TYPE kube_pod_overhead_memory_bytes gauge
# HELP kube_pod_runtimeclass_name_info The runtimeclass associated with the pod.
# TYPE kube_pod_runtimeclass_name_info gauge
# HELP kube_replicaset_created Unix creation timestamp
# TYPE kube_replicaset_created gauge
# HELP kube_replicaset_status_replicas The number of replicas per ReplicaSet.
# TYPE kube_replicaset_status_replicas gauge
# HELP kube_replicaset_status_fully_labeled_replicas The number of fully labeled replicas per ReplicaSet.
# TYPE kube_replicaset_status_fully_labeled_replicas gauge
# HELP kube_replicaset_status_ready_replicas The number of ready replicas per ReplicaSet.
# TYPE kube_replicaset_status_ready_replicas gauge
# HELP kube_replicaset_status_observed_generation The generation observed by the ReplicaSet controller.
# TYPE kube_replicaset_status_observed_generation gauge
# HELP kube_replicaset_spec_replicas Number of desired pods for a ReplicaSet.
# TYPE kube_replicaset_spec_replicas gauge
# HELP kube_replicaset_metadata_generation Sequence number representing a specific generation of the desired state.
# TYPE kube_replicaset_metadata_generation gauge
# HELP kube_replicaset_owner Information about the ReplicaSet's owner.
# TYPE kube_replicaset_owner gauge
# HELP kube_replicaset_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_replicaset_labels gauge
# HELP kube_replicationcontroller_created Unix creation timestamp
# TYPE kube_replicationcontroller_created gauge
# HELP kube_replicationcontroller_status_replicas The number of replicas per ReplicationController.
# TYPE kube_replicationcontroller_status_replicas gauge
# HELP kube_replicationcontroller_status_fully_labeled_replicas The number of fully labeled replicas per ReplicationController.
# TYPE kube_replicationcontroller_status_fully_labeled_replicas gauge
# HELP kube_replicationcontroller_status_ready_replicas The number of ready replicas per ReplicationController.
# TYPE kube_replicationcontroller_status_ready_replicas gauge
# HELP kube_replicationcontroller_status_available_replicas The number of available replicas per ReplicationController.
# TYPE kube_replicationcontroller_status_available_replicas gauge
# HELP kube_replicationcontroller_status_observed_generation The generation observed by the ReplicationController controller.
# TYPE kube_replicationcontroller_status_observed_generation gauge
# HELP kube_replicationcontroller_spec_replicas Number of desired pods for a ReplicationController.
# TYPE kube_replicationcontroller_spec_replicas gauge
# HELP kube_replicationcontroller_metadata_generation Sequence number representing a specific generation of the desired state.
# TYPE kube_replicationcontroller_metadata_generation gauge
# HELP kube_replicationcontroller_owner Information about the ReplicationController's owner.
# TYPE kube_replicationcontroller_owner gauge
# HELP kube_resourcequota_created Unix creation timestamp
# TYPE kube_resourcequota_created gauge
# HELP kube_resourcequota Information about resource quota.
# TYPE kube_resourcequota gauge
# HELP kube_secret_info Information about secret.
# TYPE kube_secret_info gauge
# HELP kube_secret_type Type about secret.
# TYPE kube_secret_type gauge
# HELP kube_secret_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_secret_labels gauge
# HELP kube_secret_created Unix creation timestamp
# TYPE kube_secret_created gauge
# HELP kube_secret_metadata_resource_version Resource version representing a specific version of secret.
# TYPE kube_secret_metadata_resource_version gauge
# HELP kube_service_info Information about service.
# TYPE kube_service_info gauge
# HELP kube_service_created Unix creation timestamp
# TYPE kube_service_created gauge
# HELP kube_service_spec_type Type about service.
# TYPE kube_service_spec_type gauge
# HELP kube_service_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_service_labels gauge
# HELP kube_service_spec_external_ip Service external ips. One series for each ip
# TYPE kube_service_spec_external_ip gauge
# HELP kube_service_status_load_balancer_ingress Service load balancer ingress status
# TYPE kube_service_status_load_balancer_ingress gauge
# HELP kube_statefulset_created Unix creation timestamp
# TYPE kube_statefulset_created gauge
# HELP kube_statefulset_status_replicas The number of replicas per StatefulSet.
# TYPE kube_statefulset_status_replicas gauge
# HELP kube_statefulset_status_replicas_current The number of current replicas per StatefulSet.
# TYPE kube_statefulset_status_replicas_current gauge
# HELP kube_statefulset_status_replicas_ready The number of ready replicas per StatefulSet.
# TYPE kube_statefulset_status_replicas_ready gauge
# HELP kube_statefulset_status_replicas_updated The number of updated replicas per StatefulSet.
# TYPE kube_statefulset_status_replicas_updated gauge
# HELP kube_statefulset_status_observed_generation The generation observed by the StatefulSet controller.
# TYPE kube_statefulset_status_observed_generation gauge
# HELP kube_statefulset_replicas Number of desired pods for a StatefulSet.
# TYPE kube_statefulset_replicas gauge
# HELP kube_statefulset_metadata_generation Sequence number representing a specific generation of the desired state for the StatefulSet.
# TYPE kube_statefulset_metadata_generation gauge
# HELP kube_statefulset_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_statefulset_labels gauge
# HELP kube_statefulset_status_current_revision Indicates the version of the StatefulSet used to generate Pods in the sequence [0,currentReplicas).
# TYPE kube_statefulset_status_current_revision gauge
# HELP kube_statefulset_status_update_revision Indicates the version of the StatefulSet used to generate Pods in the sequence [replicas-updatedReplicas,replicas)
# TYPE kube_statefulset_status_update_revision gauge
# HELP kube_storageclass_info Information about storageclass.
# TYPE kube_storageclass_info gauge
# HELP kube_storageclass_created Unix creation timestamp
# TYPE kube_storageclass_created gauge
# HELP kube_storageclass_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_storageclass_labels gauge
# HELP kube_validatingwebhookconfiguration_info Information about the ValidatingWebhookConfiguration.
# TYPE kube_validatingwebhookconfiguration_info gauge
# HELP kube_validatingwebhookconfiguration_created Unix creation timestamp.
# TYPE kube_validatingwebhookconfiguration_created gauge
# HELP kube_validatingwebhookconfiguration_metadata_resource_version Resource version representing a specific version of the ValidatingWebhookConfiguration.
# TYPE kube_validatingwebhookconfiguration_metadata_resource_version gauge
# HELP kube_volumeattachment_labels Kubernetes labels converted to Prometheus labels.
# TYPE kube_volumeattachment_labels gauge
# HELP kube_volumeattachment_info Information about volumeattachment.
# TYPE kube_volumeattachment_info gauge
# HELP kube_volumeattachment_created Unix creation timestamp
# TYPE kube_volumeattachment_created gauge
# HELP kube_volumeattachment_spec_source_persistentvolume PersistentVolume source reference.
# TYPE kube_volumeattachment_spec_source_persistentvolume gauge
# HELP kube_volumeattachment_status_attached Information about volumeattachment.
# TYPE kube_volumeattachment_status_attached gauge
# HELP kube_volumeattachment_status_attachment_metadata volumeattachment metadata.
# TYPE kube_volumeattachment_status_attachment_metadata gauge
```

#### _node-exporter_

There's also [node_exporter](https://github.com/prometheus/node_exporter)
for metrics from the underlying host, the actual available metrics depend on the configured flags.

(excluding `go_`)

```
# HELP node_arp_entries ARP entries by device
# TYPE node_arp_entries gauge
# HELP node_boot_time_seconds Node boot time, in unixtime.
# TYPE node_boot_time_seconds gauge
# HELP node_context_switches_total Total number of context switches.
# TYPE node_context_switches_total counter
# HELP node_cooling_device_cur_state Current throttle state of the cooling device
# TYPE node_cooling_device_cur_state gauge
# HELP node_cooling_device_max_state Maximum throttle state of the cooling device
# TYPE node_cooling_device_max_state gauge
# HELP node_cpu_guest_seconds_total Seconds the CPUs spent in guests (VMs) for each mode.
# TYPE node_cpu_guest_seconds_total counter
# HELP node_cpu_seconds_total Seconds the CPUs spent in each mode.
# TYPE node_cpu_seconds_total counter
# HELP node_disk_discard_time_seconds_total This is the total number of seconds spent by all discards.
# TYPE node_disk_discard_time_seconds_total counter
# HELP node_disk_discarded_sectors_total The total number of sectors discarded successfully.
# TYPE node_disk_discarded_sectors_total counter
# HELP node_disk_discards_completed_total The total number of discards completed successfully.
# TYPE node_disk_discards_completed_total counter
# HELP node_disk_discards_merged_total The total number of discards merged.
# TYPE node_disk_discards_merged_total counter
# HELP node_disk_io_now The number of I/Os currently in progress.
# TYPE node_disk_io_now gauge
# HELP node_disk_io_time_seconds_total Total seconds spent doing I/Os.
# TYPE node_disk_io_time_seconds_total counter
# HELP node_disk_io_time_weighted_seconds_total The weighted # of seconds spent doing I/Os.
# TYPE node_disk_io_time_weighted_seconds_total counter
# HELP node_disk_read_bytes_total The total number of bytes read successfully.
# TYPE node_disk_read_bytes_total counter
# HELP node_disk_read_time_seconds_total The total number of seconds spent by all reads.
# TYPE node_disk_read_time_seconds_total counter
# HELP node_disk_reads_completed_total The total number of reads completed successfully.
# TYPE node_disk_reads_completed_total counter
# HELP node_disk_reads_merged_total The total number of reads merged.
# TYPE node_disk_reads_merged_total counter
# HELP node_disk_write_time_seconds_total This is the total number of seconds spent by all writes.
# TYPE node_disk_write_time_seconds_total counter
# HELP node_disk_writes_completed_total The total number of writes completed successfully.
# TYPE node_disk_writes_completed_total counter
# HELP node_disk_writes_merged_total The number of writes merged.
# TYPE node_disk_writes_merged_total counter
# HELP node_disk_written_bytes_total The total number of bytes written successfully.
# TYPE node_disk_written_bytes_total counter
# HELP node_entropy_available_bits Bits of available entropy.
# TYPE node_entropy_available_bits gauge
# HELP node_entropy_pool_size_bits Bits of entropy pool.
# TYPE node_entropy_pool_size_bits gauge
# HELP node_exporter_build_info A metric with a constant '1' value labeled by version, revision, branch, and goversion from which node_exporter was built.
# TYPE node_exporter_build_info gauge
# HELP node_filefd_allocated File descriptor statistics: allocated.
# TYPE node_filefd_allocated gauge
# HELP node_filefd_maximum File descriptor statistics: maximum.
# TYPE node_filefd_maximum gauge
# HELP node_filesystem_avail_bytes Filesystem space available to non-root users in bytes.
# TYPE node_filesystem_avail_bytes gauge
# HELP node_filesystem_device_error Whether an error occurred while getting statistics for the given device.
# TYPE node_filesystem_device_error gauge
# HELP node_filesystem_files Filesystem total file nodes.
# TYPE node_filesystem_files gauge
# HELP node_filesystem_files_free Filesystem total free file nodes.
# TYPE node_filesystem_files_free gauge
# HELP node_filesystem_free_bytes Filesystem free space in bytes.
# TYPE node_filesystem_free_bytes gauge
# HELP node_filesystem_readonly Filesystem read-only status.
# TYPE node_filesystem_readonly gauge
# HELP node_filesystem_size_bytes Filesystem size in bytes.
# TYPE node_filesystem_size_bytes gauge
# HELP node_forks_total Total number of forks.
# TYPE node_forks_total counter
# HELP node_intr_total Total number of interrupts serviced.
# TYPE node_intr_total counter
# HELP node_ipvs_connections_total The total number of connections made.
# TYPE node_ipvs_connections_total counter
# HELP node_ipvs_incoming_bytes_total The total amount of incoming data.
# TYPE node_ipvs_incoming_bytes_total counter
# HELP node_ipvs_incoming_packets_total The total number of incoming packets.
# TYPE node_ipvs_incoming_packets_total counter
# HELP node_ipvs_outgoing_bytes_total The total amount of outgoing data.
# TYPE node_ipvs_outgoing_bytes_total counter
# HELP node_ipvs_outgoing_packets_total The total number of outgoing packets.
# TYPE node_ipvs_outgoing_packets_total counter
# HELP node_load1 1m load average.
# TYPE node_load1 gauge
# HELP node_load15 15m load average.
# TYPE node_load15 gauge
# HELP node_load5 5m load average.
# TYPE node_load5 gauge
# HELP node_memory_Active_anon_bytes Memory information field Active_anon_bytes.
# TYPE node_memory_Active_anon_bytes gauge
# HELP node_memory_Active_bytes Memory information field Active_bytes.
# TYPE node_memory_Active_bytes gauge
# HELP node_memory_Active_file_bytes Memory information field Active_file_bytes.
# TYPE node_memory_Active_file_bytes gauge
# HELP node_memory_AnonHugePages_bytes Memory information field AnonHugePages_bytes.
# TYPE node_memory_AnonHugePages_bytes gauge
# HELP node_memory_AnonPages_bytes Memory information field AnonPages_bytes.
# TYPE node_memory_AnonPages_bytes gauge
# HELP node_memory_Bounce_bytes Memory information field Bounce_bytes.
# TYPE node_memory_Bounce_bytes gauge
# HELP node_memory_Buffers_bytes Memory information field Buffers_bytes.
# TYPE node_memory_Buffers_bytes gauge
# HELP node_memory_Cached_bytes Memory information field Cached_bytes.
# TYPE node_memory_Cached_bytes gauge
# HELP node_memory_CommitLimit_bytes Memory information field CommitLimit_bytes.
# TYPE node_memory_CommitLimit_bytes gauge
# HELP node_memory_Committed_AS_bytes Memory information field Committed_AS_bytes.
# TYPE node_memory_Committed_AS_bytes gauge
# HELP node_memory_DirectMap1G_bytes Memory information field DirectMap1G_bytes.
# TYPE node_memory_DirectMap1G_bytes gauge
# HELP node_memory_DirectMap2M_bytes Memory information field DirectMap2M_bytes.
# TYPE node_memory_DirectMap2M_bytes gauge
# HELP node_memory_DirectMap4k_bytes Memory information field DirectMap4k_bytes.
# TYPE node_memory_DirectMap4k_bytes gauge
# HELP node_memory_Dirty_bytes Memory information field Dirty_bytes.
# TYPE node_memory_Dirty_bytes gauge
# HELP node_memory_FileHugePages_bytes Memory information field FileHugePages_bytes.
# TYPE node_memory_FileHugePages_bytes gauge
# HELP node_memory_FilePmdMapped_bytes Memory information field FilePmdMapped_bytes.
# TYPE node_memory_FilePmdMapped_bytes gauge
# HELP node_memory_HugePages_Free Memory information field HugePages_Free.
# TYPE node_memory_HugePages_Free gauge
# HELP node_memory_HugePages_Rsvd Memory information field HugePages_Rsvd.
# TYPE node_memory_HugePages_Rsvd gauge
# HELP node_memory_HugePages_Surp Memory information field HugePages_Surp.
# TYPE node_memory_HugePages_Surp gauge
# HELP node_memory_HugePages_Total Memory information field HugePages_Total.
# TYPE node_memory_HugePages_Total gauge
# HELP node_memory_Hugepagesize_bytes Memory information field Hugepagesize_bytes.
# TYPE node_memory_Hugepagesize_bytes gauge
# HELP node_memory_Hugetlb_bytes Memory information field Hugetlb_bytes.
# TYPE node_memory_Hugetlb_bytes gauge
# HELP node_memory_Inactive_anon_bytes Memory information field Inactive_anon_bytes.
# TYPE node_memory_Inactive_anon_bytes gauge
# HELP node_memory_Inactive_bytes Memory information field Inactive_bytes.
# TYPE node_memory_Inactive_bytes gauge
# HELP node_memory_Inactive_file_bytes Memory information field Inactive_file_bytes.
# TYPE node_memory_Inactive_file_bytes gauge
# HELP node_memory_KReclaimable_bytes Memory information field KReclaimable_bytes.
# TYPE node_memory_KReclaimable_bytes gauge
# HELP node_memory_KernelStack_bytes Memory information field KernelStack_bytes.
# TYPE node_memory_KernelStack_bytes gauge
# HELP node_memory_Mapped_bytes Memory information field Mapped_bytes.
# TYPE node_memory_Mapped_bytes gauge
# HELP node_memory_MemAvailable_bytes Memory information field MemAvailable_bytes.
# TYPE node_memory_MemAvailable_bytes gauge
# HELP node_memory_MemFree_bytes Memory information field MemFree_bytes.
# TYPE node_memory_MemFree_bytes gauge
# HELP node_memory_MemTotal_bytes Memory information field MemTotal_bytes.
# TYPE node_memory_MemTotal_bytes gauge
# HELP node_memory_Mlocked_bytes Memory information field Mlocked_bytes.
# TYPE node_memory_Mlocked_bytes gauge
# HELP node_memory_NFS_Unstable_bytes Memory information field NFS_Unstable_bytes.
# TYPE node_memory_NFS_Unstable_bytes gauge
# HELP node_memory_PageTables_bytes Memory information field PageTables_bytes.
# TYPE node_memory_PageTables_bytes gauge
# HELP node_memory_Percpu_bytes Memory information field Percpu_bytes.
# TYPE node_memory_Percpu_bytes gauge
# HELP node_memory_SReclaimable_bytes Memory information field SReclaimable_bytes.
# TYPE node_memory_SReclaimable_bytes gauge
# HELP node_memory_SUnreclaim_bytes Memory information field SUnreclaim_bytes.
# TYPE node_memory_SUnreclaim_bytes gauge
# HELP node_memory_ShmemHugePages_bytes Memory information field ShmemHugePages_bytes.
# TYPE node_memory_ShmemHugePages_bytes gauge
# HELP node_memory_ShmemPmdMapped_bytes Memory information field ShmemPmdMapped_bytes.
# TYPE node_memory_ShmemPmdMapped_bytes gauge
# HELP node_memory_Shmem_bytes Memory information field Shmem_bytes.
# TYPE node_memory_Shmem_bytes gauge
# HELP node_memory_Slab_bytes Memory information field Slab_bytes.
# TYPE node_memory_Slab_bytes gauge
# HELP node_memory_SwapCached_bytes Memory information field SwapCached_bytes.
# TYPE node_memory_SwapCached_bytes gauge
# HELP node_memory_SwapFree_bytes Memory information field SwapFree_bytes.
# TYPE node_memory_SwapFree_bytes gauge
# HELP node_memory_SwapTotal_bytes Memory information field SwapTotal_bytes.
# TYPE node_memory_SwapTotal_bytes gauge
# HELP node_memory_Unevictable_bytes Memory information field Unevictable_bytes.
# TYPE node_memory_Unevictable_bytes gauge
# HELP node_memory_VmallocChunk_bytes Memory information field VmallocChunk_bytes.
# TYPE node_memory_VmallocChunk_bytes gauge
# HELP node_memory_VmallocTotal_bytes Memory information field VmallocTotal_bytes.
# TYPE node_memory_VmallocTotal_bytes gauge
# HELP node_memory_VmallocUsed_bytes Memory information field VmallocUsed_bytes.
# TYPE node_memory_VmallocUsed_bytes gauge
# HELP node_memory_WritebackTmp_bytes Memory information field WritebackTmp_bytes.
# TYPE node_memory_WritebackTmp_bytes gauge
# HELP node_memory_Writeback_bytes Memory information field Writeback_bytes.
# TYPE node_memory_Writeback_bytes gauge
# HELP node_netstat_Icmp6_InErrors Statistic Icmp6InErrors.
# TYPE node_netstat_Icmp6_InErrors untyped
# HELP node_netstat_Icmp6_InMsgs Statistic Icmp6InMsgs.
# TYPE node_netstat_Icmp6_InMsgs untyped
# HELP node_netstat_Icmp6_OutMsgs Statistic Icmp6OutMsgs.
# TYPE node_netstat_Icmp6_OutMsgs untyped
# HELP node_netstat_Icmp_InErrors Statistic IcmpInErrors.
# TYPE node_netstat_Icmp_InErrors untyped
# HELP node_netstat_Icmp_InMsgs Statistic IcmpInMsgs.
# TYPE node_netstat_Icmp_InMsgs untyped
# HELP node_netstat_Icmp_OutMsgs Statistic IcmpOutMsgs.
# TYPE node_netstat_Icmp_OutMsgs untyped
# HELP node_netstat_Ip6_InOctets Statistic Ip6InOctets.
# TYPE node_netstat_Ip6_InOctets untyped
# HELP node_netstat_Ip6_OutOctets Statistic Ip6OutOctets.
# TYPE node_netstat_Ip6_OutOctets untyped
# HELP node_netstat_IpExt_InOctets Statistic IpExtInOctets.
# TYPE node_netstat_IpExt_InOctets untyped
# HELP node_netstat_IpExt_OutOctets Statistic IpExtOutOctets.
# TYPE node_netstat_IpExt_OutOctets untyped
# HELP node_netstat_Ip_Forwarding Statistic IpForwarding.
# TYPE node_netstat_Ip_Forwarding untyped
# HELP node_netstat_TcpExt_ListenDrops Statistic TcpExtListenDrops.
# TYPE node_netstat_TcpExt_ListenDrops untyped
# HELP node_netstat_TcpExt_ListenOverflows Statistic TcpExtListenOverflows.
# TYPE node_netstat_TcpExt_ListenOverflows untyped
# HELP node_netstat_TcpExt_SyncookiesFailed Statistic TcpExtSyncookiesFailed.
# TYPE node_netstat_TcpExt_SyncookiesFailed untyped
# HELP node_netstat_TcpExt_SyncookiesRecv Statistic TcpExtSyncookiesRecv.
# TYPE node_netstat_TcpExt_SyncookiesRecv untyped
# HELP node_netstat_TcpExt_SyncookiesSent Statistic TcpExtSyncookiesSent.
# TYPE node_netstat_TcpExt_SyncookiesSent untyped
# HELP node_netstat_TcpExt_TCPSynRetrans Statistic TcpExtTCPSynRetrans.
# TYPE node_netstat_TcpExt_TCPSynRetrans untyped
# HELP node_netstat_Tcp_ActiveOpens Statistic TcpActiveOpens.
# TYPE node_netstat_Tcp_ActiveOpens untyped
# HELP node_netstat_Tcp_CurrEstab Statistic TcpCurrEstab.
# TYPE node_netstat_Tcp_CurrEstab untyped
# HELP node_netstat_Tcp_InErrs Statistic TcpInErrs.
# TYPE node_netstat_Tcp_InErrs untyped
# HELP node_netstat_Tcp_InSegs Statistic TcpInSegs.
# TYPE node_netstat_Tcp_InSegs untyped
# HELP node_netstat_Tcp_OutRsts Statistic TcpOutRsts.
# TYPE node_netstat_Tcp_OutRsts untyped
# HELP node_netstat_Tcp_OutSegs Statistic TcpOutSegs.
# TYPE node_netstat_Tcp_OutSegs untyped
# HELP node_netstat_Tcp_PassiveOpens Statistic TcpPassiveOpens.
# TYPE node_netstat_Tcp_PassiveOpens untyped
# HELP node_netstat_Tcp_RetransSegs Statistic TcpRetransSegs.
# TYPE node_netstat_Tcp_RetransSegs untyped
# HELP node_netstat_Udp6_InDatagrams Statistic Udp6InDatagrams.
# TYPE node_netstat_Udp6_InDatagrams untyped
# HELP node_netstat_Udp6_InErrors Statistic Udp6InErrors.
# TYPE node_netstat_Udp6_InErrors untyped
# HELP node_netstat_Udp6_NoPorts Statistic Udp6NoPorts.
# TYPE node_netstat_Udp6_NoPorts untyped
# HELP node_netstat_Udp6_OutDatagrams Statistic Udp6OutDatagrams.
# TYPE node_netstat_Udp6_OutDatagrams untyped
# HELP node_netstat_Udp6_RcvbufErrors Statistic Udp6RcvbufErrors.
# TYPE node_netstat_Udp6_RcvbufErrors untyped
# HELP node_netstat_Udp6_SndbufErrors Statistic Udp6SndbufErrors.
# TYPE node_netstat_Udp6_SndbufErrors untyped
# HELP node_netstat_UdpLite6_InErrors Statistic UdpLite6InErrors.
# TYPE node_netstat_UdpLite6_InErrors untyped
# HELP node_netstat_UdpLite_InErrors Statistic UdpLiteInErrors.
# TYPE node_netstat_UdpLite_InErrors untyped
# HELP node_netstat_Udp_InDatagrams Statistic UdpInDatagrams.
# TYPE node_netstat_Udp_InDatagrams untyped
# HELP node_netstat_Udp_InErrors Statistic UdpInErrors.
# TYPE node_netstat_Udp_InErrors untyped
# HELP node_netstat_Udp_NoPorts Statistic UdpNoPorts.
# TYPE node_netstat_Udp_NoPorts untyped
# HELP node_netstat_Udp_OutDatagrams Statistic UdpOutDatagrams.
# TYPE node_netstat_Udp_OutDatagrams untyped
# HELP node_netstat_Udp_RcvbufErrors Statistic UdpRcvbufErrors.
# TYPE node_netstat_Udp_RcvbufErrors untyped
# HELP node_netstat_Udp_SndbufErrors Statistic UdpSndbufErrors.
# TYPE node_netstat_Udp_SndbufErrors untyped
# HELP node_network_address_assign_type address_assign_type value of /sys/class/net/<iface>.
# TYPE node_network_address_assign_type gauge
# HELP node_network_carrier carrier value of /sys/class/net/<iface>.
# TYPE node_network_carrier gauge
# HELP node_network_carrier_changes_total carrier_changes_total value of /sys/class/net/<iface>.
# TYPE node_network_carrier_changes_total counter
# HELP node_network_carrier_down_changes_total carrier_down_changes_total value of /sys/class/net/<iface>.
# TYPE node_network_carrier_down_changes_total counter
# HELP node_network_carrier_up_changes_total carrier_up_changes_total value of /sys/class/net/<iface>.
# TYPE node_network_carrier_up_changes_total counter
# HELP node_network_device_id device_id value of /sys/class/net/<iface>.
# TYPE node_network_device_id gauge
# HELP node_network_dormant dormant value of /sys/class/net/<iface>.
# TYPE node_network_dormant gauge
# HELP node_network_flags flags value of /sys/class/net/<iface>.
# TYPE node_network_flags gauge
# HELP node_network_iface_id iface_id value of /sys/class/net/<iface>.
# TYPE node_network_iface_id gauge
# HELP node_network_iface_link iface_link value of /sys/class/net/<iface>.
# TYPE node_network_iface_link gauge
# HELP node_network_iface_link_mode iface_link_mode value of /sys/class/net/<iface>.
# TYPE node_network_iface_link_mode gauge
# HELP node_network_info Non-numeric data from /sys/class/net/<iface>, value is always 1.
# TYPE node_network_info gauge
# HELP node_network_mtu_bytes mtu_bytes value of /sys/class/net/<iface>.
# TYPE node_network_mtu_bytes gauge
# HELP node_network_name_assign_type name_assign_type value of /sys/class/net/<iface>.
# TYPE node_network_name_assign_type gauge
# HELP node_network_net_dev_group net_dev_group value of /sys/class/net/<iface>.
# TYPE node_network_net_dev_group gauge
# HELP node_network_protocol_type protocol_type value of /sys/class/net/<iface>.
# TYPE node_network_protocol_type gauge
# HELP node_network_receive_bytes_total Network device statistic receive_bytes.
# TYPE node_network_receive_bytes_total counter
# HELP node_network_receive_compressed_total Network device statistic receive_compressed.
# TYPE node_network_receive_compressed_total counter
# HELP node_network_receive_drop_total Network device statistic receive_drop.
# TYPE node_network_receive_drop_total counter
# HELP node_network_receive_errs_total Network device statistic receive_errs.
# TYPE node_network_receive_errs_total counter
# HELP node_network_receive_fifo_total Network device statistic receive_fifo.
# TYPE node_network_receive_fifo_total counter
# HELP node_network_receive_frame_total Network device statistic receive_frame.
# TYPE node_network_receive_frame_total counter
# HELP node_network_receive_multicast_total Network device statistic receive_multicast.
# TYPE node_network_receive_multicast_total counter
# HELP node_network_receive_packets_total Network device statistic receive_packets.
# TYPE node_network_receive_packets_total counter
# HELP node_network_speed_bytes speed_bytes value of /sys/class/net/<iface>.
# TYPE node_network_speed_bytes gauge
# HELP node_network_transmit_bytes_total Network device statistic transmit_bytes.
# TYPE node_network_transmit_bytes_total counter
# HELP node_network_transmit_carrier_total Network device statistic transmit_carrier.
# TYPE node_network_transmit_carrier_total counter
# HELP node_network_transmit_colls_total Network device statistic transmit_colls.
# TYPE node_network_transmit_colls_total counter
# HELP node_network_transmit_compressed_total Network device statistic transmit_compressed.
# TYPE node_network_transmit_compressed_total counter
# HELP node_network_transmit_drop_total Network device statistic transmit_drop.
# TYPE node_network_transmit_drop_total counter
# HELP node_network_transmit_errs_total Network device statistic transmit_errs.
# TYPE node_network_transmit_errs_total counter
# HELP node_network_transmit_fifo_total Network device statistic transmit_fifo.
# TYPE node_network_transmit_fifo_total counter
# HELP node_network_transmit_packets_total Network device statistic transmit_packets.
# TYPE node_network_transmit_packets_total counter
# HELP node_network_transmit_queue_length transmit_queue_length value of /sys/class/net/<iface>.
# TYPE node_network_transmit_queue_length gauge
# HELP node_network_up Value is 1 if operstate is 'up', 0 otherwise.
# TYPE node_network_up gauge
# HELP node_nf_conntrack_entries Number of currently allocated flow entries for connection tracking.
# TYPE node_nf_conntrack_entries gauge
# HELP node_nf_conntrack_entries_limit Maximum size of connection tracking table.
# TYPE node_nf_conntrack_entries_limit gauge
# HELP node_nf_conntrack_stat_drop Number of packets dropped due to conntrack failure.
# TYPE node_nf_conntrack_stat_drop gauge
# HELP node_nf_conntrack_stat_early_drop Number of dropped conntrack entries to make room for new ones, if maximum table size was reached.
# TYPE node_nf_conntrack_stat_early_drop gauge
# HELP node_nf_conntrack_stat_found Number of searched entries which were successful.
# TYPE node_nf_conntrack_stat_found gauge
# HELP node_nf_conntrack_stat_ignore Number of packets seen which are already connected to a conntrack entry.
# TYPE node_nf_conntrack_stat_ignore gauge
# HELP node_nf_conntrack_stat_insert Number of entries inserted into the list.
# TYPE node_nf_conntrack_stat_insert gauge
# HELP node_nf_conntrack_stat_insert_failed Number of entries for which list insertion was attempted but failed.
# TYPE node_nf_conntrack_stat_insert_failed gauge
# HELP node_nf_conntrack_stat_invalid Number of packets seen which can not be tracked.
# TYPE node_nf_conntrack_stat_invalid gauge
# HELP node_nf_conntrack_stat_search_restart Number of conntrack table lookups which had to be restarted due to hashtable resizes.
# TYPE node_nf_conntrack_stat_search_restart gauge
# HELP node_procs_blocked Number of processes blocked waiting for I/O to complete.
# TYPE node_procs_blocked gauge
# HELP node_procs_running Number of processes in runnable state.
# TYPE node_procs_running gauge
# HELP node_schedstat_running_seconds_total Number of seconds CPU spent running a process.
# TYPE node_schedstat_running_seconds_total counter
# HELP node_schedstat_timeslices_total Number of timeslices executed by CPU.
# TYPE node_schedstat_timeslices_total counter
# HELP node_schedstat_waiting_seconds_total Number of seconds spent by processing waiting for this CPU.
# TYPE node_schedstat_waiting_seconds_total counter
# HELP node_scrape_collector_duration_seconds node_exporter: Duration of a collector scrape.
# TYPE node_scrape_collector_duration_seconds gauge
# HELP node_scrape_collector_success node_exporter: Whether a collector succeeded.
# TYPE node_scrape_collector_success gauge
# HELP node_sockstat_FRAG6_inuse Number of FRAG6 sockets in state inuse.
# TYPE node_sockstat_FRAG6_inuse gauge
# HELP node_sockstat_FRAG6_memory Number of FRAG6 sockets in state memory.
# TYPE node_sockstat_FRAG6_memory gauge
# HELP node_sockstat_FRAG_inuse Number of FRAG sockets in state inuse.
# TYPE node_sockstat_FRAG_inuse gauge
# HELP node_sockstat_FRAG_memory Number of FRAG sockets in state memory.
# TYPE node_sockstat_FRAG_memory gauge
# HELP node_sockstat_RAW6_inuse Number of RAW6 sockets in state inuse.
# TYPE node_sockstat_RAW6_inuse gauge
# HELP node_sockstat_RAW_inuse Number of RAW sockets in state inuse.
# TYPE node_sockstat_RAW_inuse gauge
# HELP node_sockstat_TCP6_inuse Number of TCP6 sockets in state inuse.
# TYPE node_sockstat_TCP6_inuse gauge
# HELP node_sockstat_TCP_alloc Number of TCP sockets in state alloc.
# TYPE node_sockstat_TCP_alloc gauge
# HELP node_sockstat_TCP_inuse Number of TCP sockets in state inuse.
# TYPE node_sockstat_TCP_inuse gauge
# HELP node_sockstat_TCP_mem Number of TCP sockets in state mem.
# TYPE node_sockstat_TCP_mem gauge
# HELP node_sockstat_TCP_mem_bytes Number of TCP sockets in state mem_bytes.
# TYPE node_sockstat_TCP_mem_bytes gauge
# HELP node_sockstat_TCP_orphan Number of TCP sockets in state orphan.
# TYPE node_sockstat_TCP_orphan gauge
# HELP node_sockstat_TCP_tw Number of TCP sockets in state tw.
# TYPE node_sockstat_TCP_tw gauge
# HELP node_sockstat_UDP6_inuse Number of UDP6 sockets in state inuse.
# TYPE node_sockstat_UDP6_inuse gauge
# HELP node_sockstat_UDPLITE6_inuse Number of UDPLITE6 sockets in state inuse.
# TYPE node_sockstat_UDPLITE6_inuse gauge
# HELP node_sockstat_UDPLITE_inuse Number of UDPLITE sockets in state inuse.
# TYPE node_sockstat_UDPLITE_inuse gauge
# HELP node_sockstat_UDP_inuse Number of UDP sockets in state inuse.
# TYPE node_sockstat_UDP_inuse gauge
# HELP node_sockstat_UDP_mem Number of UDP sockets in state mem.
# TYPE node_sockstat_UDP_mem gauge
# HELP node_sockstat_UDP_mem_bytes Number of UDP sockets in state mem_bytes.
# TYPE node_sockstat_UDP_mem_bytes gauge
# HELP node_sockstat_sockets_used Number of IPv4 sockets in use.
# TYPE node_sockstat_sockets_used gauge
# HELP node_softnet_dropped_total Number of dropped packets
# TYPE node_softnet_dropped_total counter
# HELP node_softnet_processed_total Number of processed packets
# TYPE node_softnet_processed_total counter
# HELP node_softnet_times_squeezed_total Number of times processing packets ran out of quota
# TYPE node_softnet_times_squeezed_total counter
# HELP node_textfile_scrape_error 1 if there was an error opening or reading a file, 0 otherwise
# TYPE node_textfile_scrape_error gauge
# HELP node_time_seconds System time in seconds since epoch (1970).
# TYPE node_time_seconds gauge
# HELP node_time_zone_offset_seconds System time zone offset in seconds.
# TYPE node_time_zone_offset_seconds gauge
# HELP node_timex_estimated_error_seconds Estimated error in seconds.
# TYPE node_timex_estimated_error_seconds gauge
# HELP node_timex_frequency_adjustment_ratio Local clock frequency adjustment.
# TYPE node_timex_frequency_adjustment_ratio gauge
# HELP node_timex_loop_time_constant Phase-locked loop time constant.
# TYPE node_timex_loop_time_constant gauge
# HELP node_timex_maxerror_seconds Maximum error in seconds.
# TYPE node_timex_maxerror_seconds gauge
# HELP node_timex_offset_seconds Time offset in between local system and reference clock.
# TYPE node_timex_offset_seconds gauge
# HELP node_timex_pps_calibration_total Pulse per second count of calibration intervals.
# TYPE node_timex_pps_calibration_total counter
# HELP node_timex_pps_error_total Pulse per second count of calibration errors.
# TYPE node_timex_pps_error_total counter
# HELP node_timex_pps_frequency_hertz Pulse per second frequency.
# TYPE node_timex_pps_frequency_hertz gauge
# HELP node_timex_pps_jitter_seconds Pulse per second jitter.
# TYPE node_timex_pps_jitter_seconds gauge
# HELP node_timex_pps_jitter_total Pulse per second count of jitter limit exceeded events.
# TYPE node_timex_pps_jitter_total counter
# HELP node_timex_pps_shift_seconds Pulse per second interval duration.
# TYPE node_timex_pps_shift_seconds gauge
# HELP node_timex_pps_stability_exceeded_total Pulse per second count of stability limit exceeded events.
# TYPE node_timex_pps_stability_exceeded_total counter
# HELP node_timex_pps_stability_hertz Pulse per second stability, average of recent frequency changes.
# TYPE node_timex_pps_stability_hertz gauge
# HELP node_timex_status Value of the status array bits.
# TYPE node_timex_status gauge
# HELP node_timex_sync_status Is clock synchronized to a reliable server (1 = yes, 0 = no).
# TYPE node_timex_sync_status gauge
# HELP node_timex_tai_offset_seconds International Atomic Time (TAI) offset.
# TYPE node_timex_tai_offset_seconds gauge
# HELP node_timex_tick_seconds Seconds between clock ticks.
# TYPE node_timex_tick_seconds gauge
# HELP node_udp_queues Number of allocated memory in the kernel for UDP datagrams in bytes.
# TYPE node_udp_queues gauge
# HELP node_uname_info Labeled system information as provided by the uname system call.
# TYPE node_uname_info gauge
# HELP node_vmstat_oom_kill /proc/vmstat information field oom_kill.
# TYPE node_vmstat_oom_kill untyped
# HELP node_vmstat_pgfault /proc/vmstat information field pgfault.
# TYPE node_vmstat_pgfault untyped
# HELP node_vmstat_pgmajfault /proc/vmstat information field pgmajfault.
# TYPE node_vmstat_pgmajfault untyped
# HELP node_vmstat_pgpgin /proc/vmstat information field pgpgin.
# TYPE node_vmstat_pgpgin untyped
# HELP node_vmstat_pgpgout /proc/vmstat information field pgpgout.
# TYPE node_vmstat_pgpgout untyped
# HELP node_vmstat_pswpin /proc/vmstat information field pswpin.
# TYPE node_vmstat_pswpin untyped
# HELP node_vmstat_pswpout /proc/vmstat information field pswpout.
# TYPE node_vmstat_pswpout untyped
# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
# TYPE process_cpu_seconds_total counter
# HELP process_max_fds Maximum number of open file descriptors.
# TYPE process_max_fds gauge
# HELP process_open_fds Number of open file descriptors.
# TYPE process_open_fds gauge
# HELP process_resident_memory_bytes Resident memory size in bytes.
# TYPE process_resident_memory_bytes gauge
# HELP process_start_time_seconds Start time of the process since unix epoch in seconds.
# TYPE process_start_time_seconds gauge
# HELP process_virtual_memory_bytes Virtual memory size in bytes.
# TYPE process_virtual_memory_bytes gauge
# HELP process_virtual_memory_max_bytes Maximum amount of virtual memory available in bytes.
# TYPE process_virtual_memory_max_bytes gauge
# HELP promhttp_metric_handler_errors_total Total number of internal errors encountered by the promhttp metric handler.
# TYPE promhttp_metric_handler_errors_total counter
# HELP promhttp_metric_handler_requests_in_flight Current number of scrapes being served.
# TYPE promhttp_metric_handler_requests_in_flight gauge
# HELP promhttp_metric_handler_requests_total Total number of scrapes by HTTP status code.
# TYPE promhttp_metric_handler_requests_total counter
```

#### _metrics-server_

You may see references to [metrics-server](https://github.com/kubernetes-sigs/metrics-server).
This "just" scrapes kubelet for the same info and exposes it to the api server
for use with autoscalers.

Since it doesn't actually produce data, it doesn't make sense to scrape it.
