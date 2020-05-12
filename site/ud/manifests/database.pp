# @summary
#   Create database
#
# Create a database with three users: an owner (with full access), a
# writer (with the ability to change data), and a reader (with the
# ability only to read existing data).
#
# @param database
#   Database name
#
# @param type
#   Database type
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
  String $database = $name,
  Enum['postgresql'] $type = 'postgresql',
  String $owner_name = $name,
  Hash $owner = {},
  String $writer_name = "${name}_writer",
  Hash $writer = {},
  String $reader_name = "${name}_reader",
  Hash $reader = {},
)
{

  # Proxy to appropriate database type
  #
  create_resources($type ? {
    'postgresql' => 'ud::postgresql::database',
  }, {
    $database => {
      owner_name => $owner_name,
      owner => $owner,
      writer_name => $writer_name,
      writer => $writer,
      reader_name => $reader_name,
      reader => $reader,
    }
  })

}
