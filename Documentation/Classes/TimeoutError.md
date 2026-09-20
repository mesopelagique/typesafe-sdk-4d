# TimeoutError

The full response did not arrive within the configured timeout. The timeout covers one
attempt, not the sequence of retries.

Retried by default, through `retryPolicy.retryOnTimeout`.

## Inherits

- [TransportError](TransportError.md)

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `timeoutMs` | Integer | The timeout that was exceeded, in milliseconds. |

`message` reads `Request timed out after <timeoutMs>ms.`
