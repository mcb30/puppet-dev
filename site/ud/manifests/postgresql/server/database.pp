# @summary
#   Configure PostgreSQL database on database server
#
# This is intended to be invoked automatically by
# [`ud::postgresql::database`](#udpostgresqldatabase).  You should not
# need to use this defined type directly.
#
# @param name
#   Database name
#
# @param owner
#   Database owner user name
#
define ud::postgresql::server::database (
  String $owner = $name,
)
{

  # Ensure PostgreSQL is installed
  #
  include ud::postgresql::server

  # Create database
  #
  postgresql::server::database { $name:
    owner => $owner,
  }

  # Revoke default public rights on schema
  #
  postgresql::server::grant { "${name} public schema revoke":
    ensure => 'absent',
    role => 'public',
    db => $name,
    privilege => 'CREATE',
    object_type => 'schema',
    object_name => 'public',
    require => Postgresql::Server::Database[$name],
  }

  # Grant owner full rights on schema
  #
  postgresql::server::grant { "${name} ${owner} schema grant":
    role => $owner,
    db => $name,
    privilege => 'ALL',
    object_type => 'schema',
    object_name => 'public',
    require => Postgresql::Server::Database[$name],
  }

}
