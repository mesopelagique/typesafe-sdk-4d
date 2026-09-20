# Result

The base class of the API results. A synchronous call throws on failure, so the result it
returns always has `success` true. An asynchronous call cannot throw into the caller, so it
hands the very same result class to the callback with `success` false and the failure in
`error`.

## Inherited by

- [SystemOneResult](SystemOneResult.md)
- [ModelsListResult](ModelsListResult.md)

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `success` | Boolean | `False` when the call failed. |
| `error` | Variant | The failure, or `Null`. One of the [error classes](TypeSafeError.md). |
| `errors` | Collection | The failure as a one-entry collection, or empty. |
| `status` | Integer | HTTP status code, `0` when no response arrived. |
| `requestId` | Text | The `x-typesafe-request-id` response header, or `""`. |
| `rawBody` | Variant | The response body as it was parsed. |

## Functions

### fail()

**fail**(*error* : Variant) : Result

Records a failure so the caller can read it instead of catching it. Returns `This`.

### throwIfError()

**throwIfError**()

Throws the recorded failure, if any. This is what turns a failed synchronous call into a
`throw`.

#### Example usage:

```4d
// Synchronous: the failure is thrown
Try
	var $result:=$client.systemOne($state; {questions: $questions})
Catch
	ALERT(String(Last errors[0].message))
End try

// Asynchronous: the failure is carried
If ($result.success)
	Form.answers:=$result.answers
Else
	ALERT($result.error.message)
End if
```
