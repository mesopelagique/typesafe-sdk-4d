// Question builders and validation. Singleton: cs.jev.Questions.me

singleton Class constructor

// A yes/no question. $criteria optionally describes the true and false outcomes.
Function noul($instructions : Variant; $criteria : Variant) : Object
	return {type: "noul"; instructions: $instructions; criteria: $criteria}

// A score question. $criteria MUST be a list of at least two descriptions,
// indexed by score from zero.
Function score($instructions : Variant; $criteria : Variant) : Object
	If (Value type:C1509($criteria)#Is collection:K8:32)
		throw:C1805(cs:C1710.TypeSafeError.new("Score criteria must be a list of descriptions indexed by score from zero, not a map."; Null:C1517))
	End if
	If ($criteria.length<2)
		throw:C1805(cs:C1710.TypeSafeError.new("Score criteria must be a list of at least two descriptions indexed by score from zero; got "+String:C10($criteria.length)+"."; Null:C1517))
	End if
	return {type: "score"; instructions: $instructions; criteria: $criteria}

// A question that selects between named alternatives.
// $criteria MUST be a map of labels to descriptions.
Function choice($instructions : Variant; $criteria : Variant) : Object
	If (Value type:C1509($criteria)=Is collection:K8:32)
		throw:C1805(cs:C1710.TypeSafeError.new("Choice criteria must be a map of labels to descriptions, not a list."; Null:C1517))
	End if
	return {type: "choice"; instructions: $instructions; criteria: $criteria}

// Reject empty question sets and score questions without a list of at least two criteria.
Function validateQuestions($questions : Object)
	If (Not:C34(cs:C1710._Utils.me.notEmpty($questions)))
		throw:C1805(cs:C1710.TypeSafeError.new("At least one question is required."; Null:C1517))
	End if
	var $name : Text
	For each ($name; $questions)
		var $q : Variant:=$questions[$name]
		If ((Value type:C1509($q)=Is object:K8:27) && ($q.type="score"))
			If (Value type:C1509($q.criteria)#Is collection:K8:32)
				throw:C1805(cs:C1710.TypeSafeError.new("Score question \""+$name+"\" has criteria that are not a list; score criteria must be a list of descriptions indexed by score from zero."; Null:C1517))
			End if
			If ($q.criteria.length<2)
				throw:C1805(cs:C1710.TypeSafeError.new("Score question \""+$name+"\" has "+String:C10($q.criteria.length)+" criteria; at least two scores are required."; Null:C1517))
			End if
		End if
	End for each 

// Validate and return the question set, so it can be inlined in a request.
Function validate($questions : Object) : Object
	This:C1470.validateQuestions($questions)
	return $questions
