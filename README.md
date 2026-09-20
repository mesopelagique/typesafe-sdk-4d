# TypeSafe AI 4D SDK

4D SDK for [TypeSafe AI](https://typesafe.ai). A port of the
[JavaScript SDK](https://github.com/typesafe-ai/typesafe-sdk-js) to a 4D component.

## Quickstart

Add the component to your host project's `Project/Sources/dependencies.json`:

```json
{
  "dependencies": {
    "typesafe-sdk-4d": { "github": "mesopelagique/typesafe-sdk-4d" }
  }
}
```

The component exposes its classes under the `jev` namespace, so everything is
reached through `cs.jev.<ClassName>`.

Set `TYPESAFE_API_KEY` in your environment, then create and use the client:

```4d
var $client:=cs.jev.Client.new()

var $criteria:={billing: Null; technical: Null; other: Null}
var $questions:={}
$questions.category:=cs.jev.Questions.me.choice("What is this ticket about?"; $criteria)

var $state:={state: {document: "I was charged twice. Please fix this ASAP."}}
var $result:=$client.systemOne($state; {questions: $questions})

LOG EVENT(Into system standard outputs; String($result.answers.category.choice)+"\n") // billing
```

## Documentation

Learn what TypeSafe can do in the [TypeSafe docs](https://docs.typesafe.ai/).

Every class of the component is documented in [Documentation/Classes](Documentation/Classes):
start with [`Client`](Documentation/Classes/Client.md) for the options and defaults, and
[`Questions`](Documentation/Classes/Questions.md) for the question set.

This component is a port, and it mirrors the JavaScript SDK release it follows, `0.6.0`.
[The parity record](Documentation/parity.md) compares the two in full: what matches, what is
deliberately 4D-shaped, and what is not implemented.

## 4D usage

### Configuration

`cs.jev.Client.new($options)` resolves each setting from the explicit option
first, then the environment, then the SDK default.

| Option | Environment variable | Default |
|--------|----------------------|---------|
| `apiKey` | `TYPESAFE_API_KEY` | — (required) |
| `baseURL` | `TYPESAFE_BASE_URL` | `https://api.typesafe.ai` |
| `model` | `TYPESAFE_DEFAULT_MODEL` | `jev-latest` |
| `logLevel` | `TYPESAFE_LOG_LEVEL` | `warn` |
| `logger` | — | the system standard outputs |
| `timeout` | — | `10000` (ms, per attempt) |
| `maxRetries` | — | `2` |
| `retry` | — | see `RetryPolicy` |
| `defaultHeaders` | — | `{}` |

Environment values are read through `cs.jev._Env.me`, which snapshots the
process environment once per session.

### Questions

`cs.jev.Questions.me` builds and validates question sets.

```4d
var $q:=cs.jev.Questions.me

var $questions:={}
// Yes/no, with optional descriptions of each outcome.
$questions.billing:=$q.noul("Is this a billing dispute?"; {true: "The customer disputes a charge."; false: "Something else."})
// Named alternatives: a map of labels to descriptions.
$questions.category:=$q.choice("What is this ticket about?"; {billing: Null; technical: Null; other: Null})
// An ordered rubric: a list of at least two descriptions, indexed from zero.
$questions.urgency:=$q.score("How urgent is this ticket?"; ["Not urgent."; "Somewhat urgent."; "Needs attention today."])

// Validate up front; returns the set so it can be inlined in a call.
$q.validate($questions)
```

### Calling the API

```4d
// in a 4D project method
Try
	var $client:=cs.jev.Client.new({logLevel: "info"})

	var $state:={state: {document: "I was charged twice. Please fix this ASAP."}}
	var $result:=$client.systemOne($state; {questions: cs.jev.Questions.me.validate($questions)})

	LOG EVENT(Into system standard outputs; JSON Stringify($result.answers)+"\n"; Information message)

	var $models:=$client.list_models(Null)
	LOG EVENT(Into system standard outputs; String($models.models.length)+" models\n"; Information message)
Catch
	LOG EVENT(Into system standard outputs; String(Last errors[0].message)+"\n"; Error message)
End try
```

`Project/Sources/Methods/_demoTypesafe.4dm` is a runnable version of the above.

### Logging

`logLevel` is one of `debug`, `info`, `warn`, `error` and `off`. `info` logs one line
per request and per retry; `debug` adds the URL and the headers, with known credential
headers redacted. Response bodies are logged at `debug` and are **not** redacted.

By default the lines go to the system standard outputs. Pass `logger` to send them
somewhere else — a table, a file, `ALERT`, anything. 4D does not check the declared
class of a property, so the sink is any object owning `debug`, `info`, `warn` and
`error` functions that take the message as their only parameter:

```4d
var $sink:={}
$sink.debug:=Formula(MyLog("debug"; $1))
$sink.info:=Formula(MyLog("info"; $1))
$sink.warn:=Formula(MyLog("warn"; $1))
$sink.error:=Formula(MyLog("error"; $1))

var $client:=cs.jev.Client.new({logLevel: "info"; logger: $sink})
```

A class instance works just as well, and is usually nicer:

```4d
var $client:=cs.jev.Client.new({logLevel: "info"; logger: cs.MyLogger.new()})
```

The sink only has to log: it receives the messages that already passed the level
filter, unprefixed, with headers already redacted. An object missing any of the four
functions is rejected with a `TypeSafeError`.

### Asynchronous calls

4D has no `async` / `await`, so a call is synchronous unless it carries a completion
handler, the way [4D AIKit](https://github.com/4d/4D-AIKit) does it. Pass any of
`onResponse`, `onError`, `onTerminate` or `formula` as a `4D.Function` and the call
returns straight away with its `4D.HTTPRequest` — the result reaches the callback
instead of being returned.

| Option | Called |
|--------|--------|
| `onResponse` | on success only |
| `onError` | on failure only |
| `onTerminate` | always, after `onResponse` / `onError` |
| `formula` | always, last |
| `formulaThis` | not a callback: becomes `This` inside each of them |

The callback receives the same result class the synchronous call returns, so
`$1.success` says which happened and `$1.error` holds the failure.

```4d
// in a worker, a form, or anything else that outlives the request
var $client:=cs.jev.Client.new()

var $options:={}
$options.questions:=$questions
$options.onResponse:=Formula(MyReceiveMethod($1))
$options.onError:=Formula(MyReceiveMethod($1))

$client.systemOne({state: "I was charged twice."}; $options)
```

```4d
// MyReceiveMethod
#DECLARE($result: cs.jev.SystemOneResult)

If ($result.success)
	Form.answers:=$result.answers
Else
	ALERT($result.error.message)
End if
```

> ⚠️ The callbacks are delivered in the process that started the request, so that
> process must still be alive when the answer arrives. Use `CALL WORKER` or a form
> context, not `New process`, and not the method editor — from the method editor the
> SDK logs a warning and falls back to a synchronous call, still notifying the callbacks.

Asynchronous calls do **not** retry: the backoff would have to block the calling
process, which is the very thing a callback avoids. Omit the callbacks to get retries.

`Project/Sources/Methods/_demoTypesafeAsync.4dm` is a runnable version of the above.

### Results

| Class | Properties |
|-------|------------|
| [`Result`](Documentation/Classes/Result.md) | Base class: `success`, `error`, `errors`, `status`, `requestId`, `rawBody`; `throwIfError()` |
| [`SystemOneResult`](Documentation/Classes/SystemOneResult.md) | `answers`, `usage`, `model`, `data`; `answer($name)` |
| [`ModelsListResult`](Documentation/Classes/ModelsListResult.md) | `models` (collection of `ModelCard`) |
| [`ModelCard`](Documentation/Classes/ModelCard.md) | `name`, `description`, `releaseDate` |

A synchronous call throws on failure, so the result it returns always has `success`
true. An asynchronous call cannot throw into the caller, so it hands the same result
class to the callback with `success` false and the failure in `error`.

### Errors

Failures are raised with `throw`, so wrap calls in `Try` / `Catch` and read
`Last errors`. Every error carries `name`, `errCode`, `message` and `cause`.

| Class | Raised when |
|-------|-------------|
| [`TypeSafeError`](Documentation/Classes/TypeSafeError.md) | Base class: bad configuration, empty or malformed questions |
| [`APIError`](Documentation/Classes/APIError.md) | Non-2xx response after retries; adds `status`, `body`, `headers`, `url`, `requestId`, `retryAfterMs` (-1 when absent) and `isBadRequest()` / `isAuthentication()` / `isPermissionDenied()` / `isNotFound()` / `isTimeout()` / `isUnprocessable()` / `isRateLimit()` / `isServer()` |
| [`TransportError`](Documentation/Classes/TransportError.md) | Base class for delivery failures |
| [`ConnectionError`](Documentation/Classes/ConnectionError.md) | The request could not reach the API |
| [`TimeoutError`](Documentation/Classes/TimeoutError.md) | No response within `timeout`; adds `timeoutMs` |

### Retries

[`cs.jev.RetryPolicy`](Documentation/Classes/RetryPolicy.md) holds the policy: HTTP 408, 429 and every 5xx are retried, as
are connection errors and timeouts. Delays use capped exponential backoff with
jitter, and honour `retry-after-ms` or `Retry-After` when the server sends a
delay within `maxRetryAfterMs`. Override per client or per call:

```4d
var $client:=cs.jev.Client.new({retry: {maxRetries: 4; backoffInitialMs: 250}})
var $result:=$client.systemOne($state; {questions: $questions; retry: {maxRetries: 0}})
```
