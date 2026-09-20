// The result of POST /v1/systemone.

property data : Object
property answers : Object
property usage : Object
property model : Text

Class extends Result

Class constructor($body : Object)
	Super:C1706()
	This:C1470.rawBody:=$body
	If ($body=Null:C1517)
		This:C1470.data:={}
		This:C1470.answers:={}
		This:C1470.usage:={}
		This:C1470.model:=""
		return 
	End if
	This:C1470.data:=$body
	This:C1470.answers:=$body.answers || {}
	This:C1470.usage:=$body.usage || {}
	This:C1470.model:=String:C10($body.model)

// The answer recorded for one question name, or Null when absent.
Function answer($name : Text) : Variant
	return This:C1470.answers[$name]
