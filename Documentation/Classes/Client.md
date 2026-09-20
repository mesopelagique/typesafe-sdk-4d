# Client

The `Client` class is the entry point of the SDK. It holds the API key, the base URL, the
default model, the timeout, the retry policy and the logger, and it sends the requests.

Each setting is resolved from the explicit option first, then the environment, then the SDK
default.

```4d
var $client:=cs.jev.Client.new()
```

## Configuration properties

| Property Name | Type | Description |
|---------------|------|-------------|
| `apiKey` | Text | Your TypeSafe AI API key. |
| `baseURL` | Text | API root, without its trailing slashes. |
| `model` | Text | Model used when a request does not name one. |
| `timeoutMs` | Integer | Timeout per attempt, in milliseconds. |
| `maxRetries` | Integer | Retries after the first attempt, mirroring `retryPolicy.maxRetries`. |
| `logLevel` | Text | `debug`, `info`, `warn`, `error` or `off`. |
| `logger` | [Logger](Logger.md) | The logger, filtered to `logLevel`. |
| `retryPolicy` | [RetryPolicy](RetryPolicy.md) | Retry settings for every call of this client. |
| `defaultHeaders` | Object | Headers added to every request. |
| `models` | [Models](Models.md) | Access to the Models API. |
| `requestCount` | Integer | Requests started by this client, used to number the log lines. |

### Class constructor

Create a client for the TypeSafe AI API.

| Argument Name | Type | Description |
|---------------|------|-------------|
| *options* | Object | Configuration; every property is optional. |

| Option | Type | Environment variable | Default |
|--------|------|----------------------|---------|
| `apiKey` | Text | `TYPESAFE_API_KEY` | — (required) |
| `baseURL` | Text | `TYPESAFE_BASE_URL` | `https://api.typesafe.ai` |
| `model` | Text | `TYPESAFE_DEFAULT_MODEL` | `jev-latest` |
| `logLevel` | Text | `TYPESAFE_LOG_LEVEL` | `warn` |
| `logger` | Object | — | the system standard outputs |
| `timeout` | Real | — | `10000` (ms, per attempt) |
| `maxRetries` | Integer | — | `2` |
| `retry` | Object | — | see [RetryPolicy](RetryPolicy.md) |
| `defaultHeaders` | Object | — | `{}` |

Throws a [TypeSafeError](TypeSafeError.md) when no API key is available, when the log level
is unknown, or when a numeric option is out of range.

```4d
// From the environment
var $client:=cs.jev.Client.new()

// Explicit, with a per-client retry policy
var $client:=cs.jev.Client.new({apiKey: "sk-…"; logLevel: "info"; retry: {maxRetries: 4}})
```

## Functions

### systemOne()

**systemOne**(*state* : Object; *options* : Object) : Variant

| Parameter | Type | Description |
|-----------|------|-------------|
| *state* | Object | `{state: <Text \| Object \| Collection>}`, or the state value's own object. May also carry `questions`, `model` and any extra request property, forwarded as-is. |
| *options* | Object | Request options, see below. |
| Function result | [SystemOneResult](SystemOneResult.md) or `4D.HTTPRequest` | The answers, or the request itself when a callback is passed. |

Answers named questions about text or structured state.

| Option | Type | Description |
|--------|------|-------------|
| `questions` | Object | The question set; may also travel in *state*. |
| `model` | Text | Model for this call only. |
| `timeout` | Real | Timeout for this call, in milliseconds. |
| `retry` | Object | Retry overrides for this call; unset fields keep the client's. |
| `headers` | Object | Headers merged over `defaultHeaders`. |
| `onResponse` | 4D.Function | Called on success only. |
| `onError` | 4D.Function | Called on failure only. |
| `onTerminate` | 4D.Function | Called always, after `onResponse` / `onError`. |
| `formula` | 4D.Function | Called always, last. |
| `formulaThis` | Variant | Not a callback: becomes `This` inside each of them. |

Passing any of the four callbacks makes the call asynchronous. See
[Asynchronous calls](../../README.md#asynchronous-calls).

Throws a [TypeSafeError](TypeSafeError.md) for an empty or malformed question set, an
[APIError](APIError.md) for a non-2xx response after retries, and a
[TimeoutError](TimeoutError.md) or [ConnectionError](ConnectionError.md) when delivery
fails.

#### Example usage:

```4d
var $q:=cs.jev.Questions.me

var $questions:={}
$questions.category:=$q.choice("What is this ticket about?"; {billing: Null; technical: Null; other: Null})
$questions.urgent:=$q.noul("Does this need urgent attention?")

var $result:=$client.systemOne({state: "I was charged twice."}; {questions: $questions})

var $category : Text:=$result.answers.category.choice
var $urgent : Real:=$result.answers.urgent.noul
```

### list_models()

**list_models**(*options* : Object) : Variant

| Parameter | Type | Description |
|-----------|------|-------------|
| *options* | Object | The same options as `systemOne()`, apart from `questions` and `model`. |
| Function result | [ModelsListResult](ModelsListResult.md) or `4D.HTTPRequest` | The models available to the account. |

Lists the models available to the account. A shortcut for
[`models.list()`](Models.md#list).

#### Example usage:

```4d
var $result:=$client.list_models(Null)
var $models : Collection:=$result.models
```
