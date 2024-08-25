package envoy.authz

import rego.v1

route := http_request.path

# Auth
allow_path if {
	regex.match(`^/service/rest/auth$`, route)
	# svc_spiffe_id
}

# Building
allow_path if {
	regex.match(`^/service/rest/building/[^/]+$`, route)
	check_id_building
}

allow_path if {
	regex.match(`^/service/rest/building/[^/]+/sensors$`, route)
	check_id_building
}

allow_path if {
	regex.match(`^/service/rest/building/[^/]+/demands$`, route)
	check_id_building
}

# Consumption
allow_path if {
	regex.match(`^/service/rest/building/[^/]+/demand/last$`, route)
	check_id_consumption
}

allow_path if {
	regex.match(`^/service/rest/building/[^/]+/demand/last_n_minutes$`, route)
	check_id_consumption
}

allow_path if {
	regex.match(`^/service/rest/building/[^/]+/consumption$`, route)
	check_id_consumption
}

allow_path if {
	regex.match(`^/service/rest/building/[^/]+/demandReport$`, route)
	check_id_consumption
}

# Unsupported Media Type
allow_path if {
	regex.match(`^/service/rest/building/[^/]+/consumption/disaggregated$`, route)
	check_id_unsupported
}

# Sensor
allow_path if {
	regex.match(`^/service/rest/sensors$`, route)
	check_id_sensor
}

allow_path if {
	regex.match(`^/service/rest/sensor/[^/]+$`, route)
	check_id_sensor
}

allow_path if {
	regex.match(`^/service/rest/consumptionHistory$`, route)
	check_id_sensor
}

# Statistics
allow_path if {
	regex.match(`^/service/rest/building/[^/]+/statistics$`, route)
	check_id_statistics
}

allow_path if {
	regex.match(`^/service/rest/sensor/[^/]+/statistics$`, route)
	check_id_statistics
}

allow_path if {
	regex.match(`^/service/rest/building/[^/]+/statisticsStatus$`, route)
	check_id_statistics
}

allow_path if {
	regex.match(`^/service/rest/building/[^/]+/periodStatisticsStatus$`, route)
	check_id_statistics
}

allow_path if {
	regex.match(`^/service/rest/building/[^/]+/statistics/alwayson$`, route)
	check_id_statistics
}

# User
allow_path if {
	regex.match(`^/service/rest/user/[^/]+/sensors$`, route)
	check_id_user
}

svc_spiffe_id := client_id if {
	[_, _, uri_type_san] := split(http_request.headers["x-forwarded-client-cert-test"], `;`)
	[_, client_id] := split(uri_type_san, `=`)
}

check_id_building if {
	svc_spiffe_id in data.building_svc
}

check_id_unsupported if {
	svc_spiffe_id in data.unsupported_svc
}

check_id_consumption if {
	svc_spiffe_id in data.consumption_svc
}

check_id_sensor if {
	svc_spiffe_id in data.sensor_svc
}

check_id_statistics if {
	svc_spiffe_id in data.statistics_svc
}

check_id_user if {
	svc_spiffe_id in data.user_svc
}
