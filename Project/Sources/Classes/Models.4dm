// The Models API resource. Reached through Client.models.

property client : cs:C1710.Client

Class constructor($client : cs:C1710.Client)
	This:C1470.client:=$client

// List the models available to the account.
// Returns a ModelsListResult, or the 4D.HTTPRequest when $options carries a callback.
Function list($options : Object) : Variant
	return This:C1470.client._call("/v1/models"; "GET"; Null:C1517; $options; cs:C1710.ModelsListResult)
