//%attributes = {}
// Runnable demo for the TypeSafe 4D SDK.
// Requires TYPESAFE_API_KEY in the environment; TYPESAFE_BASE_URL is optional.

var $out : Text
var $key : Text:=cs:C1710._Env.me.read(cs:C1710._Constants.me.apiKeyEnv())

If ($key="")
	LOG EVENT:C667(Into system standard outputs:K38:9; "[demo] "+cs:C1710._Constants.me.apiKeyEnv()+" is not set; nothing to do.\n"; Error message)
	return 
End if

var $q : cs:C1710.Questions:=cs:C1710.Questions.me

var $questions : Object:={}
$questions.billing:=$q.noul("Is this a billing dispute?"; {true: "The customer disputes a charge."; false: "The customer is asking about something else."})
$questions.category:=$q.choice("What is this ticket about?"; {billing: Null:C1517; technical: Null:C1517; other: Null:C1517})
$questions.urgency:=$q.score("How urgent is this ticket?"; ["Not urgent at all."; "Somewhat urgent."; "Needs attention today."])

var $state : Object:={state: {document: "I was charged twice. Please fix this ASAP."}}
var $options : Object:={questions: $questions; logLevel: "info"}

Try
	var $client : cs:C1710.Client:=cs:C1710.Client.new({logLevel: "info"})
	LOG EVENT:C667(Into system standard outputs:K38:9; "[demo] base URL "+$client.baseURL+", model "+$client.model+"\n"; Information message)
	
	var $result : cs:C1710.SystemOneResult:=$client.systemOne($state; $options)
	$out:="[demo] answers "+JSON Stringify:C1217($result.answers)+"\n"
	LOG EVENT:C667(Into system standard outputs:K38:9; $out; Information message)
	
	var $models : cs:C1710.ModelsListResult:=$client.list_models()
	LOG EVENT:C667(Into system standard outputs:K38:9; "[demo] "+String:C10($models.models.length)+" model(s) available\n"; Information message)
Catch
	$out:="[demo] failed"
	If ((Last errors:C1799#Null:C1517) && (Last errors:C1799.length>0))
		$out:=$out+": "+String:C10(Last errors:C1799[0].message)
	End if
	LOG EVENT:C667(Into system standard outputs:K38:9; $out+"\n"; Error message)
End try
