# Zero Trust Architecture with OPA Policies approach

This repository proposes a solution using the Open Policy Agent (OPA) as a tool to meet Zero Trust standards. 
## Sumary

- [Motivation](#motivation)
- [Problem Statement](#problem-statement)
- [Caveats and Limitations](#caveats-and-limitations)
- [What was achieved](#what-was-achieved)
- [Architecture](#architecture)
- [Understanding the policy](#understanding-the-policy)
- [Usage](#usage)
  - [Prerequisites](#prerequisites)
  - [Start the system](#start-the-system)
  - [Enter input](#enter-input)
  - [Inject data for OPA evaluation - Optional](#inject-data-for-OPA-evaluation---optional)

## Motivation

The Federal University of Campina Grande (UFCG) is advancing the "PDI in Business Intelligence Applied to University Management" initiative, spearheaded by the Center for Electrical Engineering and Informatics (CEEI) in collaboration with the Planning and Budget Department (SEPLAN) and the Information Technology Service (STI) of the institution. The core objective of this initiative is to leverage advanced data management and analysis techniques, commonly known as business intelligence, to enhance operational efficiency and support data-driven decisions in university management.

In this context, the project aims to provide data for use by faculty and students, enabling its application in development analyses and research, including opportunities for improving campus management. Given the critical nature of the data being utilized and the need for secure and reliable access, the adoption of a Zero Trust Architecture (ZTA) becomes essential.

This thesis proposes the application of a Zero Trust Architecture with an Open Policy Agent (OPA) Policies approach to the API system managing these datasets. By implementing ZTA principles, the project aims to ensure that data is protected from unauthorized access and misuse while maintaining flexibility for academic and research purposes. The use of OPA will allow for dynamic and context-aware policy enforcement, which is crucial for maintaining security in an environment that facilitates broad data access and collaboration.

## What is Zero Trust Architecture (ZTA)?

Zero Trust Architecture (ZTA) is a security model based on the principle of "never trust, always verify." In a ZTA environment, all users, devices, and applications are considered untrusted by default, regardless of their location or network status. Access to resources is granted based on strict verification of identity, context, and behavior, rather than relying on traditional network perimeters or trust boundaries.

ZTA aims to improve security by reducing the attack surface, minimizing the risk of unauthorized access, and preventing lateral movement by threat actors. By implementing fine-grained access controls, continuous monitoring, and dynamic policy enforcement, ZTA helps organizations protect critical assets and data from internal and external threats.

## Problem Statement

In the context of the "PDI in Business Intelligence Applied to University Management" initiative, the system receives data from Envoy, utilizing SPIFFE IDs to authenticate clients. However, the current setup presents several challenges in managing access control and resource usage effectively. Specifically, Envoy lacks built-in mechanisms for implementing fine-grained rate limiting, which is essential for distinguishing between legitimate and potentially malicious users.

The inability to enforce rate limits at a more granular level could result in good users being unfairly restricted, while bad actors might still exploit the system. This problem is further compounded by the fact that different API endpoints have varying resource costs, with some being significantly more CPU-intensive than others. Consequently, a one-size-fits-all approach to rate limiting is insufficient.

To address these issues, this thesis proposes the integration of Open Policy Agent (OPA) into the system. OPA offers a fast, straightforward, and contextless solution for fine-grained authorization, allowing for more precise control over user access based on their SPIFFE ID and environment informations. Additionally, OPA's flexibility and minimal infrastructure requirements make it an ideal choice for enhancing security and resource management without the need for a complex architectural overhaul.

By leveraging OPA, the system can implement dynamic, context-aware policies that consider both the identity of the user and the specific API endpoint being accessed. This approach aims to optimize resource usage while ensuring that legitimate users can continue to access the system without unnecessary restrictions, ultimately contributing to the overall effectiveness of the business intelligence initiative.

## Caveats and Limitations

The proposed solution aims to achieve Zero Trust Architecture (ZTA) by integrating Open Policy Agent (OPA) into the system. However, there are several caveats and limitations to consider when implementing this approach:

<!-- - **Complexity**: Implementing OPA policies requires a deep understanding of the system's architecture, data flow, and security requirements. Developing and maintaining policies can be complex and time-consuming, especially for large and dynamic systems. -->

- **Policy Enforcement**: OPA policies must be carefully designed and tested to ensure that they accurately reflect the desired security and access control requirements. Inadequate or incorrect policies can lead to unauthorized access or resource misuse.

<!-- - **Resource Usage**: OPA policies can consume system resources, such as memory and CPU, especially when evaluating complex policies or handling a large number of requests. Monitoring and managing resource usage are essential to prevent performance degradation. -->

- **Scalability**: OPA's scalability depends on the underlying infrastructure and the complexity of the policies being evaluated. Large-scale systems may require additional resources and optimization to ensure that OPA can handle the workload effectively.

- **HTTPS Request to Cache**: The system requires HTTPS requests to the cache server to be able to access the data. This can be a limitation if the system is not properly configured to handle HTTPS requests. In our case, we used NGINX as a reverse proxy to handle the HTTPS requests to the cache server. Also, the cache choosed was Redis, which does not have built-in HTTPS support on the free version, so we used Webdis as HTTP interface to Redis.
    - **Alternative Approach**: We can eliminate the need for HTTP requests to the cache server by storing the data in OPA's internal data store, with some service injecting data. This approach would make the policy evaluation must faster by reducing the need for external HTTP requests, but it would require proper development and maintenance of the data injection service. This project has an example of how to inject data dynamically to the OPA server, but it would be the user responsibility to implement a secure and reliable service to do so.

- **Envoy-OPA Communication**: The communication between Envoy and OPA is done through gRPC, however, the OPA plugin for Envoy does not enforce gRPC over TLS. This can be a limitation if the system requires secure communication between Envoy and OPA. 

## What was achieved

Throughout this project, several key achievements were made in implementing a Zero Trust Architecture (ZTA) with Open Policy Agent (OPA) to enhance the security and access control of the API system managing datasets. 

Firstly, the motivation behind the project was addressed by leveraging advanced data management and analysis techniques by adopting ZTA principles and integrating OPA, the project aimed to ensure the protection of critical data from unauthorized access and misuse while maintaining flexibility for academic and research purposes.

 - **Rate limit with budget per user and endpoint cost**s: The project implemented a rate-limiting strategy that allocates CPU coins to users and associates costs with API endpoints. This approach ensures that users cannot exceed their allocated CPU resources within a defined time window, thereby preventing resource monopolization and maintaining system performance and stability.

 - **Environment-aware budget management**: To account for environmental aspects, a "night mode" feature was implemented to adjust project budgets based on working hours. Projects with higher throughput needs outside normal working hours can take advantage of reduced system load, while those with lower demand during these times are budget-restricted to prevent abnormal behavior.

 - **Fine-grained access control**: The project implemented fine-grained access control policies based on SPIFFE IDs and API endpoints. By enforcing strict verification of identity and context, the system can prevent unauthorized access and misuse of resources, reducing the risk of security breaches and data loss.

 - **Dynamic and responsive security policies**: Anomalies can be detected by an external service and pushed to OPA for real-time access control adjustments. By allowing external systems to interact with OPA and adjust policies based on observed behaviors, the system can adapt to changing contexts and behaviors, enhancing overall security and responsiveness.

## Architecture

This is the propposed architecture:

![architecture](/assets/architecture.png)

## Understanding the policy

To understand the rationale behind the policy decisions and what do they cover go to [policy-decisions.md](src/docs/policy-decisions.md).

## Usage

### Prerequisites

 - Docker ([How to install docker](https://docs.docker.com/engine/install/))
 - Properly setup TLS certificates ([manual-certificates.md](/src/docs/manual-certificates.md))

### Start the system

To start the system just use docker and run the following comand on the root directory:

```bash
docker-compose up --build -d
```

This should run the following containers and its respective ports:
 - ext_authz-opa-service: `8181:8181` used to inject data and `9002:9002` used for gRPC communication
 - static-opa: `8282:8282` used to inject data and `9003:9003` used for gRPC communication
 - envoy: `10000:10000` 
 - nginx: `443:443`
 - hello-word service: `5678:5678`
 - webdis: `7379:7379`

### Enter input

With everything setup, we now can call the Envoy on port `10000` to make some request to the API, here is an example command using `curl`:
```bash
curl --cert src/tls/opa-tls-config/opa-client-cert.pem --key src/tls/opa-tls-config/opa-client-key.pem --cacert src/tls/opa-tls-config/ca.pem https://127.0.0.1:10000/service/rest/building/1/consumption/disaggregated -H "x-forwarded-client-cert-test: By=subject=subject;By=issuer;URI=spiffe://acme.com/projeto1" --verbose
```

<!-- > If you what to use a specific payload, you can change the `/tests/input.json` file or create a new one to be used. -->

### Inject data for OPA evaluation - Optional

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
├── cache-server
├── opa-policies
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
├── bin
├── docs
│   ├── manual-certificates.md
│   ├── policy-decisions.md
|   ├── tls 
│   │   ├── envoy-tls-config
│   │   ├── opa-tls-config
|   |   ├── nginx-tls-config
```

- `opa-policies/` - Directory containing the Rego policy files.
  - `policy_routes.rego` and `policy.rego` are the policies to be evaluated
  - `system_authz.rego` is the policy to authorize to access OPA server
  - `data.json` - Read-only data passed as default for the opa-server, includes limits configurations.
  - `certs.json` - Certificates used by OPA when calling NGINX through TLS connections for data
- `tests/` - Directory containing the Rego testing files.
  - `policy_test.rego` - File containing tests for the policies.
  - `input.json` - Example of input that could be send on curl.
  - `external-api-tls/` - Example of structure to inject dynamic data for the OPA Server.

## Contributing

Please open an issue or submit a pull request for any changes or improvements.

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
