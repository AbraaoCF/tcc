## Solução Proposta com taxa de 300 requisições por segundo, com 800 workers
```sh
echo "GET https://127.0.0.1:10001/service/rest/building/1/consumption/disaggregated" | \vegeta attack -duration=60s -rate=300  -workers=800 \
-cert=opa-client-cert.pem -key=opa-client-key.pem -root-certs=ca.pem \
-header "x-forwarded-client-cert-test: By=subject=subject;By=issuer;URI=spiffe://acme.com/projeto1" | tee results_opa_envoy_300_800.bin | vegeta report
```