# RetryPolicy

The `RetryPolicy` class holds what is retried and how long the SDK waits between attempts.
The [Client](Client.md) owns one, built from its `retry` option; a call that carries its own
`retry` object gets a [clone](#clone) with those overrides applied, so the client's policy is
never touched.

HTTP 408, 429 and every 5xx are retried, as are connection errors and timeouts. Delays use
capped exponential backoff with jitter, and honour a server delay when the response carries
one within `maxRetryAfterMs`.

Asynchronous calls do not retry.

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `maxRetries` | Integer | `2` | Retries after the first attempt; `0` disables them. |
| `backoffInitialMs` | Integer | `500` | First backoff delay, doubled up to `backoffMaxMs`. |
| `backoffMaxMs` | Integer | `5000` | Longest backoff delay. |
| `backoffJitter` | Real | `0.25` | Fraction of each delay randomly subtracted, from 0 to 1. |
| `httpStatuses` | Collection | `408`, `429`, `500`–`599` | Status codes that are retried. |
| `respectRetryAfter` | Boolean | `True` | Honour `retry-after-ms` and `Retry-After`. |
| `maxRetryAfterMs` | Integer | `60000` | Longest server delay accepted; beyond it, backoff is used. |
| `retryOnConnectionError` | Boolean | `True` | Retry a request that could not reach the API. |
| `retryOnTimeout` | Boolean | `True` | Retry a request that timed out. |

### Class constructor

**new**(*overrides* : Object) : RetryPolicy

Builds the default policy, then applies *overrides*. Unknown properties are ignored.

```4d
var $policy:=cs.jev.RetryPolicy.new({maxRetries: 4; backoffInitialMs: 250})
```

## Functions

### apply()

**apply**(*overrides* : Object) : RetryPolicy

| Parameter | Type | Description |
|-----------|------|-------------|
| *overrides* | Object | Any of the properties above. |
| Function result | RetryPolicy | `This`, so calls can be chained. |

Merges and validates *overrides* in place. Throws a [TypeSafeError](TypeSafeError.md) for a
negative delay, a `maxRetries` that is not a whole number, a jitter outside 0…1, or a status
code outside 100…999.

### clone()

**clone**() : RetryPolicy

A detached copy, so per-call overrides never reach the client's policy.

### isRetryableStatus()

**isRetryableStatus**(*status* : Integer) : Boolean

Whether the policy retries an HTTP status code.

### delayMs()

**delayMs**(*attempt* : Integer; *headers* : Object) : Integer

| Parameter | Type | Description |
|-----------|------|-------------|
| *attempt* | Integer | Zero-based number of the attempt that just failed. |
| *headers* | Object | Response headers, or `Null` when there was no response. |
| Function result | Integer | Milliseconds to wait. |

An accepted server delay, otherwise capped exponential backoff with jitter.

### parseRetryAfterMs()

**parseRetryAfterMs**(*headers* : Object) : Integer

Reads `retry-after-ms`, then `Retry-After` as seconds or as an HTTP-date, into milliseconds.
Returns `-1` when neither header carries a usable delay.

### sleep()

**sleep**(*ms* : Integer)

Blocks the current process for *ms* milliseconds. 4D has no asynchronous wait, which is why
asynchronous calls do not retry.
