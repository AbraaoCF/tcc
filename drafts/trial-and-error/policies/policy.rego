package envoy.authz

import input.attributes.request.http as http_request

default allow = false

rate_limit = 10

allow {
  countr = get_request_count(http_request.headers["x-forwarded-for"])
  print(countr)
  countr < rate_limit
  log_request(http_request.headers["x-forwarded-for"])
}

get_request_count(ip) = counter {
  redisl := http.send({
    "method": "GET",
    "url": sprintf("http://localhost:7379/LRANGE/%s/0/-1", [ip])
  })
  print(redisl.body.LRANGE)
  filtered := result(redisl.body.LRANGE)
  print(filtered)
  counter := count(filtered)
}
now := time.now_ns() / 1000000000 # Current time in seconds

log_request(ip) {
  print(now)
  print(sprintf("http://localhost:7379/RPUSH/%s/%.5f",[ip,now]))
  http.send({
    "method": "GET",
    "url": sprintf("http://localhost:7379/RPUSH/%s/%.5f",[ip,now])
  })
}

# Input: a list of timestamps and the current timestamp
# current_timestamp should be a number, e.g., 1.721857808360869613e+09
# timestamps should be a list of strings, e.g., ["1721857679.86377", "1721857682.73704", "1721857684.41883"]

# Maximum allowed difference in seconds
max_difference = 5  # Adjust this value as needed

# Convert string timestamps to float numbers and filter
result(timestamps) = filtered {
  filtered := [to_number(ts) |
    ts := timestamps[i];
    diff := abs(to_number(ts) - now);
    diff <= max_difference;
    not exceeds_max_difference(timestamps, now, max_difference, i)
  ]
}

# Function to stop iterating once the difference exceeds the max allowed difference
exceeds_max_difference(timestamps, current_timestamp, max_difference, index) {
    some i
    i < index
    timestamps[i] - current_timestamp > max_difference
}
