// Retry policy: retryable statuses, Retry-After parsing, backoff and waiting.

property maxRetries : Integer
property backoffInitialMs : Integer
property backoffMaxMs : Integer
property backoffJitter : Real
property maxRetryAfterMs : Integer
property respectRetryAfter : Boolean
property httpStatuses : Collection
property retryOnConnectionError : Boolean
property retryOnTimeout : Boolean

// $overrides may carry any of the properties above; unknown keys are ignored.
Class constructor($overrides : Object)
	var $c : cs:C1710._Constants:=cs:C1710._Constants.me
	This:C1470.maxRetries:=$c.defaultMaxRetries()
	This:C1470.backoffInitialMs:=$c.defaultBackoffInitialMs()
	This:C1470.backoffMaxMs:=$c.defaultBackoffMaxMs()
	This:C1470.backoffJitter:=$c.defaultBackoffJitter()
	This:C1470.maxRetryAfterMs:=$c.defaultMaxRetryAfterMs()
	This:C1470.respectRetryAfter:=True:C214
	This:C1470.retryOnConnectionError:=True:C214
	This:C1470.retryOnTimeout:=True:C214
	// HTTP 408, 429 and every 5xx.
	This:C1470.httpStatuses:=[408; 429]
	var $s : Integer
	For ($s; 500; 599)
		This:C1470.httpStatuses.push($s)
	End for 
	This:C1470.apply($overrides)

// Merge and validate overrides in place; returns This for chaining.
Function apply($overrides : Object) : cs:C1710.RetryPolicy
	If (($overrides=Null:C1517) || (Value type:C1509($overrides)#Is object:K8:27))
		return This:C1470
	End if
	If ($overrides.maxRetries#Null:C1517)
		This:C1470.maxRetries:=This:C1470._assertNonNegative("retry.maxRetries"; Num:C11($overrides.maxRetries))
	End if
	If ($overrides.backoffInitialMs#Null:C1517)
		This:C1470.backoffInitialMs:=This:C1470._assertNonNegative("retry.backoffInitialMs"; Num:C11($overrides.backoffInitialMs))
	End if
	If ($overrides.backoffMaxMs#Null:C1517)
		This:C1470.backoffMaxMs:=This:C1470._assertNonNegative("retry.backoffMaxMs"; Num:C11($overrides.backoffMaxMs))
	End if
	If ($overrides.maxRetryAfterMs#Null:C1517)
		This:C1470.maxRetryAfterMs:=This:C1470._assertNonNegative("retry.maxRetryAfterMs"; Num:C11($overrides.maxRetryAfterMs))
	End if
	If ($overrides.backoffJitter#Null:C1517)
		var $jitter : Real:=Num:C11($overrides.backoffJitter)
		If (($jitter<0) || ($jitter>1))
			throw:C1805(cs:C1710.TypeSafeError.new("`retry.backoffJitter` must be between 0 and 1, got "+String:C10($jitter)+"."; Null:C1517))
		End if
		This:C1470.backoffJitter:=$jitter
	End if
	If ($overrides.respectRetryAfter#Null:C1517)
		This:C1470.respectRetryAfter:=Bool:C1537($overrides.respectRetryAfter)
	End if
	If ($overrides.retryOnConnectionError#Null:C1517)
		This:C1470.retryOnConnectionError:=Bool:C1537($overrides.retryOnConnectionError)
	End if
	If ($overrides.retryOnTimeout#Null:C1517)
		This:C1470.retryOnTimeout:=Bool:C1537($overrides.retryOnTimeout)
	End if
	If (Value type:C1509($overrides.httpStatuses)=Is collection:K8:32)
		var $status : Variant
		For each ($status; $overrides.httpStatuses)
			If ((Num:C11($status)<100) || (Num:C11($status)>999))
				throw:C1805(cs:C1710.TypeSafeError.new("`retry.httpStatuses` must contain HTTP status codes, got "+String:C10($status)+"."; Null:C1517))
			End if
		End for each 
		This:C1470.httpStatuses:=$overrides.httpStatuses.copy()
	End if
	return This:C1470

Function _assertNonNegative($name : Text; $value : Real) : Real
	If ($value<0)
		throw:C1805(cs:C1710.TypeSafeError.new("`"+$name+"` must be non-negative, got "+String:C10($value)+"."; Null:C1517))
	End if
	return $value

// Whether the policy retries an HTTP status code.
Function isRetryableStatus($status : Integer) : Boolean
	return This:C1470.httpStatuses.indexOf($status)>=0

// Parse `retry-after-ms`, then `Retry-After` seconds, into milliseconds.
// Returns -1 when neither header carries a usable delay.
Function parseRetryAfterMs($headers : Object) : Integer
	return cs:C1710._Utils.me.parseRetryAfterMs($headers)

// Delay in milliseconds before a zero-based retry attempt.
Function delayMs($attempt : Integer; $headers : Object) : Integer
	var $n : Integer:=$attempt
	If ($n<0)
		$n:=0
	End if
	If (This:C1470.respectRetryAfter && ($headers#Null:C1517))
		var $retryAfter : Integer:=This:C1470.parseRetryAfterMs($headers)
		If (($retryAfter>=0) && ($retryAfter<=This:C1470.maxRetryAfterMs))
			return $retryAfter
		End if
	End if
	// 4D caps 2^n well before this, but keep the exponent sane anyway.
	If ($n>30)
		$n:=30
	End if
	var $exponential : Real:=This:C1470.backoffInitialMs*(2^$n)
	If ($exponential>This:C1470.backoffMaxMs)
		$exponential:=This:C1470.backoffMaxMs
	End if
	var $jitter : Real:=1-(This:C1470.backoffJitter*(Random:C100/32767))
	return Round($exponential*$jitter; 0)

// Block the current process for $ms milliseconds (4D has no async wait).
Function sleep($ms : Integer)
	If ($ms<=0)
		return 
	End if
	DELAY PROCESS:C323(Current process:C322; ($ms*60)/1000)

// A detached copy, so per-call overrides never touch the client's policy.
Function clone() : cs:C1710.RetryPolicy
	var $copy : cs:C1710.RetryPolicy:=cs:C1710.RetryPolicy.new(Null:C1517)
	$copy.maxRetries:=This:C1470.maxRetries
	$copy.backoffInitialMs:=This:C1470.backoffInitialMs
	$copy.backoffMaxMs:=This:C1470.backoffMaxMs
	$copy.backoffJitter:=This:C1470.backoffJitter
	$copy.maxRetryAfterMs:=This:C1470.maxRetryAfterMs
	$copy.respectRetryAfter:=This:C1470.respectRetryAfter
	$copy.retryOnConnectionError:=This:C1470.retryOnConnectionError
	$copy.retryOnTimeout:=This:C1470.retryOnTimeout
	$copy.httpStatuses:=This:C1470.httpStatuses.copy()
	return $copy
