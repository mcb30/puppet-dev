# @summary
#   Configure PostgreSQL user
#
# This is intended to be invoked automatically by
# [`ud::postgresql::database`](#udpostgresqldatabase).  You should not
# need to use this defined type directly.
#
# @param name
#   User name
#
# @param database
#   Database name
#
# @param server
#   Database server FQDN
#
# @param owner
#   Database owner user name
#
# @param privileges
#   Privileges to be granted by default on new objects
#
# @param configs
#   Configuration file paths in which to save connection information
#
define ud::postgresql::user (
  String $database,
  String $server = $::fqdn,
  String $owner = $name,
  Optional[Array[String]] $privileges = undef,
  Hash $configs = {},
)
{

  # Instantiate virtual resources created by ud::user
  #
  Ud::Postgresql::Localuser <| tag == 'ud::user' |>

  # Calculate password using autosecret
  #
  $password = ud::database::password($database, $name, $server)

  # Calculate connection strings
  #
  $port = $postgresql::params::port
  $url = ["postgresql://${name}:${password}@${server}:${port}/${database}",
          'sslmode=verify-full'].join('?')

  # Store required connection information
  #
  ud::config::lookup { "${name} ${database} database config":
    paths => $configs,
    values => {
      username => $name,
      password => $password,
      host => $server,
      port => $port,
      url => $url,
    },
  }

  # Configure database server user, if applicable
  #
  if ($server == $::fqdn) {
    ud::postgresql::server::user { $name:
      database => $database,
      password => $password,
      owner => $owner,
      privileges => $privileges,
    }
  }

}
