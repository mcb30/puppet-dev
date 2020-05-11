# @summary
#   Set PostgreSQL default privileges
#
# The PostgreSQL Puppet module does not provide any way to handle
# default permissions for as-yet-uncreated objects.
#
# This is intended to be invoked automatically by
# [`ud::postgresql::user`](#udpostgresqluser).  You should not need to
# use this defined type directly.
#
# @param database
#   Database name
#
# @param owner
#   Database owner name
#
# @param username
#   User for whom to set default permissions
#
# @param privileges
#   List of privileges
#
# @param objtype
#   Object type
#
define ud::postgresql::default_grant (
  String $database = $name,
  String $owner,
  String $username,
  Array[Enum[
    'SELECT',
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'REFERENCES',
    'TRIGGER',
    'CREATE',
    'CONNECT',
    'TEMPORARY',
    'EXECUTE',
    'USAGE'
  ]] $privileges = [],
  Enum[
    'TABLES',
    'SEQUENCES',
    'FUNCTIONS',
    'TYPES',
    'SCHEMAS'
  ] $objtype = 'TABLES',
)
{

  # Get internal object type representation
  #
  $objtypekey = $objtype ? {
    'TABLES' => 'r',
    'SEQUENCES' => 's',
    'FUNCTIONS' => 'f',
    'TYPES' => 'T',
    'SCHEMAS' => 'n',
  }

  # Get internal privileges representation
  #
  $privkey = $privileges.map |String $privilege| {
    $privilege ? {
      'SELECT' => 'r',
      'INSERT' => 'a',
      'UPDATE' => 'w',
      'DELETE' => 'd',
      'TRUNCATE' => 'D',
      'REFERENCES' => 'x',
      'TRIGGER' => 't',
      'CREATE' => 'C',
      'CONNECT' => 'c',
      'TEMPORARY' => 'T',
      'EXECUTE' => 'X',
      'USAGE' => 'U',
    }
  }.join('')
  $privlist = $privileges.join(', ')

  # Construct SQL statements
  #
  $revoke = "ALTER DEFAULT PRIVILEGES FOR ROLE ${owner}
	     REVOKE ALL ON ${objtype} FROM ${username}"
  $grant = "ALTER DEFAULT PRIVILEGES FOR ROLE ${owner}
	    GRANT ${privlist} ON ${objtype} TO ${username}"
  $exists = "SELECT true FROM pg_default_acl WHERE
	     defaclrole = '${owner}'::regrole AND
	     defaclobjtype = '${objtypekey}' AND
	     defaclacl @> '{${username}=${privkey}/${owner}}'::aclitem[]"

  # Execute SQL
  #
  $psql_revoke = "${owner} ${username} ${objtype} revoke"
  $psql_grant = "${owner} ${username} ${objtype} grant"
  postgresql_psql { $psql_revoke:
    db => $database,
    command => $revoke,
    unless => $exists,
    require => [
      Postgresql::Server::Database[$database],
      Postgresql::Server::Role[$owner],
      Postgresql::Server::Role[$username],
    ],
  }
  if ($privileges != '') {
    postgresql_psql { $psql_grant:
      db => $database,
      command => $grant,
      unless => $exists,
      require => Postgresql_psql[$psql_revoke],
    }
  }

}
