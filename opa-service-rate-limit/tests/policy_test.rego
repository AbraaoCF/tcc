package envoy.authz_test

import data.envoy.authz as policy
import rego.v1

rate_limits_config := {
	"time_window_seconds": 60,
	"max_requests_per_window": 100,
}

building_svc := [
	"spiffe://acme.com/projeto1",
	"spiffe://acme.com/projeto2",
]

consumption_svc := [
	"spiffe://acme.com/projeto1",
	"spiffe://acme.com/projeto2",
]

unsupported_svc := [
	"spiffe://acme.com/projeto1",
	"spiffe://acme.com/projeto2",
]

sensor_svc := [
	"spiffe://acme.com/projeto1",
	"spiffe://acme.com/projeto2",
]

statistics_svc := [
	"spiffe://acme.com/projeto1",
	"spiffe://acme.com/projeto2",
]

user_svc := [
	"spiffe://acme.com/projeto1",
	"spiffe://acme.com/projeto2",
]

timestamps_user := {
	"spiffe://acme.com/projeto1": ["1721397028", "1721397018", "1721397015"],
	"spiffe://acme.com/projeto2": ["1721397028", "1721397018", "1721397015", "1721397015"],
	"spiffe://acme.com/projeto3": ["1721397028", "1721397018", "1721397015"],
}

with_inputs(http_request) if {
	policy.allow with input.attributes.request.http as http_request
		with data.rate_limits_config as rate_limits_config
		with data.timestamps_user as timestamps_user
		with data.building_svc as building_svc
		with data.consumption_svc as consumption_svc
		with data.unsupported_svc as unsupported_svc
		with data.sensor_svc as sensor_svc
		with data.statistics_svc as statistics_svc
		with data.user_svc as user_svc
}

test_rate_limits_forbidden if {
	path := "/service/rest/auth"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto2"}
	http_request := {"path": path, "method": method, "headers": headers}

	new_rate_limit_config := {
		"time_window_seconds": 60,
		"max_requests_per_window": 0,
	}
	not policy.allow with input.attributes.request.http as http_request
		with data.rate_limits_config as new_rate_limit_config
		with data.timestamps_user as timestamps_user
		with data.building_svc as building_svc
		with data.consumption_svc as consumption_svc
		with data.unsupported_svc as unsupported_svc
		with data.sensor_svc as sensor_svc
		with data.statistics_svc as statistics_svc
		with data.user_svc as user_svc
}

############ Routes ############

## Admin
test_admin_allowed if {
	path := "/service/rest/auth"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/admin"}
	http_request := {"path": path, "method": method, "headers": headers}

	with_inputs(http_request)
}

## Auth
test_auth_allowed if {
	path := "/service/rest/auth"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto2"}
	http_request := {"path": path, "method": method, "headers": headers}

	with_inputs(http_request)
}

## Building
test_get_buildling_allowed if {
	path := "/service/rest/building/1"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto2"}
	http_request := {"path": path, "method": method, "headers": headers}

	with_inputs(http_request)
}

test_get_buildling_forbidden if {
	path := "/service/rest/building/1"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto3"}
	http_request := {"path": path, "method": method, "headers": headers}

	not with_inputs(http_request)
}

## Consumption
test_get_consumption_allowed if {
	path := "/service/rest/building/1/consumption"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto2"}
	http_request := {"path": path, "method": method, "headers": headers}

	with_inputs(http_request)
}

test_get_consumption_forbidden if {
	path := "/service/rest/building/1/consumption"
	method := "GET"
	headers := {"x-forwarded-cient-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto3"}
	http_request := {"path": path, "method": method, "headers": headers}

	not with_inputs(http_request)
}

## Unsupported
test_get_unsupported_allowed if {
	path := "/service/rest/building/1/consumption/disaggregated"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto1"}
	http_request := {"path": path, "method": method, "headers": headers}

	with_inputs(http_request)
}

test_get_unsupported_forbidden if {
	path := "/service/rest/building/1/consumption/disaggregated"
	method := "GET"
	headers := {"x-forwarded-cient-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto3"}
	http_request := {"path": path, "method": method, "headers": headers}

	not with_inputs(http_request)
}

## Sensor
test_get_sensor_allowed if {
	path := "/service/rest/consumptionHistory"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto2"}
	http_request := {"path": path, "method": method, "headers": headers}

	with_inputs(http_request)
}

test_get_sensor_forbidden if {
	path := "/service/rest/consumptionHistory"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto3"}
	http_request := {"path": path, "method": method, "headers": headers}

	not with_inputs(http_request)
}

## Statistics
test_get_statistics_allowed if {
	path := "/service/rest/building/1/statistics"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto2"}
	http_request := {"path": path, "method": method, "headers": headers}

	with_inputs(http_request)
}

test_get_statistics_forbidden if {
	path := "/service/rest/building/1/statistics"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto3"}
	http_request := {"path": path, "method": method, "headers": headers}

	not with_inputs(http_request)
}

## User
test_get_user_allowed if {
	path := "/service/rest/user/1/sensors"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto2"}
	http_request := {"path": path, "method": method, "headers": headers}

	with_inputs(http_request)
}

test_get_user_forbidden if {
	path := "/service/rest/user/1/sensors"
	method := "GET"
	headers := {"x-forwarded-client-cert": "By=subject=<subject>;By=<issuer>;URI=spiffe://acme.com/projeto3"}
	http_request := {"path": path, "method": method, "headers": headers}

	not with_inputs(http_request)
}
