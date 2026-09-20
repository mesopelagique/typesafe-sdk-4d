# Logger

The `Logger` class filters the SDK's messages to the configured level and writes them to the
system standard outputs, or to a sink you provide. The [Client](Client.md) builds one from
its `logLevel` and `logger` options.

Levels, from most to least verbose: `debug`, `info`, `warn`, `error`, `off`. The default is
`warn`.

`info` logs one line per request and per retry. `debug` adds the URL, the headers and the
bodies. Known credential headers are redacted; **bodies are not**.

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `level` | Text | The configured level. |
| `levelRank` | Integer | Its rank, `0` for `debug` to `4` for `off`. |
| `prefix` | Text | `[typesafe-sdk]`, prepended to the default output. |
| `sink` | Object | The injected sink, or `Null` for the system standard outputs. |

### Class constructor

**new**(*level* : Text; *source* : Text; *sink* : Object) : Logger

| Argument Name | Type | Description |
|---------------|------|-------------|
| *level* | Text | One of the levels above; `""` falls back to `warn`. |
| *source* | Text | Names the origin of *level* in the error message. |
| *sink* | Object | Optional replacement for the system standard outputs. |

Throws a [TypeSafeError](TypeSafeError.md) for an unknown level, or for a sink that does not
own the four functions.

A sink is any object owning `debug`, `info`, `warn` and `error` functions taking the message
as their only parameter. 4D does not check the declared class of a property, so a class
instance works as well as an object of formulas. The sink only has to log: it receives the
messages that already passed the level filter, unprefixed, with headers already redacted.

```4d
var $sink:={}
$sink.debug:=Formula(MyLog("debug"; $1))
$sink.info:=Formula(MyLog("info"; $1))
$sink.warn:=Formula(MyLog("warn"; $1))
$sink.error:=Formula(MyLog("error"; $1))

var $client:=cs.jev.Client.new({logLevel: "info"; logger: $sink})
```

## Functions

### enabled()

**enabled**(*level* : Text) : Boolean

Whether a message logged at *level* passes the filter.

### debug() / info() / warn() / error()

**debug**(*message* : Text)

Logs *message* at that level, if the filter lets it through. `error()` writes with the
`Error message` severity, the others with `Information message`.

### redactKey() / redact() / redactHeaders()

**redactHeaders**(*headers* : Object) : Object

Copies headers with known credential values masked: `authorization`, `proxy-authorization`
and `x-api-key` keep their scheme and the last four characters of secrets longer than eight,
`cookie` and `set-cookie` are replaced entirely. They are shared internal helpers, exposed
here for convenience.
