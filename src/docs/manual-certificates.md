# Manual Certificates
This document provides a step-by-step guide to manually generate certificates for the services to use for TLS communication. The certificates are generated using the `openssl` command-line tool. For a production environment, it is recommended to use a certificate authority (CA) to sign the certificates. However, for this guide, we will use our own CA to sign the certificates.

The directory already contains the TLS configuration (certs and keys) for the services, but they are probably expired (If used after October, 2024). If you want to generate new certificates, follow the steps below.

## Prerequisites
- `openssl` command-line tool installed on your machine.

## Step 1: Generate a Certificate Authority (CA)
The first step is to generate a Certificate Authority (CA) that will be used to sign the certificates for the services. 

First, go to the opa-tls-config directory:

```bash
cd src/tls/opa-tls-config
```

Run the following command to generate a CA key and certificate:

```bash
openssl ecparam -out ca-key.pem -name prime256v1 -genkey 
openssl req -x509 -new -nodes -key ca-key.pem -days 90 -out ca.pem -subj "/CN=my-ca"
```

This command generates a CA key (`ca-key.pem`) and a CA certificate (`ca.pem`) valid for 90 days.

## Step 2: Generate a Certificate for each Service

### Step 2.1: OPA Service
#### Step 2.1.1: Generate a Key and Cert for the Service OPA as client
Run the following command to generate a key and certificate for the OPA as Client:

```bash
cat <<EOF >req.cnf         
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
basicConstraints = CA:FALSE
subjectAltName = @alt_names

[alt_names]
URI.1 = spiffe://example.com/opa-client
EOF                                                         
openssl ecparam -out opa-client-key.pem -name prime256v1 -genkey 
openssl req -new -key opa-client-key.pem -out csr.pem -subj "/CN=opa-client" -config req.cnf
openssl x509 -req -in csr.pem -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out opa-client-cert.pem -days 90 -extensions v3_req -extfile req.cnf -sha256
``` 

#### Step 2.1.2: Generate a Key and Cert for the Service OPA as server
Run the following command to generate a key and certificate for the OPA as Server:

```bash
cat <<EOF >req.cnf         
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]
CN = ext_authz-opa-service

[req_ext]
subjectAltName = @alt_names

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ext_authz-opa-service
IP.1 = 127.0.0.1
URI.1 = spiffe://example.com/ext_authz-opa-service
EOF
openssl ecparam -out server-key.pem -name prime256v1 -genkey
openssl req -new -key server-key.pem -out csr.pem -subj "/CN=ext_authz-opa-service" -config req.cnf
openssl x509 -req -in csr.pem -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -days 90 -extensions v3_req -extfile req.cnf -sha256
```

### Step 2.2: Envoy Service
First, go to the envoy-tls-config directory:

```bash
cd ../envoy-tls-config
```
Copy the CA key and certificate to the envoy-tls-config directory:

```bash
cp ../opa-tls-config/ca-key.pem .
cp ../opa-tls-config/ca.pem .
```

Then, run the following command to generate a key and certificate for the Envoy service:

```bash
cat <<EOF >req.cnf         
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
basicConstraints = CA:FALSE
subjectAltName = @alt_names

[alt_names]
URI.1 = spiffe://example.com/envoy-client
EOF                                                         
openssl ecparam -out envoy-client-key.pem -name prime256v1 -genkey 
openssl req -new -key envoy-client-key.pem -out csr.pem -subj "/CN=envoy-client" -config req.cnf 
openssl x509 -req -in csr.pem -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out envoy-client-cert.pem -days 90 -extensions v3_req -extfile req.cnf -sha256
```

### Step 2.3: NGNIX Service
First, go to the nginx-tls-config directory:

```bash
cd ../nginx-tls-config
```

Copy the CA key and certificate to the envoy-tls-config directory:

```bash
cp ../opa-tls-config/ca-key.pem .
cp ../opa-tls-config/ca.pem .
```

Then, run the following command to generate a key and certificate for the NGINX service:

```bash
cat <<EOF >req.cnf         
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]
CN = nginx

[req_ext]                  
subjectAltName = @alt_names

[v3_req]                                 
basicConstraints = CA:FALSE                                 
keyUsage = nonRepudiation, digitalSignature, keyEncipherment       
subjectAltName = @alt_names        

[alt_names]                                                  
DNS.1 = nginx                                                                      
IP.1 = 127.0.0.1                                                                                                                                    
URI.1 = spiffe://example.com/nginx
EOF
openssl ecparam -out server-key.pem -name prime256v1 -genkey
openssl req -new -key server-key.pem -out csr.pem -subj "/CN=nginx" -config req.cnf
openssl x509 -req -in csr.pem -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -days 90 -extensions v3_req -extfile req.cnf -sha256
```

## Usefull links

- TLS-based Authentication Example OPA: https://www.openpolicyagent.org/docs/latest/security/#tls-based-authentication-example