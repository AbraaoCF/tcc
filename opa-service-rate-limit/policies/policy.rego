package envoy.authz

import rego.v1

http_request := input.attributes.request.http

rate_limit_user := data.rate_limits_config.user_max_requests_per_window

rate_limit_endpoint := data.rate_limits_config.endpoint_max_requests_per_window

rate_limit_user_endpoint := data.rate_limits_config.user_endpoint_requests_per_window



now := time.now_ns() / 1000000000 # Current time in seconds

window_start := now - data.rate_limits_config.time_window_seconds

environmental if {
	data.rate_limits_config.night_mode_enabled
	# night_logic
}

environmental if {
	not data.rate_limits_config.night_mode_enabled
}

# night_logic if {
# 	print("night")
#     [hour, _, _]:= time.clock(time.now_ns())
# 	print(hour)
# 	print(hour>=9)
# 	hour >= 9 # Start of business hours
# 	# hour <= 20 # End of business hours
# 	print("passou")
# 	print(rate_limit_user)
# 	rate_limit_user = 6
# 	print(rate_limit_user)

# 	rate_limit_endpoint = 6
# 	rate_limit_user_endpoint = 6
# }

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
	print(user)
	environmental
	print(rate_limit_user)
	# User martelando
	user_logs_count := request_count(user, rate_limit_user, window_start)
	print(user_logs_count)
	user_logs_count < rate_limit_user

	# Endpoint martelado
	endpoint_logs_count := request_count(endpoint, rate_limit_endpoint, window_start)
	print(endpoint_logs_count)
	endpoint_logs_count < rate_limit_endpoint

	# User martelando, endpoint martelado
	user_endpoint := sprintf("%s/%s", [user, endpoint])
	user_endpoint_logs_count := request_count(user_endpoint, rate_limit_user_endpoint, window_start)
	print(user_endpoint_logs_count)
	user_endpoint_logs_count < rate_limit_user_endpoint

	response := {
		"allowed": true,
		"headers": {"x-authorized-by": "OPA"},
		"id": user,
	}
	log_request(user)
	log_request(endpoint)
	log_request(user_endpoint)
}

request_count(id, size, window_start) := counter if {
	print(urlquery.encode(id))
	print("http://localhost:7379/LRANGE/", id, "/-", size, "/-1")
	redisl := http.send({
		"method": "GET",
		"url": sprintf("http://localhost:7379/LRANGE/%s/-%v/-1", [urlquery.encode(id), size]),
	})
	print(redisl.body.LRANGE)
	filtered := filter_logs(redisl.body.LRANGE, window_start)
	print(filtered)
	counter := count(filtered)
}

log_request(id) if {
	print(now)
	print("http://localhost:7379/RPUSH/", id, "/", now)
	http.send({
		"method": "GET",
		"url": sprintf("http://localhost:7379/RPUSH/%s/%.5f", [urlquery.encode(id), now]),
	})
}

# Convert string timestamps to float numbers and filter
filter_logs(timestamps, window) := {to_number(ts) | some ts in timestamps; to_number(ts) >= window}
