# ModelsListResult

The result of `GET /v1/models`, returned by [`Models.list()`](Models.md#list) and
[`Client.list_models()`](Client.md#list_models).

## Inherits

- [Result](Result.md)

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `models` | Collection of [ModelCard](ModelCard.md) | The models available to the account. |

A response that does not carry a `models` collection fails the result with a
[TypeSafeError](TypeSafeError.md), which a synchronous call then throws.
