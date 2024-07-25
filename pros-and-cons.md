# Pros and Cons

## Pros

## Cons

- If between the policy and the cache occur network erros, either will not retrieve the logs and the list will be empty, so every request will pass by; or it will not update the cache with a new log and it will be possible to exceed the rate limit configured.
  - For the second scenario, a possible solution is to configure the limits below the max intended, leaving a small gap for network errors on update operations.
  - Even so, if the cache and the evaluator are in the same network, using docker for e.g, this should not occur too often. 
  - Check what happens with high throughput.