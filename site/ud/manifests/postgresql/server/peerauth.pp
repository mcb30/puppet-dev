# @summary
#   Configure PostgreSQL peer authentication
#
# Configure PostgreSQL to permit passwordless peer authentication for
# an operating system local user as a list of database users.
#
# @param name
#   Operating system local user name
#
# @param dbusers
#   List of database users
#
# @param map
#   Ident map name
#
define ud::postgresql::server::peerauth (
  Array[String] $dbusers = [],
  String $map = 'ud',
)
{

  # Permit peer authentication as each database user
  #
  $dbusers.each |String $dbuser| {
    postgresql::server::pg_ident_rule { "${name} ${dbuser}":
      map_name => $map,
      system_username => $name,
      database_username => $dbuser,
    }
  }

}
