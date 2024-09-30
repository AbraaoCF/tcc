## Solução Alternativa 1 com taxa de 300 requisições por segundo, com 60 workers
```sh
echo "GET https://127.0.0.1:10002/service/rest/building/1/consumption/disaggregated" | \vegeta attack -duration=60s -rate=300  -workers=60 \
-cert=opa-client-cert.pem -key=opa-client-key.pem -root-certs=ca.pem \
-header "x-forwarded-client-cert-test: By=subject=subject;By=issuer;URI=spiffe://acme.com/projeto1" | tee results_opa_static_300_60.bin | vegeta report
```