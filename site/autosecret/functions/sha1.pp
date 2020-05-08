# @summary
#   Construct a secret value using SHA-1
#
# @param nonces [String]
#   List of nonce values used to identify the secret
#
# @return [String]
#   Secret value
#
function autosecret::sha1 (
  String *$nonces
) >> String
{
  autosecret::hash('sha1', *$nonces )
}
