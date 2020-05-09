# @summary
#   Configure the Apache web server
#
# Configure the Apache web server for serving static files or a web
# application via HTTPS.
#
# @param aliases
#   Fully qualified DNS names to be added to the TLS certificate.
#
# @param docroot
#   Document root for static files.
#
# @param app_path
#   Relative URL path for a web application configured via a drop-in
#   Apache configuration file.
#
# @param app_port
#   Port number for a web application configured to run as a service
#   listening for HTTP connections to `localhost` on a non-standard
#   port.
#
# @param vhost
#   Additional virtual host configuration parameters passed through
#   directly to the `apache::vhost` Puppet class.
#
class ud::profile::apache (
  Array[String] $aliases = [],
  Optional[String] $docroot = undef,
  Optional[String] $app_path = undef,
  Optional[Integer] $app_port = undef,
  Hash $vhost = {},
)
{

  include apache
  include apache::mod::ssl

  # Allow httpd network connections
  #
  # Required for local app server (if present) and for OCSP stapling.
  #
  selinux::boolean { 'httpd_can_network_connect': }

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

  # Conditional checks for certificate existence
  #
  # Required to allow Apache to start up prior to the certificate
  # being issued.  If the certificate is not yet present, then we
  # temporarily use the default (localhost) certificate.
  #
  $sslinc = "${apache::vhost_dir}/${::fqdn}-ssl.inc"
  $basedef = upcase(regsubst($::fqdn, '\W', '_', 'G'))
  $certdef = "SSL_CERT_${basedef}"
  $keydef = "SSL_KEY_${basedef}"
  $certfile = "/etc/letsencrypt/live/${::fqdn}/fullchain.pem"
  $keyfile = "/etc/letsencrypt/live/${::fqdn}/privkey.pem"
  $certtemp = $apache::params::default_ssl_cert
  $keytemp = $apache::params::default_ssl_key
  file { $sslinc:
    ensure => 'file',
    content => template('ud/apache-cert-check.erb'),
    owner => 'root',
    group => $apache::params::root_group,
    mode => $apache::file_mode,
    require => Package['httpd'],
    notify => Class['apache::service'],
  }

  # HTTPS virtual host
  #
  apache::vhost { "${::fqdn}-https":
    * => {
      servername => $::fqdn,
      serveraliases => $aliases,
      port => 443,
      ssl => true,
      ssl_cert => "\${${certdef}}",
      ssl_key => "\${${keydef}}",
      additional_includes => [$sslinc],
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
            "^/?(.*) ws://127.0.0.1:${app_port}/\$1 [L,NE,P]",
          ],
        }, {
          rewrite_rule => [
            "^/?(.*) http://127.0.0.1:${app_port}/\$1 [L,NE,P]",
          ],
        }],
      },
    }) + $vhost
  }

  # LetsEncrypt certificate
  #
  class { 'ud::cert':
    aliases => $aliases,
    webroot => $apache::params::docroot,
    deploy_hook_commands => [
      "systemctl reload ${apache::params::service_name}",
    ],
  }

}
