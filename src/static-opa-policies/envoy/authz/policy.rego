# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#	 		OPA Policy with Zero Trust Approach 		  #
#    	  Rate Limiting (without http_requests)			  #
# 			Author: Abraão Caiana de Freitas   		 	  #
#					(github.com/AbraaoCF) 		    	  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # #	# #
#  Some of the features of this policy are:				  #
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
	not outside_working_hours
	budget := project_config.budget
}

user_budget := budget if {
	outside_working_hours
	budget := project_config.night_budget
}

outside_working_hours if {
	[hour, _, _] := time.clock(time.now_ns())
	not hour >= environment_variables.starting_working_hours
	not hour <= environment_variables.ending_working_hours
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

	# Budget Rate Limiting
	user_id_budget := sprintf("%s/budget", [user])
	cost_logs := request_logs_cost(user_id_budget, user_budget, window_start)
	cost_request := data.cost_endpoints[endpoint]
	cost_logs + cost_request < user_budget

	response := {
		"allowed": true,
		"headers": {"x-ext-authz-check": "allowed"},
		"id": user,
		"request_costs": cost_request,
		"budget_left": user_budget - (cost_logs + cost_request),
	}
}

request_logs_cost(id, budget, window_start) := total_cost if {
	# filtered_costs := [parse(item).cost | some item in data.timestamps_user[id]; parse(item).timestamp > window_start]
	total_cost := data.costs_user[id]
}

# Convert string timestamps to float numbers and filter
# filter_logs(timestamps, window) := {to_number(ts) | some ts in timestamps; to_number(ts) >= window}

parse(item) := {"timestamp": ts, "cost": cost} if {
	parts := split(item, ":")
	ts = to_number(parts[0])
	cost = to_number(parts[1])
}
