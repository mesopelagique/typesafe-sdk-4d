# JavaScript 0.6.0 parity

The reference is the [TypeSafe JS SDK](https://github.com/typesafe-ai/typesafe-sdk-js)
v0.6.0, commit `66880ccded6cb642dc1809620c2b108c33730214` (2026-09-15). The Python SDK is
not a reference for this port: where the two upstreams disagree, this SDK follows JS.

Reviewed: 2026-09-20, against `src/client.ts`, `types.ts`, `questions.ts`, `retry.ts`,
`errors.ts`, `logging.ts`, `env.ts`, `runtime.ts`, `api-promise.ts` and
`resources/models.ts`.

## Coverage

| Upstream behavior | 4D implementation | Where |
| --- | --- | --- |
| `POST /v1/systemone`, `GET /v1/models` | `Client.systemOne`, `Models.list`, `Client.list_models` | `Client.4dm`, `Models.4dm` |
| `noul` / `choice` / `score` builders, criteria shape checks | `Questions.me.noul` / `.choice` / `.score`, same messages | `Questions.4dm` |
| Nonempty question set; score criteria a list of at least two | `validateQuestions`, also checked in `score()` | `Questions.4dm` |
| Request properties forwarded as-is; `model` override falls back to the client default | `systemOne` copies the request, then sets `state`, `questions`, `model` | `Client.4dm` |
| Explicit option > trimmed environment > SDK default; blank values ignored | `Class constructor` + `_Env.read` | `Client.4dm`, `_Env.4dm` |
| `TYPESAFE_API_KEY`, `TYPESAFE_BASE_URL`, `TYPESAFE_DEFAULT_MODEL`, `TYPESAFE_LOG_LEVEL` | Same four names | `_Constants.4dm` |
| Missing API key throws at construction | `TypeSafeError` with the same wording | `Client.4dm` |
| Trailing slashes stripped from `baseURL` | `_Utils.stripTrailingSlashes` | `_Utils.4dm` |
| Timeout per attempt, positive-milliseconds validation, no total retry budget | `_assertPositiveMs`, `4D.HTTPRequest` timeout | `Client.4dm` |
| Header merge: caller headers first, SDK headers last, last wins case-insensitively, `undefined`/`Null` removes | `_Utils.mergeHeaders` | `_Utils.4dm` |
| `Authorization`, `Accept`, `User-Agent`, `X-TypeSafe-SDK`, `X-TypeSafe-Runtime`, `Content-Type` when a body is sent | `_prepare` | `Client.4dm` |
| `X-TypeSafe-Retry-Count` on retry attempts only | `_perform` | `Client.4dm` |
| Request ID read from `x-typesafe-request-id` | `_Utils.requestIdFrom`, `Result.requestId`, `APIError.requestId` | `_Utils.4dm`, `Result.4dm` |
| API error messages from `error` / `error.message` / `message` / `detail` / validation lists, raw body truncated at 200 characters with `…` | `APIError._describe`, `_extractMessage`, `_describeValidationErrors` | `APIError.4dm` |
| Per-status error taxonomy (400, 401, 403, 404, 422, 429, 5xx) | `APIError.is*()` predicates over `status` | `APIError.4dm` |
| Retry defaults: 2 retries, 500 ms initial, 5000 ms cap, 0.25 jitter, statuses 408/429/500–599, 60 s server-delay cap, connection errors and timeouts retried | `RetryPolicy` constructor | `RetryPolicy.4dm`, `_Constants.4dm` |
| Capped exponential backoff with subtractive jitter | `RetryPolicy.delayMs` | `RetryPolicy.4dm` |
| `retry-after-ms`, then `Retry-After` as seconds or as an HTTP-date, honored up to `maxRetryAfterMs` | `_Utils.parseRetryAfterMs`, `_parseHTTPDateDelayMs` | `_Utils.4dm` |
| Per-call retry overrides inherit client settings and never mutate them | `RetryPolicy.clone().apply` | `RetryPolicy.4dm` |
| Retry override validation (non-negative values, jitter in 0…1, status codes 100–999) | `RetryPolicy.apply` | `RetryPolicy.4dm` |
| Log levels `debug`/`info`/`warn`/`error`/`off`, default `warn`, `[typesafe-sdk]` prefix, invalid level rejected with its source | `Logger` | `Logger.4dm` |
| One `info` line per request and per retry; URL, headers and bodies at `debug` | `_perform`, `_requestAsync` | `Client.4dm` |
| Credential redaction: `authorization`, `proxy-authorization`, `x-api-key` keep scheme and last four characters of secrets over eight; `cookie`, `set-cookie` fully masked; bodies not redacted | `_Utils.redact`, `redactKey`, `redactHeaders` | `_Utils.4dm` |
| Injectable logger, filtered to the configured level | `Logger` sink | `Logger.4dm` |
| `GET /v1/models` shape check with the same message | `ModelsListResult` | `ModelsListResult.4dm` |

## Deliberate deviations

These are 4D-shaped on purpose. They are the SDK's public contract, not accidents.

- **No promises.** `APIPromise`, `asResponse()` and `withResponse()` have no 4D
  equivalent. Every call returns a `Result` subclass that carries `status`, `requestId`
  and `rawBody` itself.
- **Completion handlers instead of `await`.** `onResponse`, `onError`, `onTerminate`,
  `formula` and `formulaThis` in the options make a call asynchronous, following 4D AIKit.
  The call then returns its `4D.HTTPRequest` and the result reaches the handler with
  `success` false rather than being thrown.
- **Asynchronous calls do not retry.** Backoff would block the calling process, which is
  what a handler exists to avoid. Synchronous calls retry.
- **No `AbortSignal`, so no user-abort error.** `4D.HTTPRequest.terminate()` is the
  nearest equivalent; JS's `APIUserAbortError` has no counterpart.
- **One `APIError` class.** `BadRequestError`, `RateLimitError` and the rest are
  predicates (`isBadRequest()`, `isRateLimit()`, …) over `status`, not subclasses.
- **`TransportError` base layer.** JS nests `APITimeoutError` under `APIConnectionError`;
  4D puts `ConnectionError` and `TimeoutError` side by side under `TransportError`.
- **`APIError` always carries `url` and `retryAfterMs`** (`-1` when absent). JS exposes no
  URL, and `retryAfterMs` only on `RateLimitError`.
- **`ModelCard.releaseDate`** is camelCase and accepts either wire spelling; JS exposes
  `release_date` verbatim.
- **Option and property names follow 4D habits**: `model` (also accepting `defaultModel`)
  rather than `defaultModel`, `timeoutMs`, `retryPolicy`, a top-level `maxRetries`
  shortcut, and `retryOnConnectionError` / `retryOnTimeout` for JS's `apiConnectionError`
  / `apiTimeoutError`.
- **State shorthand.** An object carrying no `state` property *is* the state. JS always
  requires `{ state: … }`. See the first known gap below for the cost of this.
- **Questions may travel in either argument**, `$state.questions` or `$options.questions`.
  JS accepts them only in the request.
- **`Client.list_models()`** is a shortcut for `client.models.list()`, which also exists.
- **The environment is snapshotted once per session** by `_Env`, through
  `LAUNCH EXTERNAL PROCESS`. JS reads `process.env` on every access, so a variable changed
  mid-session is picked up there and not here.
- **Identification headers name this SDK**: `typesafe-sdk-4d/<version>` and
  `4d/<application version> (macos|windows)`, where JS sends `typesafe-sdk/<version>` and
  its own runtime. Both headers carry the same value, as upstream does.
- **The logger sink takes the message only.** JS passes `(message, ...args)` and defaults
  to `console`; here structured values are folded into the message and the default sink is
  `LOG EVENT(Into system standard outputs)`.
- **Timeout classification is a heuristic.** `4D.HTTPRequest` does not distinguish a
  timeout from a connection failure, so `_transportError` reports `TimeoutError` when the
  elapsed time reached the configured timeout and `ConnectionError` otherwise.
- **Body parsing is delegated** to `dataType: "auto"`. JS parses the text itself and
  falls back to `JSON.parse` even when `content-type` is wrong, so a JSON body served
  without the JSON content type reaches JS parsed and reaches 4D as text.
- **Jitter granularity.** `Random/32767` gives 32768 discrete multipliers where JS uses
  `Math.random()`. The distribution and the bounds are the same.
- **`score()` rejects a rubric shorter than two entries at build time**, not only in
  `validateQuestions`. Same error, raised earlier.

## Accepted differences

The first review of this port, on 2026-09-20, found seven unintended divergences. All
seven were fixed the same day and now read as parity rows above:

1. `systemOne` tested `state` for a non-`Null` value, so `{state: Null; questions: …}`
   sent the whole request object as the state. It now tests the property for presence
   (`Is undefined`), so an explicit `state: Null` stays a state value.
2. A caller-supplied `X-TypeSafe-Retry-Count` survived the first attempt. `_prepare` now
   drops it, as JS does.
3. `Retry-After` as an HTTP-date fell back to backoff. `_Utils._parseHTTPDateDelayMs`
   now reads the IMF-fixdate, RFC 850 and asctime forms and returns the delay from now.
4. `retry.maxRetries` accepted fractions. `RetryPolicy._assertNonNegativeInteger` now
   rejects them with the JS wording.
5. The `info` response line omitted the request ID. Both the synchronous and the
   asynchronous paths now append ` (request <id>)` when the response carries one.
6. `_Constants.sdkVersion()` said `1.0.0`, which named no upstream line. Releases now
   mirror the upstream release they were reviewed against, so it is `0.6.0` and the
   identification headers say which JS version this port follows.
7. `Client._request()` was unreachable and has been removed.

What remains is deliberate and small:

- **Server delays are capped at 2147483647 ms** (`_Utils._clampMs`), because a 4D Integer
  is a Longint. Any delay large enough to be capped is far past `maxRetryAfterMs`, so the
  caller falls back to backoff exactly as JS would. JS does no clamping.
- **An empty `Retry-After` value** yields no delay here; `Number("")` makes it `0` ms in
  JS. Both then proceed to retry.

## Not applicable

`dangerouslyAllowBrowser` and the browser refusal, the injectable `fetch`, runtime
detection for Deno/Bun/Cloudflare/edge, and `APIPromise.map` have no meaning in a 4D
component and are intentionally absent.

## Verification boundaries

This record is a source review of both SDKs at the versions named above. The one exception
is the HTTP-date arithmetic added for the third fix below: `_epochSeconds` and
`_parseHTTPDateDelayMs` were transliterated and checked against `calendar.timegm` for every
month of 1970–2100 and against the three date formats, which validates the algorithm but
not its 4D transcription. Otherwise nothing here was established by running the component: the repository has no automated tests, and the
four `_demoTypesafe*` methods are manual and need credentials and network access. No live
API call, no compilation run and no retry-timing measurement backs any row of the coverage
table. Treat every entry as "the code reads as equivalent", not as "verified equivalent".

The gap that matters most is the missing test suite. Upstream covers header merging, retry
timing, error mapping, logging and release regressions with vitest; none of that is
mirrored here. A `Tests` folder of project methods runnable under `tool4d --dataless`,
following the upstream test files, would turn this document into a checkable claim.

## Keeping this current

Releases mirror the upstream release they are reviewed against, so the component version
and the version at the top of this file are the same number.

1. Resolve the newest JS release and its commit; compare with the pair named at the top.
2. Review `client.ts`, `types.ts`, `questions.ts`, `retry.ts`, `errors.ts` and
   `logging.ts` for user-visible changes.
3. Port each change, then update this file and the README's differences section together.
4. Record deliberate divergences under **Deliberate deviations** and anything left undone
   under **Known gaps**, so the two lists stay exhaustive.
