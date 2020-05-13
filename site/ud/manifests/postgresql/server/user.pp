# @summary
#   Configure PostgreSQL user on database server
#
# This is intended to be invoked automatically by
# [`ud::postgresql::user`](#udpostgresqluser).  You should not need to
# use this defined type directly.
#
# @param name
#   User name
#
# @param database
#   Database name
#
# @param password
#   User password
#
# @param owner
#   Database owner user name
#
# @param privileges
#   Privileges to be granted by default on new objects
#
define ud::postgresql::server::user (
  String $database,
  String $password,
  String $owner = $name,
  Optional[Array[String]] $privileges = undef,
)
{

  # Create PostgreSQL user
  #
  postgresql::server::role { $name:
    password_hash => postgresql_password($name, $password),
    before => Postgresql::Server::Database[$database],
  }

  # Set default privileges
  #
  if ($privileges) {
    ud::postgresql::server::default_grant { "${database} ${owner} ${name}":
      database => $database,
      owner => $owner,
      role => $name,
      privileges => $privileges,
      objtype => 'TABLES',
    }
  }

  # Set connection privileges
  #
  postgresql::server::database_grant { "${database} ${name}":
    db => $database,
    role => $name,
    privilege => 'CONNECT',
    require => Postgresql::Server::Database[$database],
  }

  # Allow peer authentication as this user
  #
  Ud::Postgresql::Server::Peerauth <| |> {
    dbusers +> $name,
  }

}
