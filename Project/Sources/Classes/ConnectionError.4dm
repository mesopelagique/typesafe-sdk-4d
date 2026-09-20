// The request could not reach the API.

Class extends TransportError

Class constructor($message : Text; $cause : Variant)
	Super($message; $cause)
	This:C1470.name:="ConnectionError"
	If (This:C1470.message="")
		This:C1470.message:="Connection error."
	End if
