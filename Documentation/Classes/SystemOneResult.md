# SystemOneResult

The result of `POST /v1/systemone`, returned by [`Client.systemOne()`](Client.md#systemone).

## Inherits

- [Result](Result.md)

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `answers` | Object | The answers, keyed by question name. |
| `usage` | Object | Token usage: `input_tokens` and `output_tokens`. |
| `model` | Text | The model that answered. |
| `data` | Object | The whole response body. |

### Answers

Each answer is an object whose shape follows the question that asked for it.

| Question | Answer properties |
|----------|-------------------|
| [noul](Questions.md#noul) | `noul`, the probability of yes, from 0 to 1. |
| [choice](Questions.md#choice) | `choice`, the selected label; `confidence`; `probabilities`, keyed by label. |
| [score](Questions.md#score) | `score`, which may fall between rubric levels; `confidence`; `legend`; `probabilities`, keyed by score. |

## Functions

### answer()

**answer**(*name* : Text) : Variant

| Parameter | Type | Description |
|-----------|------|-------------|
| *name* | Text | A question name. |
| Function result | Variant | The answer recorded for it, or `Null` when absent. |

#### Example usage:

```4d
var $result:=$client.systemOne($state; {questions: $questions})

LOG EVENT(Into system standard outputs; $result.answers.category.choice+"\n")
LOG EVENT(Into system standard outputs; String($result.answers.urgency.score)+"\n")
LOG EVENT(Into system standard outputs; String($result.usage.input_tokens)+" input tokens\n")
```
