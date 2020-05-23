# @summary
#   Configure MySQL user on database server
#
# This is intended to be invoked automatically by
# [`ud::mysql::user`](#udmysqluser).  You should not need to use this
# defined type directly.
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
# @param privileges
#   Privileges to be granted by default on new objects
#
define ud::mysql::server::user (
  String $database,
  String $password,
  Array[String] $privileges = ['ALL'],
)
{

  # Create MySQL user
  #
  mysql_user { "${name}@%":
    password_hash => mysql::password($password),
    tls_options => ['SSL'],
  }

  # Set privileges
  #
  mysql_grant { "${name}@%/${database}.*":
    user => "${name}@%",
    table => "${database}.*",
    privileges => $privileges,
  }

}
