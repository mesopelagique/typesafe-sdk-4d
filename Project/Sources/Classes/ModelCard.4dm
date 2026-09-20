// One entry of GET /v1/models.

property name : Text
property description : Text
property releaseDate : Text

Class constructor($card : Object)
	If ($card=Null:C1517)
		return 
	End if
	This:C1470.name:=String:C10($card.name)
	This:C1470.description:=String:C10($card.description)
	This:C1470.releaseDate:=String:C10($card.releaseDate || $card.release_date)
