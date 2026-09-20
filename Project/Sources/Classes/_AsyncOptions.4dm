/*
* HTTP options for an asynchronous request.
*
* Passed as the options object of 4D.HTTPRequest.new(), which picks up `onTerminate`
* below as its own callback. Because the options object is a class instance, `This`
* inside that callback is this object, which is how the call keeps its context.
*/

// 4D.HTTPRequest options.
property method : Text
property headers : Object
property dataType : Text
property body : Variant
property timeout : Real

// Call context, read back by Client._completeAsync().
property _client : cs:C1710.Client
property _callbacks : Object
property _resultType : 4D:C1709.Class
property _tag : Text
property _url : Text
property _timeoutMs : Integer
property _started : Integer
property _done : Boolean

Class constructor($options : Object; $client : cs:C1710.Client; $callbacks : Object; $resultType : 4D:C1709.Class; $tag : Text; $url : Text; $timeoutMs : Integer)
	var $key : Text
	For each ($key; $options)
		This:C1470[$key]:=$options[$key]
	End for each 
	This:C1470._client:=$client
	This:C1470._callbacks:=$callbacks
	This:C1470._resultType:=$resultType
	This:C1470._tag:=$tag
	This:C1470._url:=$url
	This:C1470._timeoutMs:=$timeoutMs
	This:C1470._started:=Milliseconds
	This:C1470._done:=False:C215

// Always called once, after onResponse or onError, so it is the only callback we need.
Function onTerminate($request : 4D:C1709.HTTPRequest; $event : Object)
	If (This:C1470._done)
		return 
	End if
	This:C1470._done:=True:C214
	This:C1470._client._completeAsync(This:C1470; $request)
