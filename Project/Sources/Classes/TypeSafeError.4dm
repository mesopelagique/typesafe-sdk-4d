// Base class for SDK errors. Carries errCode + message so it can be thrown with `throw`.

property name : Text
property errCode : Integer
property message : Text
property cause : Variant

Class constructor($message : Text; $cause : Variant)
	This:C1470.name:="TypeSafeError"
	This:C1470.errCode:=1
	This:C1470.message:=$message
	This:C1470.cause:=$cause
