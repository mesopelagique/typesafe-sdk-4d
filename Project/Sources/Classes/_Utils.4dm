// Small shared helpers. Singleton: cs.jev._Utils.me

singleton Class constructor

// Strip leading and trailing whitespace (space, tab, CR, LF).
Function trim($value : Text) : Text
	var $result : Text:=$value
	$result:=Replace string:C233($result; Char:C90(Carriage return:K15:38); " ")
	$result:=Replace string:C233($result; Char:C90(Line feed:K15:40); " ")
	$result:=Replace string:C233($result; Char:C90(9); " ")
	return Trim($result)

// True when the object is non-Null and owns at least one key.
Function notEmpty($o : Object) : Boolean
	If ($o=Null:C1517)
		return False:C215
	End if
	If (Value type:C1509($o)#Is object:K8:27)
		return False:C215
	End if
	return Not:C34(OB Is empty($o))

// Drop trailing slashes from a URL root.
Function stripTrailingSlashes($url : Text) : Text
	var $result : Text:=$url
	While (($result#"") && (Substring:C12($result; Length:C16($result); 1)="/"))
		$result:=Substring:C12($result; 1; Length:C16($result)-1)
	End while
	return $result

// Copy an object's keys, lowercased, into a fresh object.
Function lowerKeys($o : Object) : Object
	var $out : Object:={}
	If ($o=Null:C1517)
		return $out
	End if
	var $k : Text
	For each ($k; $o)
		$out[Lowercase:C14($k)]:=$o[$k]
	End for each
	return $out

// Merge $source over $target in place (last value wins).
Function assign($target : Object; $source : Object) : Object
	If ($target=Null:C1517)
		$target:={}
	End if
	If ($source=Null:C1517)
		return $target
	End if
	var $k : Text
	For each ($k; $source)
		$target[$k]:=$source[$k]
	End for each
	return $target

/*
* Merge header objects in order into a fresh object. The last value wins regardless of
* key case, so a caller's `authorization` cannot sit beside the SDK's `Authorization`,
* and a Null value removes the header entirely.
*/
Function mergeHeaders($sources : Collection) : Object
	var $out : Object:={}
	// Lowercased header name -> the key currently used for it in $out.
	var $names : Object:={}
	var $source : Variant
	var $key; $low; $previous : Text
	For each ($source; $sources)
		If (Value type:C1509($source)#Is object:K8:27)
			continue
		End if
		For each ($key; $source)
			$low:=Lowercase:C14($key)
			$previous:=String:C10($names[$low])
			If ($previous#"")
				OB REMOVE:C1226($out; $previous)
			End if
			If ($source[$key]=Null:C1517)
				OB REMOVE:C1226($names; $low)
			Else
				$names[$low]:=$key
				$out[$key]:=String:C10($source[$key])
			End if
		End for each
	End for each
	return $out

// The `x-typesafe-request-id` response header, or "" when absent.
Function requestIdFrom($headers : Object) : Text
	If ($headers=Null:C1517)
		return ""
	End if
	var $id : Variant:=This:C1470.lowerKeys($headers)["x-typesafe-request-id"]
	If (Value type:C1509($id)#Is text:K8:3)
		return ""
	End if
	return $id

// True when the text holds only characters a number can be read from.
Function isNumeric($value : Text) : Boolean
	If ($value="")
		return False:C215
	End if
	var $i : Integer
	For ($i; 1; Length:C16($value))
		If (Position:C15(Substring:C12($value; $i; 1); "0123456789.-+")=0)
			return False:C215
		End if
	End for
	return True:C214

/*
* Parse `retry-after-ms`, then `Retry-After` seconds, into milliseconds.
* Returns -1 when neither header carries a usable delay; HTTP-date values are not read.
*/
Function parseRetryAfterMs($headers : Object) : Integer
	If ($headers=Null:C1517)
		return -1
	End if
	var $lower : Object:=This:C1470.lowerKeys($headers)

	var $ms : Text:=String:C10($lower["retry-after-ms"])
	If (This:C1470.isNumeric($ms) && (Num:C11($ms)>=0))
		return Num:C11($ms)
	End if

	var $raw : Text:=String:C10($lower["retry-after"])
	If (This:C1470.isNumeric($raw) && (Num:C11($raw)>=0))
		return Num:C11($raw)*1000
	End if

	return -1

// Mask a key, keeping its scheme and the last four characters of secrets longer than eight.
Function redactKey($value : Text) : Text
	var $at : Integer:=Position:C15(" "; $value)
	var $scheme : Text:=""
	var $secret : Text:=$value
	If ($at>0)
		$scheme:=Substring:C12($value; 1; $at-1)+" "
		$secret:=Substring:C12($value; $at+1)
	End if
	var $tail : Text:=""
	If (Length:C16($secret)>8)
		$tail:=Substring:C12($secret; Length:C16($secret)-3; 4)
	End if
	return $scheme+"***"+$tail

Function redact($name : Text; $value : Text) : Text
	var $low : Text:=Lowercase:C14($name)
	Case of 
		: (($low="authorization") || ($low="proxy-authorization") || ($low="x-api-key"))
			return This:C1470.redactKey($value)
		: (($low="cookie") || ($low="set-cookie"))
			return "***"
		Else 
			return $value
	End case 

// Copy headers with known credential values redacted.
Function redactHeaders($headers : Object) : Object
	var $out : Object:={}
	If (($headers=Null:C1517) || (Value type:C1509($headers)#Is object:K8:27))
		return $out
	End if
	var $k : Text
	For each ($k; $headers)
		$out[$k]:=This:C1470.redact($k; String:C10($headers[$k]))
	End for each 
	return $out
