# Use an official OPA image as the base
FROM openpolicyagent/opa:latest-envoy

# Set the working directory
WORKDIR /app

# Command to run the OPA server with the specified options
CMD ["run", "-s",\
     "--set=decision_logs.console=true", \
     "policies", \
     "--log-level", "debug", \
     "--log-format", "json-pretty", \
     "--tls-cert-file", "tls/server-cert.pem", \
     "--tls-private-key-file", "tls/server-key.pem", \
     "--tls-ca-cert-file", "tls/ca.pem", \
     "--authentication=tls", \
     # "--authorization=basic", \
     "-a", ":8181" , \
     "--set=plugins.envoy_ext_authz_grpc.addr=:9002"]
