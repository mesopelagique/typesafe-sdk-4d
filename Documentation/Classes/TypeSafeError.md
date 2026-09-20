# TypeSafeError

The base class of the SDK's errors. It carries `errCode` and `message`, so it can be raised
with `throw` and read back from `Last errors`.

A `TypeSafeError` itself is raised for bad configuration and for an empty or malformed
question set, that is, for everything the SDK rejects before reaching the network.

## Inherited by

- [APIError](APIError.md)
- [TransportError](TransportError.md)

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | Text | The class name, `"TypeSafeError"` here. |
| `errCode` | Integer | `1`, or the HTTP status for an [APIError](APIError.md). |
| `message` | Text | What went wrong. |
| `cause` | Variant | The underlying failure, when there is one. |

#### Example usage:

```4d
Try
	var $client:=cs.jev.Client.new()
Catch
	// "No API key was provided. Pass `apiKey` to cs.jev.Client.new() or set the TYPESAFE_API_KEY environment variable."
	ALERT(String(Last errors[0].message))
End try
```
