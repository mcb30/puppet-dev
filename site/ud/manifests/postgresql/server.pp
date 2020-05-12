# @summary
#   Install PostgreSQL server
#
class ud::postgresql::server {

  # Require a LetsEncrypt certificate
  #
  require ud::cert

  # Install PostgreSQL server
  #
  require postgresql::server

  # Ensure postgres user is able to read LetsEncrypt private keys
  #
  ud::groupmember { 'postgres certkeys':
    user => 'postgres',
    group => 'certkeys',
  }

  # Configure TLS
  #
  postgresql::server::config_entry { 'ssl':
    value => 'on',
  }
  postgresql::server::config_entry { 'ssl_cert_file':
    value => "/etc/letsencrypt/live/${::fqdn}/fullchain.pem",
  }
  postgresql::server::config_entry { 'ssl_key_file':
    value => "/etc/letsencrypt/live/${::fqdn}/privkey.pem",
  }

  # Configure pg_hba.conf
  #
  postgresql::server::pg_hba_rule { 'Allow locally mapped users':
    type => 'local',
    database => 'all',
    user => 'all',
    auth_method => 'ident',
    auth_option => 'map=ud',
    order => '001a',  # Thanks for leaving space, guys!
  }
  postgresql::server::pg_hba_rule { 'Allow TLS logins via IPv6':
    type => 'hostssl',
    database => 'all',
    user => 'all',
    address => '::/0',
    auth_method => 'md5',
    order => 50,
  }
  postgresql::server::pg_hba_rule { 'Allow TLS logins via IPv4':
    type => 'hostssl',
    database => 'all',
    user => 'all',
    address => '0.0.0.0/0',
    auth_method => 'md5',
    order => 50,
  }

  # Configure pg_ident.conf global rule
  #
  # Our 'map=ud' rule in pg_hba.conf will match before the usual rule
  # that permits ident authentication as the matching database user.
  # This rule recreates this functionality within the map.
  #
  postgresql::server::pg_ident_rule { "${localuser} ${dbuser}":
    map_name => 'ud',
    system_username => '/^(.*)$',
    database_username => '\1',
    order => 900,
  }

}
