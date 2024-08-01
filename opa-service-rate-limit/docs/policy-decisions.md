# Policy Decisions Rationale

This module tries to apply [Zero Trust Architecture](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf) principles.
In the following topics we will discuss the rationale behind the decisions.

## Allow Path

The [policy_routes.rego](../policies/policy_routes.rego) file is designed to validate request paths and ensure that only registered `spiffe_id` can access specific group routes. The routes are divided into the following groups: `building_svc`, `consumption_svc`, `unsupported_svc`, `sensor_svc`, `statistics_svc`, and `user_svc`.

To enhance security, we can add a more specific check for individual endpoints. This involves registering IDs for the endpoints in the [`data.json`](../policies/data.json) file and incorporating an additional check within the respective function. This approach increases the granularity of the policy, ensuring more precise access control.


## Rate Limits

Regarding rate limits, it was used [OPA Data API](https://www.openpolicyagent.org/docs/latest/philosophy/#the-opa-document-model) to call a Rest API for our Redis instance. The configuration is defined on the [`data.json`](../policies/data.json). Four rate limits policies were created, one implementing a budget mechanism that we will go in details below and three of them implement a simple method of amount of request per window:

- <b> Rate Limit User</b>: Defines how much requests a user can make independetly of the endpoint.
- <b> Rate Limit Endpoint</b>: Defines how much request a endpoint can receive independently of the user.
- <b> Rate Limit User-Endpoint</b>: Defines how much a user can call a request on a specific endpoint.

### Rate Limit With User Budget and Endpoint Costs

This approach recognizes that some endpoints are more CPU-intensive than others. To protect the system from users who might be unaware of the resource constraints, a **budget per user** strategy was implemented.

#### Budget Per User Strategy

- **CPU Coins**: Each user is allocated a certain amount of **CPU coins** to spend within a defined time window.
- **Endpoint Costs**: Each endpoint has an associated cost in **CPU coins**.
- **Budget Management**: Every time a user calls a specific endpoint, their available budget decreases by the endpoint's cost. This ensures that users cannot exceed their allocated CPU resources within the time window.

By applying this strategy, the system can better manage CPU resources and prevent any single user from monopolizing CPU capacity, thereby maintaining overall system performance and stability.

## Night Mode

To account for the environmental aspects of the infrastructure, a `night_mode` flag was created in the `projects_config` in [`data.json`](../policies/data.json) to determine if a project has higher demand outside working hours. 

- **Outside Working Hours**: If `night_mode` is enabled and it is outside working hours, the project's budget increases by 20%.
- **During Working Hours**: If `night_mode` is enabled and it is within working hours, the project's budget decreases to 70%.

This ensures that projects with higher throughput needs outside of normal working hours can take advantage of the reduced system load, while those that do not require high demand during these times are budget-restricted to prevent abnormal behavior when no system administrator is available to monitor them.
