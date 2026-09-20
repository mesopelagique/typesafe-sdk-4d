# APIError

An unsuccessful HTTP response from the API, raised once the retries are spent.

## Inherits

- [TypeSafeError](TypeSafeError.md)

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `status` | Integer | The HTTP status code. Also copied into `errCode`. |
| `body` | Variant | The response body, parsed when it was JSON. |
| `headers` | Object | The response headers. |
| `url` | Text | The URL that was called. |
| `requestId` | Text | The `x-typesafe-request-id` response header, or `""`. |
| `retryAfterMs` | Integer | The server's retry delay in milliseconds, `-1` when the response carries none. |

`message` is derived from the body when the server sends one, as `<status> <detail>`, reading
`error`, `error.message`, `message` or `detail`, including a collection of validation errors.
Otherwise it holds the raw body, truncated to 200 characters.

## Functions

Each of these reports one status; they save you comparing `status` by hand.

| Function | True for |
|----------|----------|
| `isBadRequest()` | 400 |
| `isAuthentication()` | 401 |
| `isPermissionDenied()` | 403 |
| `isNotFound()` | 404 |
| `isTimeout()` | 408 |
| `isUnprocessable()` | 422 |
| `isRateLimit()` | 429 |
| `isServer()` | 500 to 599 |

#### Example usage:

```4d
Try
	var $result:=$client.systemOne($state; {questions: $questions})
Catch
	var $error:=Last errors[0]
	If (OB Instance of($error; cs.jev.APIError) && $error.isRateLimit())
		LOG EVENT(Into system standard outputs; "rate limited, retry after "+String($error.retryAfterMs)+"ms\n")
	End if
End try
```
