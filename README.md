# OPA Policies Repository

This repository contains policies for the Open Policy Agent (OPA). Below you will find instructions on how to  lint the policies, start the OPA server, and run tests.

## Architecture

![architecture](/assets/architecture.png)

## Understanding the policy

To understand the idea configured in this policy access [policy-decisions.md](src/docs/policy-decisions.md).

## Prerequisites

- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/docs/latest/getting-started/)
- [Regal](https://github.com/StyraInc/regal) (for linting Rego policies)

This repo contains a binary version of those two on `/bin` - both for `linux-amd64` - you can use them if you prefer.

Remenber to make them executable if needed:

```bash
chmod +x ./src/bin/opa
chmod +x ./src/bin/regal
```

## Starting the OPA Server

First, enter `src` directory and start our cache REST server with NGINX as reverse proxy:

```bash
cd src
docker-compose -f cache-server/docker-compose.yml up -d --build
```

Then, to start the OPA server, run the following command:

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
```

This will start the OPA server on the default port `8181`, accepting only TLS connections.

## Usage

### Enter input

You can interact with the OPA server using the REST API. For example, to evaluate a policy, you can use `curl`:

```bash
cd tests
curl --key ../tls-config/client-key-1.pem \
  --cert ../tls-config/client-cert-1.pem \
  --cacert  ../tls-config/ca.pem \
  -X POST \
  https://127.0.0.1:8181/v1/data/envoy/authz/allow \
  -d @input.json
```

> If you what to use a specific payload, you can change the `/tests/input.json` file or create a new one to be used.

### Inject data for opa to analyz

It is possible also to inject data to be used by OPA policies, to cover this sccenario it was created an example where an external service can - after detecting an anomaly - add one user to the "black list" so OPA will automatically block them until they are remove from that list.

To test this you can run:

```bash
python3 tests/external-api-tls/user_anomaly.py
# An interface like this should apper:
# Do you want to add or delete a user to the forbidden list? (add/delete): 
# Enter the user ID: 
```

## Directory Structure

```md
src
├── policies
│   ├── certs.json
│   ├── data.json
│   ├── policy.rego
│   ├── policy_routes.rego
│   ├── system_authz.rego
├── tests
│   ├── policy_test.rego
│   ├── input.json
│   ├── external-api-tls
│   │   ├── ca.pem
│   │   ├── client-cert-1.pem
│   │   ├── client-key-1.pem
│   │   ├── user_anomaly.py
```

- `policies/` - Directory containing the Rego policy files.
  - `policy_routes.rego` and `policy.rego` are the policies to be evaluated
  - `system_authz.rego` is the policy to authorize to access OPA server
  - `data.json` - Read-only data passed as default for the opa-server, includes limits configurations.
  - `certs.json` - Certificates used by OPA when calling NGINX through TLS connections for data
- `tests/` - Directory containing the Rego testing files.
  - `policy_test.rego` - File containing tests for the policies.
  - `input.json` - Example of input that could be send on curl.
  - `external-api-tls/` - Example of structure to inject dynamic data for the OPA Server.
<!-- - `.regal.yml` - Configuration file for Regal linter. -->

<!-- ## Running Policy Tests

To run the policy tests located in `policy_test.rego` using the OPA binary, use the following commands:

```bash
cd ../bin
./opa test ../policies -v
```

or, if you are not using the binary:

```bash
opa test .
```

This command will run all the tests in the current directory. -->

## Linting Policies

To lint the policies in the repository using the Regal binary, use the following commands:

```bash
./bin/regal lint policies
```

This will check all Rego files in the current directory for linting errors.

## Contributing

Please open an issue or submit a pull request for any changes or improvements.

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
