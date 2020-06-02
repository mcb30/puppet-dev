# @summary
#   Construct a database password
#
# @param database
#   Database name
#
# @param user
#   User name
#
# @param server
#   Database server FQDN
#
# @return [String]
#   Password
#
function ud::database::password (
  String $database,
  String $user = $database,
  String $server = $::fqdn,
) >> String
{
  autosecret::sha256('database', $server, $database, $user)
}
