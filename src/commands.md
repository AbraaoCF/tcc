# Commands

```bash
./bin/opa run  -s policies \
 --log-level debug \
 --log-format json-pretty \
  --tls-cert-file tls-config/server-cert.pem \
  --tls-private-key-file tls-config/server-key.pem \
 --tls-ca-cert-file tls-config/ca.pem \
 --authentication=tls \
 --authorization=basic \
 -a https://127.0.0.1:8181 

 curl --key ../tls-config/client-key-1.pem \
  --cert ../tls-config/client-cert-1.pem \
  --cacert  ../tls-config/ca.pem \
  -X POST \
  https://127.0.0.1:8181/v1/data/envoy/authz/allow \
  -d @input.json

  curl --key ../tls-config/opa-client-key.pem \
  --cert ../tls-config/opa-client-cert.pem \  
  --cacert  ../tls-config/ca.pem \
  https://127.0.0.1:443/LPUSH/spiffe%3A%2F%2Facme.com%2Fprojeto1%2Fbudget/%7B1722440579.83461%3A8%7D

```

[docs tls](https://www.openpolicyagent.org/docs/latest/security/#tls-based-authentication-example)

