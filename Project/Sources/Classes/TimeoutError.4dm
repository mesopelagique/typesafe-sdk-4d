// The full response did not arrive within the configured timeout.

property timeoutMs : Integer

Class extends TransportError

Class constructor($timeoutMs : Integer; $cause : Variant)
	Super("Request timed out after "+String:C10($timeoutMs)+"ms."; $cause)
	This:C1470.name:="TimeoutError"
	This:C1470.timeoutMs:=$timeoutMs
