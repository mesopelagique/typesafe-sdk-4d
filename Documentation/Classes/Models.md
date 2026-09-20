# Models

The `Models` class gives access to the Models API resource. An instance is created by the
[Client](Client.md) and reached through its `models` property.

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `client` | [Client](Client.md) | The client that sends the requests. |

## Functions

### list()

**list**(*options* : Object) : Variant

| Parameter | Type | Description |
|-----------|------|-------------|
| *options* | Object | Request options, as in [`Client.systemOne()`](Client.md#systemone). |
| Function result | [ModelsListResult](ModelsListResult.md) or `4D.HTTPRequest` | The models available to the account. |

Lists the models available to the account, through `GET /v1/models`.

#### Example usage:

```4d
var $result:=$client.models.list(Null)

var $card : cs.jev.ModelCard
For each ($card; $result.models)
	LOG EVENT(Into system standard outputs; $card.name+"\n")
End for each
```
