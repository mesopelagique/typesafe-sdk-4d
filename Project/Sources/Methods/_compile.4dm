var $options:=New object
$options.targets:=[]
$options.generateSyntaxFile:=True
$options.generateTypingMethods:=False

var $result : Object:=Compile project($options)

If ($result.success)
	LOG EVENT(Into system standard outputs; JSON Stringify($result); Information message)
Else 
	LOG EVENT(Into system standard outputs; JSON Stringify($result); Error message)
End if 
