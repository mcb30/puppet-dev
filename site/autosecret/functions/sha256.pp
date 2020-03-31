function autosecret::sha256 (
  String *$nonces
) >> String
{
  autosecret::hash('sha256', *$nonces )
}
