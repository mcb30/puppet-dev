# @summary
#   Configure PostgreSQL database
#
# This is intended to be invoked automatically by
# [`ud::database`](#uddatabase).  You should not need to use this
# defined type directly.
#
# @param name
#   Database name
#
# @param server
#   Database server FQDN
#
# @param owner
#   Database owner user name
#
# @param owner_configs
#   Configuration file paths in which to save owner connection information
#
# @param writer
#   Database writer user name
#
# @param writer_configs
#   Configuration file paths in which to save writer connection information
#
# @param reader
#   Database reader user name
#
# @param reader_configs
#   Configuration file paths in which to save reader connection information
#
define ud::postgresql::database (
  String $server = $::fqdn,
  String $owner = $name,
  Hash $owner_configs = {},
  String $writer = "${name}_writer",
  Hash $writer_configs = {},
  String $reader = "${name}_reader",
  Hash $reader_configs = {},
)
{

  # Configure database client
  #
  include postgresql::client

  # Configure database server, if applicable
  #
  if ($server == $::fqdn) {
    ud::postgresql::server::database { $name:
      owner => $owner,
    }
  }

  # Configure database owner user
  #
  ud::postgresql::user { $owner:
    database => $name,
    server => $server,
    configs => $owner_configs,
  }

  # Configure database writer user
  #
  ud::postgresql::user { $writer:
    database => $name,
    server => $server,
    owner => $owner,
    privileges => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
    configs => $writer_configs,
  }

  # Configure database reader user
  #
  ud::postgresql::user { $reader:
    database => $name,
    server => $server,
    owner => $owner,
    privileges => ['SELECT'],
    configs => $reader_configs,
  }

}
