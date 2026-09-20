# ConnectionError

The request could not reach the API.

`4D.HTTPRequest` does not say whether a failed delivery ran out of time, so the SDK decides
from the elapsed time: past the configured timeout the failure is a
[TimeoutError](TimeoutError.md), otherwise it is a `ConnectionError`.

Retried by default, through `retryPolicy.retryOnConnectionError`.

## Inherits

- [TransportError](TransportError.md)

## Properties

Those of [TypeSafeError](TypeSafeError.md). `message` quotes the underlying 4D error when
there is one, as `Connection error: <message>`.
