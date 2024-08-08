## Fine-Grained Access Control (check - utilizando spire)
```
package envoy.authz

import input.attributes.request.http as http_request

default allow = false

# Allow only admin users to access admin endpoints
allow {
    http_request.path == "/admin"
    http_request.method == "GET"
    http_request.headers["x-user-role"] == "admin"
}
```

## Rate Limiting and Throttling (check - utilizando logs)
```
package envoy.authz

import input.attributes.request.http as http_request

default allow = false

rate_limit = {
    "time_window_seconds": 60,
    "max_requests_per_window": 100
}

allow {
    user := http_request.headers["x-user"]
    user_requests := data.rate_limits[user]
    count(user_requests) < rate_limit.max_requests_per_window
}
```
## Dynamic Service Authorization
```
package envoy.authz

import input.attributes.request.http as http_request

default allow = false

allow {
    http_request.headers["x-service-name"] == "service-a"
    http_request.path == "/service-b/resource"
}
``` 

## Mutual TLS and Identity Verification
```
package envoy.authz

import input.attributes.request.http as http_request

default allow = false

allow {
    valid_cert := http_request.tls.client_certificates[0].subject == "CN=service-a"
    valid_cert
    http_request.path == "/secure-endpoint"
}
```

## Context-Aware Access Control (boa perspectiva, easy win)

```
package envoy.authz

import input.attributes.request.http as http_request

default allow = false

allow {
    http_request.path == "/sensitive-resource"
    time := time.now_ns() / 1e9
    hour := (time / 3600) % 24
    hour >= 9  # Start of business hours
    hour <= 17  # End of business hours
}
```
## Behavioral Anomaly Detection
```
package envoy.authz

import input.attributes.request.http as http_request

default allow = false

allow {
    user := http_request.headers["x-user"]
    not data.anomalies[user]
}
```

## Data Exfiltration Prevention
```
package envoy.authz

import input.attributes.request.http as http_request

default allow = false

allow {
    http_request.method == "GET"
    http_request.path == "/download"
    http_request.headers["x-user-role"] == "data-analyst"
    # Log the download attempt
    _ = opa.log("Data download attempt by " + http_request.headers["x-user"])
}
```
## API Gateway Authorization
package envoy.authz

import input.attributes.request.http as http_request

default allow = false

allow {
    api_key := http_request.headers["x-api-key"]
    user_role := data.api_keys[api_key].role
    user_role == "allowed_role"
}
```