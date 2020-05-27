# @summary
#   Configure database
#
# Configure a database with three users: an owner (with full access),
# a writer (with the ability to change data), and a reader (with the
# ability only to read existing data).
#
# @param name
#   Database name
#
# @param type
#   Database type
#
# @param server
#   Database server
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
define ud::database (
  Enum['postgresql', 'mariadb', 'mysql'] $type = 'postgresql',
  String $server = $::fqdn,
  String $owner_name = $name,
  Hash $owner = {},
  String $writer_name = "${name}_writer",
  Hash $writer = {},
  String $reader_name = "${name}_reader",
  Hash $reader = {},
)
{

  # Construct database server FQDN
  #
  $serverfqdn = '.' in $server ? {
    true => $server,
    false => "${server}.${::domain}",
  }

  # Instantiate appropriate database type
  #
  create_resources($type ? {
    'postgresql' => 'ud::postgresql::database',
    'mariadb' => 'ud::mysql::database',
    'mysql' => 'ud::mysql::database',
  }, {
    $name => {
      server => $serverfqdn,
      owner => $owner_name,
      owner_configs => $owner,
      writer => $writer_name,
      writer_configs => $writer,
      reader => $reader_name,
      reader_configs => $reader,
    }
  })

}
