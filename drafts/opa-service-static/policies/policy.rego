package envoy.authz

import rego.v1

http_request := input.attributes.request.http

default allow := false

# Admin
allow := response if {
	svc_spiffe_id == "spiffe://acme.com/admin"
	response := {
		"allowed": true,
		"headers": {"x-authorized-by": "OPA"},
		"id": svc_spiffe_id,
	}
}

allow := response if {
	http_request.method == "GET"
	allow_path

	user := svc_spiffe_id
	user_logs := filter_logs(user, window_start, data.timestamps_user[user])
	count(user_logs) < data.rate_limits_config.max_requests_per_window

	response := {
		"allowed": true,
		"headers": {"x-authorized-by": "OPA"},
		"id": user,
	}
}

# Helper function to get user logs within the time window
filter_logs(user, window_start, timestamps) := {log | some log in timestamps; log > window_start}

window_start := window if {
	now := time.now_ns() / 1000000000 # Current time in seconds
	window := now - data.rate_limits_config.time_window_seconds
}

# # Log access if allowed
# log_access {
#     user := svc_spiffe_id
#     timestamp := time.now_ns()
#     new_log := array.concat(user_logs, [timestamp])
#     print("Updating user logs for user:", user, "with new log:", new_log)
#     updated_rate_limits := object.union({user: new_log}, data.logging)
#     print(data.logging)
#     data.logging[svc_spiffe_id] = new_log
# }
# # Helper rule to check if the user log exists
# user_logs := [] if {
#     not data.logging[svc_spiffe_id]
# } else := data.logging[svc_spiffe_id]
# names := [name | sites[i].region == region; name := sites[i].name]
# Add to Envoy under "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager]
#   forward_client_cert_details: sanitize_set
#   set_current_client_cert_details:
#       uri: true
# curl -X GET http://localhost:8080/service/rest/consumptionHistory \
#  -H "x-forwarded-client-cert: By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto1"
