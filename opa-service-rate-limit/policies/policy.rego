package envoy.authz

import rego.v1

http_request := input.attributes.request.http

rate_limit_user := data.rate_limits_config.user_max_requests_per_window

rate_limit_endpoint := data.rate_limits_config.endpoint_max_requests_per_window

rate_limit_user_endpoint := data.rate_limits_config.user_endpoint_requests_per_window

projects_config := data.projects_config

now := time.now_ns() / 1000000000 # Current time in seconds

window_start := now - data.rate_limits_config.time_window_seconds

user_budget := budget if {
	not outside_working_hours
	budget := projects_config[svc_spiffe_id].budget
}

user_budget := budget if {
	outside_working_hours
	budget := night_mode
}

outside_working_hours if {
	[hour, _, _] := time.clock(time.now_ns())
	print("outside_working_hours -", hour)

	not hour >= 9 # Start of business hours
	not hour <= 20 # End of business hours
	print("outside_working_hours - outside")
}

night_mode := budget if {
	projects_config[svc_spiffe_id].night_mode
	budget := projects_config[svc_spiffe_id].budget * 1.2
}

night_mode := budget if {
	not projects_config[svc_spiffe_id].night_mode
	budget := projects_config[svc_spiffe_id].budget * 0.7
}

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
	endpoint := allow_path
	user := svc_spiffe_id
	print("allow -", endpoint, user)
	print("allow - setup_user_budget:", user_budget)
	print("allow - rate_limit_user:", rate_limit_user)

	# User martelando
	user_logs_count := request_count(user, rate_limit_user, window_start)
	print("allow - user_logs_count:", user_logs_count)
	user_logs_count < rate_limit_user

	# Endpoint martelado
	endpoint_logs_count := request_count(endpoint, rate_limit_endpoint, window_start)
	print("allow - endpoint_logs_count:", endpoint_logs_count)
	endpoint_logs_count < rate_limit_endpoint

	# User martelando, endpoint martelado
	user_endpoint := sprintf("%s/%s", [user, endpoint])
	user_endpoint_logs_count := request_count(user_endpoint, rate_limit_user_endpoint, window_start)
	print("allow - user_endpoint_logs_count:", user_endpoint_logs_count)
	user_endpoint_logs_count < rate_limit_user_endpoint

	# Budget
	print("allow - user_budget_begin")
	user_id_budget := sprintf("%s/budget", [user])
	cost_logs := request_logs_cost(user_id_budget, user_budget, window_start)
	cost_request := data.cost_endpoints[endpoint]
	print("allow - cost_logs/cost_request:", cost_logs, cost_request)
	cost_logs + cost_request < user_budget
	print("allow - user_budget_end")

	# Response
	response := {
		"allowed": true,
		"headers": {"x-authorized-by": "OPA"},
		"id": user,
	}

	log_request(user, now)
	log_request(endpoint, now)
	log_request(user_endpoint, now)

	log_request_budget(user_id_budget, now, cost_request)
}

request_count(id, size, window_start) := counter if {
	print("request_count URL - http://localhost:7379/LRANGE/", urlquery.encode(id), "/0/", size)
	redisl := http.send({
		"method": "GET",
		"url": sprintf("http://localhost:7379/LRANGE/%s/0/%v", [urlquery.encode(id), size]),
	})
	print("request_count result -", redisl.body.LRANGE)
	filtered := filter_logs(redisl.body.LRANGE, window_start)
	counter := count(filtered)
}

request_logs_cost(id, budget, window_start) := total_cost if {
	print("request_logs_cost URL - http://localhost:7379/LRANGE/", urlquery.encode(id), "/0/", budget)
	redisl := http.send({
		"method": "GET",
		"url": sprintf("http://localhost:7379/LRANGE/%s/0/%v", [urlquery.encode(id), budget]),
	})
	print("request_logs_cost result - ", redisl.body.LRANGE)
	filtered_costs := [parse_value(item).cost | some item in redisl.body.LRANGE; parse_value(item).timestamp > window_start]
	print("request_logs_cost result - ", filtered_costs)
	total_cost := sum(filtered_costs)
}

# Budget
log_request_budget(id, timestamp, value) if {
	valor := sprintf("%.5f:%v", [timestamp, value])
	print(sprintf("http://localhost:7379/LPUSH/%s/%s", [urlquery.encode(id), urlquery.encode(valor)]))
	answer := http.send({
		"method": "GET",
		"url": sprintf("http://localhost:7379/LPUSH/%s/%s", [urlquery.encode(id), urlquery.encode(valor)]),
	})
	print("log_request_budget result:", answer.body)
}

log_request(id, value) if {
	print("log_request URL - http://localhost:7379/LPUSH/", urlquery.encode(id), "/", "/", value)
	http.send({
		"method": "GET",
		"url": sprintf("http://localhost:7379/RPUSH/%s/%.5f", [urlquery.encode(id), value]),
	})
}

# Convert string timestamps to float numbers and filter
filter_logs(timestamps, window) := {to_number(ts) | some ts in timestamps; to_number(ts) >= window}

parse_value(item) := {"timestamp": ts, "cost": cost} if {
	parts := split(item, ":")
	ts = to_number(parts[0])
	cost = to_number(parts[1])
}
