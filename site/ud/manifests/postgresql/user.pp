# @summary
#   Create PostgreSQL user
#
# This is intended to be invoked automatically by
# [`ud::postgresql::database`](#udpostgresqldatabase).  You should not
# need to use this defined type directly.
#
# @param database
#   Database name
#
# @param username
#   User name
#
# @param owner
#   Database owner user name
#
# @param privileges
#   Privileges to be granted by default on new objects
#
# @param paths
#   Configuration file paths in which to save connection information
#
define ud::postgresql::user (
  String $database,
  String $username = $name,
  String $owner = $username,
  Optional[Array[String]] $privileges = undef,
  Hash $paths = {},
)
{

  # Ensure PostgreSQL is installed
  #
  include postgresql::server

  # Calculate password using autosecret
  #
  $password = autosecret::sha256('database', $username)

  # Create PostgreSQL user
  #
  postgresql::server::role { $username:
    password_hash => postgresql_password($username, $password),
    before => Postgresql::Server::Database[$database],
  }

  # Set default privileges
  #
  if ($privileges) {
    ud::postgresql::default_grant { "${database} ${username} default grant":
      database => $database,
      owner => $owner,
      username => $username,
      privileges => $privileges,
      objtype => 'TABLES',
    }
  }

  # Set connection privileges
  #
  postgresql::server::database_grant { "${database} ${username} database grant":
    db => $database,
    role => $username,
    privilege => 'CONNECT',
    require => Postgresql::Server::Database[$database],
  }

  # Calculate connection strings
  #
  $port = $postgresql::params::port
  $dbapi = "postgresql://${username}:${password}@${::fqdn}:${port}/${database}"

  # Store required configuration
  #
  ud::config::lookup { "${database} ${username} database config":
    paths => $paths,
    values => {
      username => $username,
      password => $password,
      host => $::fqdn,
      port => $port,
      dbapi => $dbapi,
    },
  }

}
