# @summary
#   Create PostgreSQL database
#
# This is intended to be invoked automatically by
# [`ud::database`](#uddatabase).  You should not need to use this
# defined type directly.
#
# @param database
#   Database name
#
# @param owner_name
#   Database owner user name
#
# @param owner
#   Configuration file paths in which to save owner connection information
#
# @param writer_name
#   Database writer user name
#
# @param writer
#   Configuration file paths in which to save writer connection information
#
# @param reader_name
#   Database reader user name
#
# @param reader
#   Configuration file paths in which to save reader connection information
#
define ud::postgresql::database (
  String $database = $name,
  String $owner_name = $name,
  Hash $owner = {},
  String $writer_name = "${name}_writer",
  Hash $writer = {},
  String $reader_name = "${name}_reader",
  Hash $reader = {},
)
{

  # Ensure PostgreSQL is installed
  #
  include ud::postgresql::server

  # Create database
  #
  postgresql::server::database { $database:
    owner => $owner_name,
  }

  # Revoke default public rights on schema
  #
  postgresql::server::grant { "${database} public schema revoke":
    role => 'public',
    db => $database,
    privilege => 'CREATE',
    object_type => 'schema',
    object_name => 'public',
    ensure => 'absent',
    require => Postgresql::Server::Database[$database],
  }

  # Grant owner full rights on schema
  #
  postgresql::server::grant { "${database} ${owner_name} schema grant":
    role => $owner_name,
    db => $database,
    privilege => 'ALL',
    object_type => 'schema',
    object_name => 'public',
    require => Postgresql::Server::Database[$database],
  }

  # Create users
  #
  ud::postgresql::user { $owner_name:
    database => $database,
    paths => $owner,
  }
  ud::postgresql::user { $writer_name:
    database => $database,
    owner => $owner_name,
    privileges => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
    paths => $writer,
  }
  ud::postgresql::user { $reader_name:
    database => $database,
    owner => $owner_name,
    privileges => ['SELECT'],
    paths => $reader,
  }

}
