// Level-filtered logger. Levels, most to least verbose: debug, info, warn, error, off.
//
// Messages that pass the level filter go to the system standard outputs, or to an
// injected sink. Redaction lives in _Utils, so a sink only has to log.

property level : Text
property levelRank : Integer
property prefix : Text
property sink : Object

/*
* $level "" falls back to "warn". $source names the origin in the error message.
*
* $sink replaces the system standard outputs. It is any object owning debug, info,
* warn and error functions taking the message as their only parameter; it receives
* the messages that pass the level filter, unprefixed, with headers already redacted.
*/
Class constructor($level : Text; $source : Text; $sink : Object)
	This:C1470.prefix:="[typesafe-sdk]"
	var $value : Text:=Lowercase:C14(cs:C1710._Utils.me.trim($level))
	If ($value="")
		$value:="warn"
	End if
	If (This:C1470._rank($value)<0)
		var $where : Text:=($source#"") ? $source : "the `logLevel` option"
		throw:C1805(cs:C1710.TypeSafeError.new("Invalid log level \""+$value+"\" from "+$where+". Expected one of: debug, info, warn, error, off."; Null:C1517))
	End if
	This:C1470.level:=$value
	This:C1470.levelRank:=This:C1470._rank($value)
	
	This:C1470.sink:=Null:C1517
	If ($sink#Null:C1517)
		If (Not:C34(This:C1470._isSink($sink)))
			throw:C1805(cs:C1710.TypeSafeError.new("`logger` must be an object owning debug, info, warn and error functions."; Null:C1517))
		End if
		This:C1470.sink:=$sink
	End if

// True when the object can stand in for a log sink. 4D does not check the declared
// class of a property, so any object shaped like one will do.
Function _isSink($o : Object) : Boolean
	If (Value type:C1509($o)#Is object:K8:27)
		return False:C215
	End if
	var $name : Text
	For each ($name; ["debug"; "info"; "warn"; "error"])
		// Value type first: OB Instance of raises on a non-object.
		If (Value type:C1509($o[$name])#Is object:K8:27)
			return False:C215
		End if
		If (Not:C34(OB Instance of:C1731($o[$name]; 4D:C1709.Function)))
			return False:C215
		End if
	End for each 
	return True:C214

Function _rank($lvl : Text) : Integer
	Case of 
		: ($lvl="debug")
			return 0
		: ($lvl="info")
			return 1
		: ($lvl="warn")
			return 2
		: ($lvl="error")
			return 3
		: ($lvl="off")
			return 4
		Else 
			return -1
	End case 

Function enabled($lvl : Text) : Boolean
	return This:C1470._rank($lvl)>=This:C1470.levelRank

Function debug($message : Text)
	If (This:C1470.enabled("debug"))
		This:C1470._emit("debug"; $message; Information message)
	End if

Function info($message : Text)
	If (This:C1470.enabled("info"))
		This:C1470._emit("info"; $message; Information message)
	End if

Function warn($message : Text)
	If (This:C1470.enabled("warn"))
		This:C1470._emit("warn"; $message; Information message)
	End if

Function error($message : Text)
	If (This:C1470.enabled("error"))
		This:C1470._emit("error"; $message; Error message)
	End if

Function _emit($level : Text; $message : Text; $severity : Integer)
	If (This:C1470.sink#Null:C1517)
		var $f : 4D:C1709.Function:=This:C1470.sink[$level]
		$f.call(This:C1470.sink; $message)
		return 
	End if
	LOG EVENT:C667(Into system standard outputs:K38:9; This:C1470.prefix+" ["+$level+"] "+$message+"\n"; $severity)

	// MARK:- Redaction, kept here for convenience; the implementation lives in _Utils.
	
Function redactKey($value : Text) : Text
	return cs:C1710._Utils.me.redactKey($value)

Function redact($name : Text; $value : Text) : Text
	return cs:C1710._Utils.me.redact($name; $value)

Function redactHeaders($headers : Object) : Object
	return cs:C1710._Utils.me.redactHeaders($headers)
