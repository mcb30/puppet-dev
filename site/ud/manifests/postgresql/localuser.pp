# @summary
#   Configure PostgreSQL peer authentication
#
# Configure PostgreSQL to permit passwordless peer authentication for
# an operating system user for a list of database users.
#
# @param localuser
#   Operating system local user
#
# @param dbusers
#   List of database users
#
# @param map_name
#   Ident map name
#
define ud::postgresql::localuser (
  String $localuser = $name,
  Array[String] $dbusers = [],
  String $map_name = 'ud',
)
{

  # Permit peer authentication for each local user
  #
  $dbusers.each |String $dbuser| {
    postgresql::server::pg_ident_rule { "${localuser} ${dbuser}":
      map_name => $map_name,
      system_username => $localuser,
      database_username => $dbuser,
    }
  }

}
