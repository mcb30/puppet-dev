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

}
