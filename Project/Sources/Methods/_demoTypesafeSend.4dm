//%attributes = {}
// Runs in the "typesafe-demo" worker: starts the request and returns immediately.

var $client : cs:C1710.Client:=cs:C1710.Client.new({logLevel: "info"})

var $questions : Object:={}
$questions.billing:=cs:C1710.Questions.me.noul("Is this a billing dispute?"; Null:C1517)

var $options : Object:={}
$options.questions:=$questions
$options.onResponse:=Formula:C1597(_demoTypesafeReceive($1))
$options.onError:=Formula:C1597(_demoTypesafeReceive($1))

// Returns the 4D.HTTPRequest, not the answer: the answer goes to the callbacks.
$client.systemOne({state: "I was charged twice. Please fix this ASAP."}; $options)
