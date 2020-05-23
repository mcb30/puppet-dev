# @summary
#   Configure MySQL server
#
class ud::mysql::server {

  # Require a LetsEncrypt certificate
  #
  require ud::cert

  # Install MySQL server
  #
  # The 'ssl-ca' option is irrelevant since we are not using client
  # certificates, but Puppet defaults to setting a path to a
  # nonexistent file, which prevents MySQL from enabling TLS support.
  #
  class { 'mysql::server':
    override_options => {
      'mysqld' => {
        'bind-address' => '::',
        'ssl' => true,
        'ssl-cert' => "/etc/letsencrypt/live/${::fqdn}/fullchain.pem",
        'ssl-key' => "/etc/letsencrypt/live/${::fqdn}/privkey.pem",
        'ssl-ca' => '/etc/pki/tls/certs/ca-bundle.crt',
      },
    },
  }

  # Ensure mysql user is able to read LetsEncrypt private keys
  #
  ud::groupmember { 'mysql certkeys':
    user => 'mysql',
    group => 'certkeys',
  }

  # Install unix_socket plugin
  #
  mysql_plugin { 'unix_socket':
    soname => 'auth_socket.so',
  }

}
