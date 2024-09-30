## Solução Alternativa 1 com taxa de 350 requisições por segundo, com 1, 2, ou 3 réplicas
```sh
echo "GET https://127.0.0.1:10002/service/rest/building/1/consumption/disaggregated" | \vegeta attack -duration=60s -rate=350 \
-cert=opa-client-cert.pem -key=opa-client-key.pem -root-certs=ca.pem \
-header "x-forwarded-client-cert-test: By=subject=subject;By=issuer;URI=spiffe://acme.com/projeto1" | tee results_opa_static_350.bin | vegeta report
```
