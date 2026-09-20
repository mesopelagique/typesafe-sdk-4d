# Documentation

## Classes

The client and the API resources:

| Class | Role |
|-------|------|
| [Client](Classes/Client.md) | The entry point: configuration, `systemOne()`, `list_models()`. |
| [Models](Classes/Models.md) | The Models API resource, reached through `Client.models`. |
| [Questions](Classes/Questions.md) | Builds and validates question sets. |
| [RetryPolicy](Classes/RetryPolicy.md) | What is retried, and how long the SDK waits. |
| [Logger](Classes/Logger.md) | Level filtering, output, credential redaction. |

The results:

| Class | Role |
|-------|------|
| [Result](Classes/Result.md) | Base class: `success`, `error`, `status`, `requestId`. |
| [SystemOneResult](Classes/SystemOneResult.md) | The answers, the usage, the model. |
| [ModelsListResult](Classes/ModelsListResult.md) | The available models. |
| [ModelCard](Classes/ModelCard.md) | One available model. |

The errors:

| Class | Raised when |
|-------|-------------|
| [TypeSafeError](Classes/TypeSafeError.md) | Base class: bad configuration, malformed questions. |
| [APIError](Classes/APIError.md) | A non-2xx response, once the retries are spent. |
| [TransportError](Classes/TransportError.md) | Base class for delivery failures. |
| [ConnectionError](Classes/ConnectionError.md) | The request could not reach the API. |
| [TimeoutError](Classes/TimeoutError.md) | No response within the timeout. |

## Reference

- [Parity with the JavaScript SDK](parity.md) — what matches, what is deliberately
  4D-shaped, and what is not implemented.
- [README](../README.md) — quickstart, configuration, asynchronous calls, retries.
