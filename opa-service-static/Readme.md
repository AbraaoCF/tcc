# OPA Policies Repository

This repository contains policies for the Open Policy Agent (OPA). Below you will find instructions on how to run tests, lint the policies, and start the OPA server.

## Prerequisites

- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/docs/latest/getting-started/)
- [Regal](https://github.com/StyraInc/regal) (for linting Rego policies)

This repo contains a binary version of those two on `/bin` - both for `linux-amd64` - you can use them if you prefer.

Remenber to make them executable if needed:

```bash
cd bin
chmod +x opa
chmod +x regal
```

## Running Policy Tests

To run the policy tests located in `policy_test.rego` using the OPA binary, use the following commands:

```bash
cd bin
./opa test .. -v
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
./regal lint ..
```

or, if you are not using the binary:


```bash
regal  .
```

This will check all Rego files in the current directory for linting errors.

## Starting the OPA Server

To start the OPA server, run the following command:

```bash
./opa run  -s --log-level debug --log-format json-pretty ../policies ../data.json
```

```bash
opa run --server
```

This will start the OPA server on the default port `8181`.

## Usage

You can interact with the OPA server using the REST API. For example, to evaluate a policy, you can use `curl`:

```bash
curl -X POST http://localhost:8181/v1/data/example/policy -d '{"input": {}}'
```

Replace `example/policy` with the path to your policy and provide the appropriate input in the data payload.

> There is an full input example on `tests/input.json`
>
## Directory Structure

```
.
├── policies
│   ├── policy.rego
│   ├── policy_routes.rego
├── tests
│   ├── policy_test.rego
│   ├── input.json
├── data.json
└── README.md
```

- `policies/` - Directory containing the Rego policy files.
- `tests/` - Directory containing the Rego testing files.
  - `policy_test.rego` - File containing tests for the policies.
  - `input.json` - Example of input that could be send on curl.
<!-- - `.regal.yml` - Configuration file for Regal linter. -->
- `data.json` - Read-only data passed as default for the opa-server, includes limits configurations.
- `README.md` - This file.

## Contributing

Please open an issue or submit a pull request for any changes or improvements.

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
