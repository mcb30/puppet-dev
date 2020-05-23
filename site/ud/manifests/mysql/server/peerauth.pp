# @summary
#   Configure MySQL peer authentication
#
# Configure MySQL to permit passwordless peer authentication for an
# operating system local user, with full access to a specified list of
# databases.
#
# @param name
#   Operating system local user name
#
# @param databases
#   List of databases
#
define ud::mysql::server::peerauth (
  Array[String] $databases = [],
)
{

  # Configure peer authentication
  #
  mysql_user { "${name}@localhost":
    plugin => 'unix_socket',
  }

  # Grant all privileges to each database
  #
  $databases.each |String $database| {
    mysql_grant { "${name}@localhost/${database}.*":
      user => "${name}@localhost",
      table => "${database}.*",
      privileges => 'ALL',
    }
  }

}
