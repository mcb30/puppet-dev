# @summary
#   Configure MySQL user
#
# This is intended to be invoked automatically by
# [`ud::mysql::database`](#udmysqldatabase).  You should not need to
# use this defined type directly.
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
# @param privileges
#   Privileges to be granted by default on new objects
#
# @param configs
#   Configuration file paths in which to save connection information
#
define ud::mysql::user (
  String $database,
  String $server = $::fqdn,
  Optional[Array[String]] $privileges = undef,
  Hash $configs = {},
)
{

  # Instantiate virtual resources created by ud::user
  #
  Ud::Mysql::Localuser <| tag == 'ud::user' |>

  # Calculate password using autosecret
  #
  $password = autosecret::sha256('database', $server, $database, $name)

  # Calculate connection strings
  #
  $port = 3306
  $url = "mysql://${name}:${password}@${server}:${port}/${database}?ssl=1"

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
    ud::mysql::server::user { $name:
      database => $database,
      password => $password,
      privileges => $privileges,
    }
  }

}
