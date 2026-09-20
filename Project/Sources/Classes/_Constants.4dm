singleton Class constructor

function apiKeyEnv() : Text
	return "TYPESAFE_API_KEY"

function baseURLEnv() : Text
	return "TYPESAFE_BASE_URL"

function defaultModelEnv() : Text
	return "TYPESAFE_DEFAULT_MODEL"

function logLevelEnv() : Text
	return "TYPESAFE_LOG_LEVEL"

function defaultBaseURL() : Text
	return "https://api.typesafe.ai"

function defaultModel() : Text
	return "jev-latest"

function sdkVersion() : Text
	return "1.0.0"

// Runtime description for the X-TypeSafe-Runtime header.
function runtime() : Text
	var $platform : Text:=(Is Windows:C1573) ? "windows" : "macos"
	return "4d/"+String:C10(Application version:C493)+" ("+$platform+")"

function defaultTimeoutMs() : Integer
	return 10000

function defaultMaxRetries() : Integer
	return 2

function defaultBackoffInitialMs() : Integer
	return 500

function defaultBackoffMaxMs() : Integer
	return 5000

function defaultBackoffJitter() : Real
	return 0.25

function defaultMaxRetryAfterMs() : Integer
	return 60000
