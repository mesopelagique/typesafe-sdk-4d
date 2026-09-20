//%attributes = {}
// Runnable asynchronous demo for the TypeSafe 4D SDK.
// Requires TYPESAFE_API_KEY in the environment.
//
// The callbacks are delivered in the process that started the request, so that process
// has to still be alive when the answer arrives: run the call from a worker or a form,
// never from a process that ends with the method.

If (cs:C1710._Env.me.read(cs:C1710._Constants.me.apiKeyEnv())="")
	LOG EVENT:C667(Into system standard outputs:K38:9; "[demo] "+cs:C1710._Constants.me.apiKeyEnv()+" is not set; nothing to do.\n"; Error message)
	return 
End if

CALL WORKER:C1389("typesafe-demo"; Formula:C1597(_demoTypesafeSend))
