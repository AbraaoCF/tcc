## Solução Proposta com taxa de 350 requisições por segundo
```sh
echo "GET https://127.0.0.1:10001/service/rest/building/1/consumption/disaggregated" | \vegeta attack -duration=60s -rate=350 \
-cert=opa-client-cert.pem -key=opa-client-key.pem -root-certs=ca.pem \
-header "x-forwarded-client-cert-test: By=subject=subject;By=issuer;URI=spiffe://acme.com/projeto1" | tee results_opa_envoy_350.bin | vegeta report
```