# Questions

The `Questions` singleton builds and validates question sets. Reach it through
`cs.jev.Questions.me`.

A question set is an object whose property names identify the answers. Each value is one of
the three question types below.

Instructions and criteria descriptions accept text, an object, a collection or `Null`.

## Functions

### noul()

**noul**(*instructions* : Variant; *criteria* : Variant) : Object

| Parameter | Type | Description |
|-----------|------|-------------|
| *instructions* | Variant | The question. |
| *criteria* | Variant | Optional `{true: …; false: …}` descriptions of both outcomes. |
| Function result | Object | A `noul` question. |

A yes/no question. Its answer carries `noul`, the probability of yes, from 0 to 1.

```4d
$questions.urgent:=cs.jev.Questions.me.noul("Does this need urgent attention?"; \
	{true: "The customer is blocked."; false: "It can wait."})
```

### choice()

**choice**(*instructions* : Variant; *criteria* : Variant) : Object

| Parameter | Type | Description |
|-----------|------|-------------|
| *instructions* | Variant | The question. |
| *criteria* | Object | Labels mapped to descriptions; `Null` leaves a label undescribed. |
| Function result | Object | A `choice` question. |

A question that selects between named alternatives. Its answer carries `choice`,
`confidence` and `probabilities`.

Throws a [TypeSafeError](TypeSafeError.md) when *criteria* is a collection rather than a map.

```4d
$questions.category:=cs.jev.Questions.me.choice("What is this ticket about?"; \
	{billing: Null; technical: Null; other: Null})
```

### score()

**score**(*instructions* : Variant; *criteria* : Variant) : Object

| Parameter | Type | Description |
|-----------|------|-------------|
| *instructions* | Variant | The question. |
| *criteria* | Collection | An ordered rubric: at least two descriptions, indexed by score from zero. |
| Function result | Object | A `score` question. |

A question that assigns a score using an ordered rubric. Its answer carries `score`, which
may fall between rubric levels, plus `confidence`, `legend` and `probabilities`.

Throws a [TypeSafeError](TypeSafeError.md) when *criteria* is a map, or a collection of
fewer than two entries.

```4d
$questions.urgency:=cs.jev.Questions.me.score("How urgent is this ticket?"; \
	["Not urgent."; "Somewhat urgent."; "Needs attention today."])
```

### validateQuestions()

**validateQuestions**(*questions* : Object)

| Parameter | Type | Description |
|-----------|------|-------------|
| *questions* | Object | The question set to check. |

Rejects an empty question set, and any score question whose criteria are not a collection
of at least two descriptions. Throws a [TypeSafeError](TypeSafeError.md). Every call runs
this check before sending anything.

### validate()

**validate**(*questions* : Object) : Object

| Parameter | Type | Description |
|-----------|------|-------------|
| *questions* | Object | The question set to check. |
| Function result | Object | The same question set. |

`validateQuestions()` returning its argument, so a set can be checked where it is used.

#### Example usage:

```4d
var $result:=$client.systemOne($state; {questions: cs.jev.Questions.me.validate($questions)})
```
