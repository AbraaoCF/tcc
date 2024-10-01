## Solução Proposta com taxa de 10 requisições por segundo, por 5 minutos
```sh
echo "GET https://127.0.0.1:10001/service/rest/building/1/consumption/disaggregated" | \vegeta attack -duration=300s -rate=10  \
-cert=opa-client-cert.pem -key=opa-client-key.pem -root-certs=ca.pem \
-header "x-forwarded-client-cert-test: By=subject=subject;By=issuer;URI=spiffe://acme.com/projeto2" | tee results_projeto2_068.bin | vegeta report
```