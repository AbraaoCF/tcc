package envoy.authz

import input.attributes.request.http as http_request

# Admin
allow = response {
    svc_spiffe_id == "spiffe://acme.com/admin"
}

# Auth
allowed_path_auth {
    re_match("^/service/rest/auth$", [], http_request.path)
    svc_spiffe_id 
}

# Building
allowed_path_building {
    re_match("^/service/rest/building/[^/]+$", [], http_request.path)
}

allowed_path_sensors {
    re_match("^/service/rest/building/[^/]+/sensors$", [], http_request.path)
}

allowed_path_demands {
    re_match("^/service/rest/building/[^/]+/demands$", [], http_request.path)
}

# Consumption
allowed_path_demand_last {
    re_match("^/service/rest/building/[^/]+/demand/last$", [], http_request.path)
}

allowed_path_demand_last_n_minutes {
    re_match("^/service/rest/building/[^/]+/demand/last_n_minutes$", [], http_request.path)
}

allowed_path_consumption {
    re_match("^/service/rest/building/[^/]+/consumption$", [], http_request.path)
}

allowed_path_demand_report {
    re_match("^/service/rest/building/[^/]+/demandReport$", [], http_request.path)
}

# Unsupported Media Type
allowed_path_consumption_disaggregated {
    re_match("^/service/rest/building/[^/]+/consumption/disaggregated$", [], http_request.path)
}

# Sensor
allowed_path_service_sensors {
    re_match("^/service/rest/sensors$", [], http_request.path)
}

allowed_path_sensor {
    re_match("^/service/rest/sensor/[^/]+$", [], http_request.path)
}

allowed_path_consumption_history {
    re_match("^/service/rest/consumptionHistory$", [], http_request.path)
}

# Statistics
allowed_path_statistics {
    re_match("^/service/rest/building/[^/]+/statistics$", [], http_request.path)
}

allowed_path_sensor_statistics {
    re_match("^/service/rest/sensor/[^/]+/statistics$", [], http_request.path)
}

allowed_path_statistics_status {
    re_match("^/service/rest/building/[^/]+/statisticsStatus$", [], http_request.path)
}

allowed_path_period_statistics_status {
    re_match("^/service/rest/building/[^/]+/periodStatisticsStatus$", [], http_request.path)
}

allowed_path_statistics_alwayson {
    re_match("^/service/rest/building/[^/]+/statistics/alwayson$", [], http_request.path)
}

# User
allowed_path_user_sensors {
    re_match("^/service/rest/user/[^/]+/sensors$", [], http_request.path)
}

# Allow rule
allow = response {
    http_request.method == "GET"
    allowed_path_building
    or allowed_path_sensors
    or allowed_path_demands
    or allowed_path_demand_last
    or allowed_path_demand_last_n_minutes
    or allowed_path_consumption
    or allowed_path_demand_report
    or allowed_path_consumption_disaggregated
    or allowed_path_service_sensors
    or allowed_path_sensor
    or allowed_path_consumption_history
    or allowed_path_statistics
    or allowed_path_sensor_statistics
    or allowed_path_statistics_status
    or allowed_path_period_statistics_status
    or allowed_path_statistics_alwayson
    or allowed_path_user_sensors
}

allow = response {
    http_request.method == "POST"
    allowed_path_auth

    user := http_request.headers["x-user"]  # Extract user from the request headers
    now := time.now_ns() / 1000000000  # Current time in seconds
    window_start := now - rate_limit.time_window_seconds

    # Fetch the user's request logs
    user_logs := get_user_logs(user, window_start)
    # Allow if the number of requests within the time window is below the limit
    count(user_logs) < rate_limit.max_requests_per_window
}

# Helper function to get user logs within the time window
get_user_logs(user, window_start) = logs {
    logs := {log | log := data.rate_limit_logs[user][_]; log.timestamp > window_start}
}

# Log the request if allowed
log_request {
    allow
    user := http_request.headers["x-user"]
    now := time.now_ns() / 1000000000  # Current time in seconds

    # Append the log entry
    data.rate_limit_logs[user][_] := {"timestamp": now, "path": http_request.path}
}

# {
#   "rate_limits": {
#     "user1": [timestamp1, timestamp2, ...],
#     "user2": [timestamp1, timestamp2, ...],
#     ...
#   }
# }

svc_spiffe_id := client_id {
    [_, _, uri_type_san] := split(http_request.headers["x-forwarded-client-cert"], ";")
    [_, client_id] := split(uri_type_san, "=")
}

building_svc := ["spiffe://acme.com/projeto1", "spiffe://acme.com/projeto2"]
consumption_svc := ["spiffe://acme.com/projeto3"]
disaggregated_svc := ["spiffe://acme.com/projeto3"]
sensor_svc := ["spiffe://acme.com/projeto1", "spiffe://acme.com/projeto2"]
statistics_svc := ["spiffe://acme.com/projeto1", "spiffe://acme.com/projeto2", "spiffe://acme.com/projeto3"]
user_svc := ["spiffe://acme.com/projeto1", "spiffe://acme.com/projeto2"]


# Configuration
rate_limit = {
    "time_window_seconds": 60,  # Time window for rate limit in seconds
    "max_requests_per_window": 100  # Maximum number of requests per user per window
}


# names := [name | sites[i].region == region; name := sites[i].name]

# Add to Envoy under "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager]
#   forward_client_cert_details: sanitize_set
#   set_current_client_cert_details:
#       uri: true
