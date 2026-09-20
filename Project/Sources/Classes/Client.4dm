// Client for the TypeSafe AI API.
//
// Explicit options take precedence over environment variables, then SDK defaults.
// 4D has no async/await: a call is synchronous unless it carries a callback, in which
// case the result is delivered to that callback instead of being returned. See _call().

property apiKey : Text
property baseURL : Text
property model : Text
property timeoutMs : Integer
property maxRetries : Integer
property logLevel : Text
property retryPolicy : cs:C1710.RetryPolicy
property logger : cs:C1710.Logger
property defaultHeaders : Object
property models : cs:C1710.Models
property requestCount : Integer

/*
* $options: apiKey, baseURL, model, timeout (ms), maxRetries, logLevel, logger,
*           retry (object of RetryPolicy overrides), defaultHeaders.
* Throws TypeSafeError when no API key is available or an option is invalid.
*/
Class constructor($options : Object)
	var $o : Object:={}
	If (($options#Null:C1517) && (Value type:C1509($options)=Is object:K8:27))
		$o:=$options
	End if
	
	var $env : cs:C1710._Env:=cs:C1710._Env.me
	var $k : cs:C1710._Constants:=cs:C1710._Constants.me
	var $utils : cs:C1710._Utils:=cs:C1710._Utils.me
	
	This:C1470.requestCount:=0
	
	This:C1470.apiKey:=$utils.trim(String:C10($o.apiKey))
	If (This:C1470.apiKey="")
		This:C1470.apiKey:=$env.read($k.apiKeyEnv())
	End if
	If (This:C1470.apiKey="")
		throw:C1805(cs:C1710.TypeSafeError.new("No API key was provided. Pass `apiKey` to cs.jev.Client.new() or set the "+$k.apiKeyEnv()+" environment variable."; Null:C1517))
	End if
	
	var $base : Text:=$utils.trim(String:C10($o.baseURL))
	If ($base="")
		$base:=$env.read($k.baseURLEnv())
	End if
	If ($base="")
		$base:=$k.defaultBaseURL()
	End if
	This:C1470.baseURL:=$utils.stripTrailingSlashes($base)
	
	var $model : Text:=$utils.trim(String:C10($o.model))
	If ($model="")
		$model:=$utils.trim(String:C10($o.defaultModel))
	End if
	If ($model="")
		$model:=$env.read($k.defaultModelEnv())
	End if
	If ($model="")
		$model:=$k.defaultModel()
	End if
	This:C1470.model:=$model
	
	This:C1470.timeoutMs:=$k.defaultTimeoutMs()
	If ($o.timeout#Null:C1517)
		This:C1470.timeoutMs:=This:C1470._assertPositiveMs("timeout"; Num:C11($o.timeout))
	End if
	
	This:C1470.logLevel:=Lowercase:C14($utils.trim(String:C10($o.logLevel)))
	var $logSource : Text:="the `logLevel` option"
	If (This:C1470.logLevel="")
		This:C1470.logLevel:=Lowercase:C14($env.read($k.logLevelEnv()))
		$logSource:=$k.logLevelEnv()
	End if
	This:C1470.logger:=cs:C1710.Logger.new(This:C1470.logLevel; $logSource; $o.logger)
	This:C1470.logLevel:=This:C1470.logger.level
	
	This:C1470.retryPolicy:=cs:C1710.RetryPolicy.new($o.retry)
	If ($o.maxRetries#Null:C1517)
		This:C1470.retryPolicy.apply({maxRetries: Num:C11($o.maxRetries)})
	End if
	This:C1470.maxRetries:=This:C1470.retryPolicy.maxRetries
	
	This:C1470.defaultHeaders:=$utils.assign({}; $o.defaultHeaders)
	This:C1470.models:=cs:C1710.Models.new(This:C1470)

Function _assertPositiveMs($name : Text; $value : Real) : Real
	If ($value<=0)
		throw:C1805(cs:C1710.TypeSafeError.new("`"+$name+"` must be a positive number of milliseconds, got "+String:C10($value)+"."; Null:C1517))
	End if
	return $value

	// MARK:- API
	
/*
* Answer named questions about text or structured state.
*
* $state:   {state: <text|object|collection>} or the state value's own object;
*           may also carry `questions`, `model` and any extra request property,
*           which is forwarded to the API as-is.
* $options: questions, model, timeout, retry, headers,
*           onResponse / onError / onTerminate / formula (see _call).
*
* Returns a SystemOneResult, or the 4D.HTTPRequest when called asynchronously.
* Throws TypeSafeError for an empty or malformed question set, APIError for a
* non-2xx response after retries, TimeoutError / ConnectionError for transport failures.
*/
Function systemOne($state : Object; $options : Object) : Variant
	var $utils : cs:C1710._Utils:=cs:C1710._Utils.me
	var $opts : Object:={}
	If (($options#Null:C1517) && (Value type:C1509($options)=Is object:K8:27))
		$opts:=$options
	End if
	
	var $questions : Object:=Null:C1517
	If (Value type:C1509($opts.questions)=Is object:K8:27)
		$questions:=$opts.questions
	Else 
		If (($state#Null:C1517) && (Value type:C1509($state.questions)=Is object:K8:27))
			$questions:=$state.questions
		End if
	End if
	cs:C1710.Questions.me.validateQuestions($questions)
	
	var $payload : Object:={}
	// An object owning a `state` property is the request; anything else is the state itself.
	// The property is read by presence, so an explicit `state: Null` stays a state value.
	If (($state#Null:C1517) && (Value type:C1509($state)=Is object:K8:27) && (Value type:C1509($state.state)#Is undefined:K8:13))
		// Forward any extra request property, as the JavaScript SDK spreads the request.
		$utils.assign($payload; $state)
		$payload.state:=$state.state
	Else 
		$payload.state:=$state
	End if
	$payload.questions:=$questions
	
	var $model : Text:=This:C1470.model
	If (($state#Null:C1517) && (String:C10($state.model)#""))
		$model:=$state.model
	End if
	If (String:C10($opts.model)#"")
		$model:=$opts.model
	End if
	$payload.model:=$model
	
	return This:C1470._call("/v1/systemone"; "POST"; $payload; $opts; cs:C1710.SystemOneResult)

// List the models available to the account. Same $options as systemOne.
Function list_models($options : Object) : Variant
	return This:C1470.models.list($options)

	// MARK:- Dispatch
	
/*
* Run one call, synchronously or asynchronously.
*
* Synchronous (no callback in $options): returns an instance of $resultType and throws
* on failure.
*
* Asynchronous ($options carries onResponse, onError, onTerminate or formula as a
* 4D.Function): returns the 4D.HTTPRequest so the caller can .terminate() it, and hands
* the same $resultType instance to the callbacks, with `success` false and the failure
* in `error` rather than thrown. $options.formulaThis becomes This inside a callback.
*
* The calling process must survive long enough to receive the callback: use CALL WORKER
* or a form context, not New process. Asynchronous calls do not retry.
*/
Function _call($path : Text; $method : Text; $body : Object; $options : Object; $resultType : 4D:C1709.Class) : Variant
	var $opts : Object:={}
	If (($options#Null:C1517) && (Value type:C1509($options)=Is object:K8:27))
		$opts:=$options
	End if
	
	var $callbacks : Object:=This:C1470._callbacksFrom($opts)
	If ($callbacks#Null:C1517)
		return This:C1470._requestAsync($path; $method; $body; $opts; $resultType; $callbacks)
	End if
	
	var $result : Object:=This:C1470._result($resultType; This:C1470._perform($path; $method; $body; $opts))
	$result.throwIfError()
	return $result

// The callback set for an asynchronous call, or Null when the call is synchronous.
Function _callbacksFrom($options : Object) : Object
	var $out : Object:={onResponse: Null:C1517; onError: Null:C1517; onTerminate: Null:C1517; formula: Null:C1517; formulaThis: $options.formulaThis}
	var $any : Boolean:=False:C215
	var $name : Text
	For each ($name; ["onResponse"; "onError"; "onTerminate"; "formula"])
		If (($options[$name]#Null:C1517) && (OB Instance of:C1731($options[$name]; 4D:C1709.Function)))
			$out[$name]:=$options[$name]
			$any:=True:C214
		End if
	End for each 
	If (Not:C34($any))
		return Null:C1517
	End if
	return $out

// Notify the callbacks: onResponse or onError, then onTerminate and formula.
Function _dispatch($callbacks : Object; $result : Object)
	If ($callbacks=Null:C1517)
		return 
	End if
	var $context : Variant:=$callbacks.formulaThis
	If ($result.success)
		If ($callbacks.onResponse#Null:C1517)
			$callbacks.onResponse.call($context; $result)
		End if
	Else 
		If ($callbacks.onError#Null:C1517)
			$callbacks.onError.call($context; $result)
		End if
	End if
	If ($callbacks.onTerminate#Null:C1517)
		$callbacks.onTerminate.call($context; $result)
	End if
	If ($callbacks.formula#Null:C1517)
		$callbacks.formula.call($context; $result)
	End if

	// MARK:- Transport
	
/*
* Send one request with retries and report the result as
* {ok; body; error; status; headers; requestId}. Never throws for an API or
* transport failure, so the asynchronous fallback path can reuse it.
*/
Function _perform($path : Text; $method : Text; $body : Object; $options : Object) : Object
	var $utils : cs:C1710._Utils:=cs:C1710._Utils.me
	var $prep : Object:=This:C1470._prepare($path; $method; $body; $options)
	var $policy : cs:C1710.RetryPolicy:=$prep.policy
	
	var $attempt : Integer:=0
	var $retriesLeft : Integer:=0
	var $attemptHeaders : Object:=Null:C1517
	var $retryHeader : Object:=Null:C1517
	var $requestOptions : Object:=Null:C1517
	var $request : 4D:C1709.HTTPRequest:=Null:C1517
	var $response : Object:=Null:C1517
	var $failure : Text:=""
	var $started : Integer:=0
	var $elapsed : Integer:=0
	var $transportError : Variant:=Null:C1517
	var $retryTransport : Boolean:=False:C215
	var $outcome : Object:=Null:C1517
	var $done : Boolean:=False:C215
	
	While (Not:C34($done))
		$retriesLeft:=$policy.maxRetries-$attempt
		$attemptHeaders:=$prep.headers
		If ($attempt>0)
			$retryHeader:={}
			$retryHeader["X-TypeSafe-Retry-Count"]:=String:C10($attempt)
			$attemptHeaders:=$utils.mergeHeaders([$prep.headers; $retryHeader])
		End if
		This:C1470.logger.debug($prep.tag+" -> "+$prep.url+" headers="+JSON Stringify:C1217($utils.redactHeaders($attemptHeaders)))
		
		$requestOptions:={method: $method; headers: $attemptHeaders; dataType: "auto"; timeout: $prep.timeoutMs/1000}
		If ($body#Null:C1517)
			$requestOptions.body:=$body
		End if
		
		$failure:=""
		$request:=Null:C1517
		$response:=Null:C1517
		$started:=Milliseconds
		Try
			$request:=4D:C1709.HTTPRequest.new($prep.url; $requestOptions)
			$request.wait()
			$response:=$request.response
		Catch
			$failure:="Connection error."
			If ((Last errors:C1799#Null:C1517) && (Last errors:C1799.length>0))
				$failure:="Connection error: "+String:C10(Last errors:C1799[0].message)
			End if
		End try
		$elapsed:=Milliseconds-$started
		
		If (($failure#"") || ($response=Null:C1517))
			$transportError:=This:C1470._transportError($failure; $elapsed; $prep.timeoutMs)
			$retryTransport:=(OB Instance of:C1731($transportError; cs:C1710.TimeoutError)) ? $policy.retryOnTimeout : $policy.retryOnConnectionError
			This:C1470.logger.info($prep.tag+" "+String:C10($transportError.message)+" after "+String:C10($elapsed)+"ms")
			If (($retriesLeft<=0) || (Not:C34($retryTransport)))
				return {ok: False:C215; body: Null:C1517; error: $transportError; status: 0; headers: Null:C1517; requestId: ""}
			End if
			This:C1470._backOff($prep.tag; $attempt; $retriesLeft; String:C10($transportError.message); Null:C1517; $policy)
			$attempt:=$attempt+1
		Else 
			$outcome:=This:C1470._outcomeFromResponse($response; $prep.url)
			This:C1470.logger.info($prep.tag+" <- "+String:C10($outcome.status)+" in "+String:C10($elapsed)+"ms"+This:C1470._requestSuffix($outcome.requestId))
			This:C1470.logger.debug($prep.tag+" <- body "+JSON Stringify:C1217($response.body || Null:C1517))
			If ($outcome.ok || ($retriesLeft<=0) || (Not:C34($policy.isRetryableStatus($outcome.status))))
				return $outcome
			End if
			This:C1470._backOff($prep.tag; $attempt; $retriesLeft; String:C10($outcome.status); $response.headers; $policy)
			$attempt:=$attempt+1
		End if
	End while 
	
	return Null:C1517

/*
* Start an asynchronous request and return its 4D.HTTPRequest, so the caller can
* .terminate() it. The result reaches $callbacks instead of being returned.
*
* Asynchronous calls do not retry: the backoff would have to block the calling process,
* which is the very thing a callback avoids. Omit the callbacks to get retries.
*/
Function _requestAsync($path : Text; $method : Text; $body : Object; $options : Object; $resultType : 4D:C1709.Class; $callbacks : Object) : Variant
	var $prep : Object:=This:C1470._prepare($path; $method; $body; $options)
	
	// 4D delivers the callbacks in the calling process, which never gets the hand back
	// from the method editor: run synchronously there and notify straight away.
	If (Process info:C1843(Current process:C322).type=Created from execution dialog:K36:14)
		This:C1470.logger.warn($prep.tag+" cannot call back asynchronously from the method editor; running synchronously")
		This:C1470._dispatch($callbacks; This:C1470._result($resultType; This:C1470._perform($path; $method; $body; $options)))
		return Null:C1517
	End if
	
	var $requestOptions : Object:={method: $method; headers: $prep.headers; dataType: "auto"; timeout: $prep.timeoutMs/1000}
	If ($body#Null:C1517)
		$requestOptions.body:=$body
	End if
	This:C1470.logger.debug($prep.tag+" -> "+$prep.url+" (async) headers="+JSON Stringify:C1217(cs:C1710._Utils.me.redactHeaders($prep.headers)))
	
	var $async : cs:C1710._AsyncOptions:=cs:C1710._AsyncOptions.new($requestOptions; This:C1470; $callbacks; $resultType; $prep.tag; $prep.url; $prep.timeoutMs)
	return 4D:C1709.HTTPRequest.new($prep.url; $async)

// Finish an asynchronous request: build the result and notify the callbacks.
// Called back by _AsyncOptions.onTerminate().
Function _completeAsync($async : cs:C1710._AsyncOptions; $request : 4D:C1709.HTTPRequest)
	var $elapsed : Integer:=Milliseconds-$async._started
	var $response : Object:=$request.response
	var $outcome : Object:=Null:C1517
	var $failure : Text:=""
	
	If (($request.errors#Null:C1517) && ($request.errors.length>0))
		$failure:="Connection error: "+String:C10($request.errors[0].message)
	End if
	
	If (($failure#"") || ($response=Null:C1517))
		$outcome:={ok: False:C215; body: Null:C1517; error: This:C1470._transportError($failure; $elapsed; $async._timeoutMs); status: 0; headers: Null:C1517; requestId: ""}
		This:C1470.logger.info($async._tag+" "+String:C10($outcome.error.message)+" after "+String:C10($elapsed)+"ms")
	Else 
		$outcome:=This:C1470._outcomeFromResponse($response; $async._url)
		This:C1470.logger.info($async._tag+" <- "+String:C10($outcome.status)+" in "+String:C10($elapsed)+"ms"+This:C1470._requestSuffix($outcome.requestId))
		This:C1470.logger.debug($async._tag+" <- body "+JSON Stringify:C1217($response.body || Null:C1517))
	End if
	
	This:C1470._dispatch($async._callbacks; This:C1470._result($async._resultType; $outcome))

	// MARK:- Helpers
	
// URL, merged headers, timeout, retry policy and log tag for one call.
Function _prepare($path : Text; $method : Text; $body : Object; $options : Object) : Object
	var $utils : cs:C1710._Utils:=cs:C1710._Utils.me
	var $k : cs:C1710._Constants:=cs:C1710._Constants.me
	
	var $policy : cs:C1710.RetryPolicy:=This:C1470.retryPolicy
	If ($options.retry#Null:C1517)
		$policy:=This:C1470.retryPolicy.clone().apply($options.retry)
	End if
	
	var $timeoutMs : Integer:=This:C1470.timeoutMs
	If ($options.timeout#Null:C1517)
		$timeoutMs:=This:C1470._assertPositiveMs("timeout"; Num:C11($options.timeout))
	End if
	
	var $sdk : Text:="typesafe-sdk-4d/"+$k.sdkVersion()
	var $fixed : Object:={}
	$fixed["Authorization"]:="Bearer "+This:C1470.apiKey
	$fixed["Accept"]:="application/json"
	$fixed["User-Agent"]:=$sdk
	$fixed["X-TypeSafe-SDK"]:=$sdk
	$fixed["X-TypeSafe-Runtime"]:=$k.runtime()
	// Only a retry sets this; a caller's own value is dropped.
	$fixed["X-TypeSafe-Retry-Count"]:=Null:C1517
	If ($body#Null:C1517)
		$fixed["Content-Type"]:="application/json"
	End if
	
	This:C1470.requestCount:=This:C1470.requestCount+1
	
	var $prep : Object:={}
	$prep.url:=This:C1470.baseURL+$path
	// Caller headers go first so they cannot clobber auth or the JSON content type.
	$prep.headers:=$utils.mergeHeaders([This:C1470.defaultHeaders; $options.headers; $fixed])
	$prep.timeoutMs:=$timeoutMs
	$prep.policy:=$policy
	$prep.tag:="#"+String:C10(This:C1470.requestCount)+" "+$method+" "+$path
	return $prep

// " (request <id>)" for a response that carries one, "" otherwise.
Function _requestSuffix($requestId : Text) : Text
	If ($requestId="")
		return ""
	End if
	return " (request "+$requestId+")"

// Turn one HTTP response into an outcome object.
Function _outcomeFromResponse($response : Object; $url : Text) : Object
	var $status : Integer:=Num:C11($response.status)
	var $requestId : Text:=cs:C1710._Utils.me.requestIdFrom($response.headers)
	If (($status>=200) && ($status<300))
		return {ok: True:C214; body: $response.body; error: Null:C1517; status: $status; headers: $response.headers; requestId: $requestId}
	End if
	var $error : Variant:=cs:C1710.APIError.new(""; $status; $response.body; $response.headers; $url; Null:C1517)
	return {ok: False:C215; body: $response.body; error: $error; status: $status; headers: $response.headers; requestId: $requestId}

// Classify a delivery failure: past the deadline it is a timeout, otherwise a connection error.
Function _transportError($message : Text; $elapsed : Integer; $timeoutMs : Integer) : Variant
	If ($elapsed>=$timeoutMs)
		return cs:C1710.TimeoutError.new($timeoutMs; Null:C1517)
	End if
	return cs:C1710.ConnectionError.new($message; Null:C1517)

// Build the result instance for an outcome, carrying the failure instead of throwing it.
Function _result($resultType : 4D:C1709.Class; $outcome : Object) : Object
	var $result : Object:=Null:C1517
	If ($outcome.ok)
		$result:=$resultType.new($outcome.body)
	Else 
		$result:=$resultType.new(Null:C1517)
		$result.fail($outcome.error)
	End if
	$result.status:=Num:C11($outcome.status)
	$result.requestId:=String:C10($outcome.requestId)
	return $result

Function _backOff($tag : Text; $attempt : Integer; $retriesLeft : Integer; $reason : Text; $headers : Object; $policy : cs:C1710.RetryPolicy)
	var $delay : Integer:=$policy.delayMs($attempt; $headers)
	This:C1470.logger.info($tag+" retrying in "+String:C10($delay)+"ms (retry "+String:C10($attempt+1)+"/"+String:C10($attempt+$retriesLeft)+") after "+$reason)
	$policy.sleep($delay)
