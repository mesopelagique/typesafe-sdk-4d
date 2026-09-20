/*
* Base class for API results.
*
* A synchronous call throws on failure, so the result it returns always has `success` true.
* An asynchronous call cannot throw into the caller, so it hands the very same result class
* to the callback with `success` false and the failure in `error`.
*/

property success : Boolean
property error : Variant
property errors : Collection
property status : Integer
property requestId : Text
property rawBody : Variant

Class constructor
	This:C1470.success:=True:C214
	This:C1470.error:=Null:C1517
	This:C1470.errors:=[]
	This:C1470.status:=0
	This:C1470.requestId:=""
	This:C1470.rawBody:=Null:C1517

// Record a failure so the caller can read it instead of catching it. Returns This.
Function fail($error : Variant) : cs:C1710.Result
	This:C1470.success:=False:C215
	This:C1470.error:=$error
	This:C1470.errors:=[$error]
	return This:C1470

// Throw the recorded failure, if any. Used by the synchronous code paths.
Function throwIfError()
	If (Not:C34(This:C1470.success))
		throw:C1805(This:C1470.error)
	End if
