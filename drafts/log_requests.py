import json
import time
from collections import defaultdict
import requests

# Configuration
LOG_FILE = '/var/log/envoy/access.log'
OPA_URL = 'http://localhost:8181/v1/data/rate_limits'
RATE_LIMIT_WINDOW = 60  # seconds
MAX_REQUESTS_PER_WINDOW = 100

# Store user request logs
user_request_logs = defaultdict(list)

def process_log_entry(log_entry):
    user = log_entry.get('user')
    if not user:
        return

    timestamp = log_entry.get('timestamp')
    if not timestamp:
        return

    timestamp = time.strptime(timestamp, '%Y-%m-%dT%H:%M:%S.%fZ')
    timestamp = int(time.mktime(timestamp))

    # Remove old entries
    current_time = int(time.time())
    window_start = current_time - RATE_LIMIT_WINDOW
    user_request_logs[user] = [entry for entry in user_request_logs[user] if entry > window_start]

    # Add new entry
    user_request_logs[user].append(timestamp)

    # Update OPA
    update_opa()

def update_opa():
    # Convert defaultdict to regular dict for JSON serialization
    rate_limits = dict(user_request_logs)
    # Update the OPA data store
    response = requests.put(OPA_URL, json={"rate_limits": rate_limits})
    if response.status_code != 200:
        print(f"Failed to update OPA data: {response.status_code}, {response.text}")

def tail_log_file(log_file):
    with open(log_file, 'r') as f:
        f.seek(0, 2)  # Move to the end of the file
        while True:
            line = f.readline()
            if not line:
                time.sleep(1)
                continue
            try:
                log_entry = json.loads(line)
                process_log_entry(log_entry)
            except json.JSONDecodeError:
                continue

if __name__ == "__main__":
    tail_log_file(LOG_FILE)

# This will be helpful if the final decision it is to use only envoy logs, then the envoy logs must follow this:
# - name: envoy.http_connection_manager
#               config:
#                 stat_prefix: ingress_http
#                 access_log:
#                   - name: envoy.file_access_log
#                     typed_config:
#                       "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
#                       path: "/var/log/envoy/access.log"
#                       log_format:
#                         json_format:
#                           user: "%REQ(x-user)%"
#                           path: "%REQ(:path)%"
#                           method: "%REQ(:method)%"
#                           timestamp: "%START_TIME%"
#                 route_config:
#                   name: local_route
#                   virtual_hosts:
#                     - name: local_service
#                       domains: ["*"]
#                       routes:
#                         - match: { prefix: "/" }
#                           route: { cluster: service_cluster }