// The result of GET /v1/models.

property models : Collection

Class extends Result

Class constructor($body : Object)
	Super:C1706()
	This:C1470.rawBody:=$body
	This:C1470.models:=[]
	If (($body=Null:C1517) || (Value type:C1509($body.models)#Is collection:K8:32))
		// Recorded rather than thrown, so an asynchronous caller sees it too.
		// The synchronous paths raise it through Result.throwIfError().
		This:C1470.fail(cs:C1710.TypeSafeError.new("Unexpected response shape from GET /v1/models; expected { models: [...] }."; Null:C1517))
		return 
	End if
	var $card : Variant
	For each ($card; $body.models)
		This:C1470.models.push(cs:C1710.ModelCard.new($card))
	End for each 
