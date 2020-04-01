class ud::profile::apache (
  Array[String] $aliases = [],
  Optional[String] $docroot = undef,
  Optional[String] $app_path = undef,
  Optional[Integer] $app_port = undef,
  Hash $vhost = {},
)
{

  include ::apache

  $ssl_dir = "/etc/letsencrypt/live/${::fqdn}"
  $ssl_fullchain = "${ssl_dir}/fullchain.pem"
  $ssl_key = "${ssl_dir}/privkey.pem"

  # Allow httpd network connections
  #
  # Required for local app server (if present) and for OCSP stapling.
  #
  selinux::boolean { 'httpd_can_network_connect': }

  # Ensure httpd can start up before certificates are issued
  #
  file { $ssl_dir:
    ensure => 'directory',
  }
  file { $ssl_fullchain:
    ensure => 'link',
    target => $apache::default_ssl_cert,
    replace => false,
  }
  file { $ssl_key:
    ensure => 'link',
    target => $apache::default_ssl_key,
    replace => false,
  }

  # HTTP virtual host
  #
  apache::vhost { "${::fqdn}-http":
    servername => $::fqdn,
    serveraliases => $aliases,
    port => 80,
    docroot => false,
    manage_docroot => false,
    access_log => false,
    error_log => false,
    rewrites => [{
      rewrite_rule => [
        '^/?\.well-known - [L]',
        '^/?(.*) https://%{SERVER_NAME}/$1 [L,NE,R=permanent]',
      ],
    }],
  }

  # HTTPS virtual host
  #
  apache::vhost { "${::fqdn}-https":
    * => {
      servername => $::fqdn,
      serveraliases => $aliases,
      port => 443,
      ssl => true,
      ssl_cert => $ssl_fullchain,
      ssl_key => $ssl_key,
      docroot => $docroot ? { undef => false, default => $docroot },
      manage_docroot => false,
      access_log => false,
      error_log => false,
      headers => [
        'always set Strict-Transport-Security max-age=31536000',
      ],
    } + ($app_path ? {
      undef => {},
      default => {
        rewrites => [{
          rewrite_rule => ["^/?\$ ${app_path} [L,R]"],
        }],
      },
    }) + ($app_port ? {
      undef => {},
      default => {
        rewrites => [{
          rewrite_cond => [
            '${HTTP:Upgrade} websocket [NC]',
            '${HTTP:Connection} upgrade [NC]',
          ],
          rewrite_rule => [
            "^/?(.*) ws://localhost:${app_port}/\$1 [L,NE,P]",
          ],
        }, {
          rewrite_rule => [
            "^/?(.*) http://localhost:${app_port}/\$1 [L,NE,P]",
          ],
        }],
      },
    }) + $vhost
  }

  # LetsEncrypt certificate
  #
  class { 'ud::profile::cert':
    aliases => $aliases,
    webroot => $apache::params::webroot,
  }

}
