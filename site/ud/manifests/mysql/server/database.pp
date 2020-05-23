# @summary
#   Configure MySQL database on database server
#
# This is intended to be invoked automatically by
# [`ud::mysql::database`](#udmysqldatabase).  You should not need to
# use this defined type directly.
#
# @param name
#   Database name
#
define ud::mysql::server::database (
)
{

  # Ensure MySQL is installed
  #
  include ud::mysql::server

  # Create database
  #
  mysql_database { $name:
    ensure => 'present',
    require => Class['mysql::client'],
  }

  # Allow peer authentication for this database
  #
  Ud::Mysql::Server::Peerauth <| |> {
    databases +> [$name],
  }

}
