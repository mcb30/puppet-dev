function autosecret::sha1 (
  String *$nonces
) >> String
{
  autosecret::hash('sha1', *$nonces )
}
