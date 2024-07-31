# Policy Decisions

This module tries to apply [Zero Trust](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf).
Int the following topics we will discuss the rationale behind the decisions.

## Allow Path

The [policy_routes.rego](../policies/policy_routes.rego) file has the only objective to validate the path on the request and make sure only the registered spiffe_id can access that group route. It was divided in these groups: building_svc, consumption_svc, unsupported_svc, sensor_svc, statistics_svc and user_svc. 

> It can be even more restrictive, we can add a more specific check for a singloe endpoint. To do this, this endpoint must have some ids registered on the [data.json](../policies/data.json) file and we just add another check in its respective function. This should add more granularity to the policy.

## Night Mode

Taking in account the environmental aspects of the infrastructure, this flag was created to determine if a project has or not a higher demand outside working hours. If it does not, we restrict its limit to avoid anormal behavior when there is no system admin to check. On the other hande, if it is a project the has a higher throughput that does not need to be addressed during the working house, it is good for it to run when there is less services accessing the system.

If `night_mode` is enable on the `projects_config` in [data.json](../policies/data.json), when it is outside working hours its budget increases 20%, if not it decreases to 70% .