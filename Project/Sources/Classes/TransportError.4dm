// The request or response-body delivery failed (DNS, TLS, connection closed...).

Class extends TypeSafeError

Class constructor($message : Text; $cause : Variant)
	Super($message; $cause)
	This:C1470.name:="TransportError"
	If (This:C1470.message="")
		This:C1470.message:="Connection error."
	End if
