# OPA Policies Repository

This repository contains policies for the Open Policy Agent (OPA). Below you will find instructions on how to run tests, lint the policies, and start the OPA server.

## Understanding the policy
To understand the idea configure in this policy access [policy-decisions.md](docs/policy-decisions.md)

## Prerequisites

- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/docs/latest/getting-started/)
- [Regal](https://github.com/StyraInc/regal) (for linting Rego policies)
- [Webdis](https://github.com/nicolasff/webdis?tab=readme-ov-file)

This repo contains a binary version of those two on `/bin` - both for `linux-amd64` - you can use them if you prefer.

Remenber to make them executable if needed:

```bash
cd bin
chmod +x opa
chmod +x regal
```

## Starting the OPA Server

To start the OPA server, run the following command:

```bash
./opa run  -s --log-level debug --log-format json-pretty ../policies
```

or, if you are not using the binary, do:

```bash
opa run --server
```

This will start the OPA server on the default port `8181`.

## Usage

You can interact with the OPA server using the REST API. For example, to evaluate a policy, you can use `curl`:

```bash
cd tests
curl -X POST http://localhost:8181/v1/data/envoy/authz -d @input.json'
```

> If you what to use a specific payload, you can change the `/tests/input.json` file or create a new one to be used.

## Directory Structure

```
.
├── policies
│   ├── data.json
│   ├── policy.rego
│   ├── policy_routes.rego
├── tests
│   ├── policy_test.rego
│   ├── input.json
└── README.md
```

- `policies/` - Directory containing the Rego policy files.
- `tests/` - Directory containing the Rego testing files.
  - `policy_test.rego` - File containing tests for the policies.
  - `input.json` - Example of input that could be send on curl.
<!-- - `.regal.yml` - Configuration file for Regal linter. -->
  - `data.json` - Read-only data passed as default for the opa-server, includes limits configurations.
- `README.md` - This file.

## Running Policy Tests

First, start our cache REST server:
```bash
docker run --name webdis-test --rm -d -p 127.0.0.1:7379:7379 nicolas/webdis
```
To run the policy tests located in `policy_test.rego` using the OPA binary, use the following commands:

```bash
cd bin
./opa test ../policies -v
```

or, if you are not using the binary:

```bash
opa test .
```

This command will run all the tests in the current directory.

## Linting Policies

To lint the policies in the repository using the Regal binary, use the following commands:

```bash
cd bin
chmod +x regal
./regal lint ../policies
```

or, if you are not using the binary:


```bash
regal  .
```

This will check all Rego files in the current directory for linting errors.

## Contributing

Please open an issue or submit a pull request for any changes or improvements.

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
