# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	 		OPA Policy with Zero Trust Approach 		  #
# 					  Rate Limiting 				  	  #
# 			Author: Abraão Caiana de Freitas   		 	  #
#					(github.com/AbraaoCF) 		    	  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #	# #
#  Some of the features of this policy are:				  #
#														  #
#  - Rate Limiting 										  #
#     - User (disabled by default) 						  #
#			To enable, uncoment the lines 99-101 and 118  #
#     - Endpoint (disabled by default) 					  #
# 			To enable, uncoment the lines 103-105 and 119 #
#     - User/Endpoint (disabled by default) 			  #
#			To enable, uncoment the lines 107-110 and 120 #
#														  #
#  - Rate Limiting with Budget (enabled by default)		  #
#														  #
#  - Night Budget Evaluation (disabled by default) 	  	  #
# 		To enable, the specific project configuration     #
#		must set the night_budget attribute != 0		  #
#														  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

package envoy.authz

import rego.v1

http_request := input.attributes.request.http

rate_limit_user := data.rate_limits_config.user_max_requests_per_window

rate_limit_endpoint := data.rate_limits_config.endpoint_max_requests_per_window

rate_limit_user_endpoint := data.rate_limits_config.user_endpoint_requests_per_window

environment_variables := data.environment_variables

project_config := map_project_config(data.projects_config, svc_spiffe_id)

map_project_config(configs, project) := config if {
	config := configs[project]
} else := config if {
	config := configs["default"]
}

now := time.now_ns() / 1000000000

window_start := now - data.rate_limits_config.time_window_seconds

user_budget := budget if {
	inside_working_hours
	budget := project_config.budget
}

user_budget := budget if {
	not inside_working_hours
	budget := project_config.night_budget
}

inside_working_hours if {
	[hour, _, _] := time.clock(time.now_ns())
	hour >= environment_variables.starting_working_hours
	hour <= environment_variables.ending_working_hours
}

default allow := false

allow := response if {
	svc_spiffe_id == "spiffe://acme.com/admin"
	response := {
		"allowed": true,
		"headers": {"x-ext-authz-check": "allowed"},
		"id": svc_spiffe_id,
		"request_costs": -1,
		"budget_left": -1,
	}
}

allow := response if {
	http_request.method == "GET"
	endpoint := allow_path
	endpoint in data.whitelisted_endpoints
	response := {
		"allowed": true,
		"headers": {"x-ext-authz-check": "allowed"},
		"id": svc_spiffe_id,
		"request_costs": 0,
		"budget_left": -1,
	}
}

allow := response if {
	http_request.method == "GET"
	endpoint := allow_path
	user := svc_spiffe_id
	not user in data.anomalies.users

	# User Rate Limiting
	# user_logs_count := request_count(user, rate_limit_user, window_start)
	# user_logs_count < rate_limit_user

	# Endpoint Rate Limiting
	# endpoint_logs_count := request_count(endpoint, rate_limit_endpoint, window_start)
	# endpoint_logs_count < rate_limit_endpoint

	# User-Endpoint Rate Limiting
	# user_endpoint := sprintf("%s/%s", [user, endpoint])
	# user_endpoint_logs_count := request_count(user_endpoint, rate_limit_user_endpoint, window_start)
	# user_endpoint_logs_count < rate_limit_user_endpoint

	# Budget Rate Limiting
	request_info := process_request_budget(user, endpoint)

    # Escolher a resposta dependendo de exceder ou não o orçamento
    response = choose_response(request_info, user)

	# log_request(user, now)
	# log_request(endpoint, now)
	# log_request(user_endpoint, now)
}


choose_response(request_info, user) = response if {
    not request_info.exceed_budget
    response := {
        "allowed": true,
        "headers": {"x-ext-authz-check": "allowed"},
        "id": user,
        "request_costs": request_info.cost_request,
        "budget_left": request_info.budget_left,
    }
	log_request_budget(request_info.user_id_budget, now, request_info.cost_request)
}

choose_response(request_info, user) = response if {
    request_info.exceed_budget
    response := {
        "allowed": false,
        "http_status": 429,
        "headers": {"x-ext-authz-check": "denied", "x-ext-authz-error": "Budget exceeded"},
        "id": user,
        "request_costs": request_info.cost_request,
        "budget_left": request_info.budget_left,
    }
}

process_request_budget(user, endpoint) = response if {
    user_id_budget := sprintf("%s/budget", [user])
    cost_logs := request_logs_cost(user_id_budget, user_budget, window_start)
    cost_request := data.cost_endpoints[endpoint]
    
    response := {
        "user_id_budget": user_id_budget,
        "cost_logs": cost_logs,
        "cost_request": cost_request,
        "budget_left": user_budget - (cost_logs + cost_request),
        "exceed_budget": cost_logs + cost_request > user_budget
    }
}

ca_cert := data.certs.ca_cert

client_cert := data.certs.client_cert

client_key := data.certs.client_key

request_count(id, size, window_start) := counter if {
	response := http.send({
		"method": "GET",
		"url": sprintf("https://envoy:10004/LRANGE/%s/0/%v", [urlquery.encode(id), size]),
		"headers": {"Content-Type": "application/json"},
		"tls_ca_cert": ca_cert,
		"tls_client_cert": client_cert,
		"tls_client_key": client_key,
	})
	filtered := filter_logs(response.body.LRANGE, window_start)
	counter := count(filtered)
}

request_logs_cost(id, budget, window_start) := total_cost if {
	redisl := http.send({
		"method": "GET",
		"url": sprintf("https://envoy:10005/LRANGE/%s/0/%v", [urlquery.encode(id), budget]),
		"headers": {
			"Content-Type": "application/json",
			"x-timestamp": sprintf("%f", [window_start]),
		},
		"tls_ca_cert": ca_cert,
		"tls_client_cert": client_cert,
		"tls_client_key": client_key,
	})
	total_cost := to_number(redisl.body)
}

log_request_budget(id, timestamp, value) if {
	valor := sprintf("%.5f:%v", [timestamp, value])
	answer := http.send({
		"method": "GET",
		"url": sprintf("https://envoy:10004/LPUSH/%s/%s", [urlquery.encode(id), urlquery.encode(valor)]),
		"headers": {"Content-Type": "application/json"},
		"tls_ca_cert": ca_cert,
		"tls_client_cert": client_cert,
		"tls_client_key": client_key,
	})
}

log_request(id, value) if {
	valuer := http.send({
		"method": "GET",
		"url": sprintf("https://envoy:10004/LPUSH/%s/%.5f", [urlquery.encode(id), value]),
		"headers": {"Content-Type": "application/json"},
		"tls_ca_cert": ca_cert,
		"tls_client_cert": client_cert,
		"tls_client_key": client_key,
	})
}

# Convert string timestamps to float numbers and filter
filter_logs(timestamps, window) := {to_number(ts) | some ts in timestamps; to_number(ts) >= window}

parse(item) := {"timestamp": ts, "cost": cost} if {
	parts := split(item, ":")
	ts = to_number(parts[0])
	cost = to_number(parts[1])
}
