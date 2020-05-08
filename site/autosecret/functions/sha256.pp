# @summary
#   Construct a secret value using SHA-256
#
# @param nonces
#   List of nonce values used to identify the secret
#
# @return [String]
#   Secret value
#
function autosecret::sha256 (
  String *$nonces
) >> String
{
  autosecret::hash('sha256', *$nonces )
}
