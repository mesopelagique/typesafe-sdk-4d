// An unsuccessful HTTP response from the API.

property status : Integer
property body : Variant
property headers : Object
property url : Text
property requestId : Text
property retryAfterMs : Integer

Class extends TypeSafeError

// Pass "" as $message to derive one from the status and body.
Class constructor($message : Text; $status : Integer; $body : Variant; $headers : Object; $url : Text; $cause : Variant)
	Super($message; $cause)
	This:C1470.name:="APIError"
	This:C1470.status:=$status
	This:C1470.errCode:=$status
	This:C1470.body:=$body
	This:C1470.headers:=$headers
	This:C1470.url:=$url
	This:C1470.requestId:=cs:C1710._Utils.me.requestIdFrom($headers)
	// Server retry delay in milliseconds, or -1 when the response carries none.
	This:C1470.retryAfterMs:=cs:C1710._Utils.me.parseRetryAfterMs($headers)
	If (This:C1470.message="")
		This:C1470.message:=This:C1470._describe($status; $body)
	End if

Function isBadRequest() : Boolean
	return This:C1470.status=400

Function isRateLimit() : Boolean
	return This:C1470.status=429

Function isTimeout() : Boolean
	return This:C1470.status=408

Function isNotFound() : Boolean
	return This:C1470.status=404

Function isAuthentication() : Boolean
	return This:C1470.status=401

Function isPermissionDenied() : Boolean
	return This:C1470.status=403

Function isUnprocessable() : Boolean
	return This:C1470.status=422

Function isServer() : Boolean
	return (This:C1470.status>=500) && (This:C1470.status<=599)

// Extract a message from a text, error, or validation response body.
Function _extractMessage($body : Variant) : Text
	Case of 
		: (Value type:C1509($body)=Is text:K8:3)
			return $body
		: (Value type:C1509($body)#Is object:K8:27)
			return ""
	End case 
	If (Value type:C1509($body.error)=Is text:K8:3)
		return $body.error
	End if
	If ((Value type:C1509($body.error)=Is object:K8:27) && (Value type:C1509($body.error.message)=Is text:K8:3))
		return $body.error.message
	End if
	If (Value type:C1509($body.message)=Is text:K8:3)
		return $body.message
	End if
	If (Value type:C1509($body.detail)=Is text:K8:3)
		return $body.detail
	End if
	If ((Value type:C1509($body.detail)=Is object:K8:27) && (Value type:C1509($body.detail.message)=Is text:K8:3))
		return $body.detail.message
	End if
	If (Value type:C1509($body.detail)=Is collection:K8:32)
		return This:C1470._describeValidationErrors($body.detail)
	End if
	return ""

// Format validation errors as "; "-separated `path: message` entries.
Function _describeValidationErrors($errors : Collection) : Text
	var $parts : Collection:=[]
	var $e : Variant
	For each ($e; $errors)
		If ((Value type:C1509($e)=Is object:K8:27) && (Value type:C1509($e.msg)=Is text:K8:3))
			var $loc : Text:=""
			If (Value type:C1509($e.loc)=Is collection:K8:32)
				$loc:=$e.loc.filter(Formula:C1597($1.value#"body")).join(".")
			End if
			$parts.push(($loc#"") ? $loc+": "+$e.msg : $e.msg)
		End if
	End for each 
	return $parts.join("; ")

Function _describe($status : Integer; $body : Variant) : Text
	var $detail : Text:=This:C1470._extractMessage($body)
	If ($detail#"")
		return String:C10($status)+" "+$detail
	End if
	If ($body=Null:C1517)
		return String:C10($status)+" status code (no body)"
	End if
	var $raw : Text:=(Value type:C1509($body)=Is text:K8:3) ? $body : JSON Stringify:C1217($body)
	If (Length:C16($raw)>200)
		$raw:=Substring:C12($raw; 1; 200)+"…"
	End if
	return String:C10($status)+" "+$raw
