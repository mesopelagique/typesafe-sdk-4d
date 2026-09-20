//%attributes = {}
// Receives the asynchronous result. $1 is the same SystemOneResult a synchronous
// call would have returned, except that a failure is carried instead of thrown.
#DECLARE($result : cs:C1710.SystemOneResult)

If ($result.success)
	LOG EVENT:C667(Into system standard outputs:K38:9; "[demo] answers "+JSON Stringify:C1217($result.answers)+"\n"; Information message)
Else 
	LOG EVENT:C667(Into system standard outputs:K38:9; "[demo] failed: "+String:C10($result.error.message)+"\n"; Error message)
End if
