# TransportError

The base class for delivery failures: the request or the response body did not make it
through, for a reason that is not an HTTP status. DNS, TLS, a closed connection, a timeout.

## Inherits

- [TypeSafeError](TypeSafeError.md)

## Inherited by

- [ConnectionError](ConnectionError.md)
- [TimeoutError](TimeoutError.md)

## Properties

Those of [TypeSafeError](TypeSafeError.md). `message` falls back to `"Connection error."`
when none is given.
