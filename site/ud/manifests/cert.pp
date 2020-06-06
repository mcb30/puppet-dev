# @summary
#   Obtain LetsEncrypt certificate
#
# This is intended to be included automatically by manifests that
# define the mechanism used for certificate renewal, such as
# [`ud::profile::apache`](#udprofileapache).  You should not need to
# use this resource class directly.
#
# @param aliases
#   Fully qualified DNS names to be included within the certificate
#
# @param deploy_hook_commands
#   Commands to be run after a certificate deployment
#
# @param webroot
#   Web root directory (for when using the webroot plugin)
#
# @param group
#   Group granted access to the certificate's private key
#
# @param mode
#   Access mode (e.g. '0640') for the certificate's private key
#
class ud::cert (
  Array[String] $aliases = [],
  Array[String] $deploy_hook_commands = [],
  Optional[String] $webroot = undef,
  String $group = 'certkeys',
  String $mode = '0640',
)
{

  include ::letsencrypt

  # Ensure certificates are readable by non-root services
  #
  file { '/etc/letsencrypt/live':
    ensure => 'directory',
    mode => '0755',
  }
  file { '/etc/letsencrypt/archive':
    ensure => 'directory',
    mode => '0755',
  }

  # Group to allow for key to be readable by non-root services
  #
  if ! defined(Group[$group]) {
    group { $group:
      ensure => 'present',
      system => true,
    }
  }

  # Construct common arguments for both staging and production environments
  #
  $args = {
    domains => [$::fqdn] + $aliases,
    plugin => $webroot ? { undef => 'standalone', default => 'webroot' },
    webroot_paths => $webroot ? { undef => [], default => [$webroot] },
  }

  # Issue certificate from staging environment to verify connectivity
  #
  letsencrypt::certonly { "${::fqdn}-staging":
    * => $args,
    additional_args => ['--staging'],
  }

  # Issue certificate from production environment
  #
  letsencrypt::certonly { $::fqdn:
    * => $args,
    deploy_hook_commands => [
      "chgrp ${group} \${RENEWED_LINEAGE}/privkey.pem",
      "chmod ${mode} \${RENEWED_LINEAGE}/privkey.pem",
    ] + $deploy_hook_commands,
  }

  # Ensure renewal timer is running
  #
  service { 'certbot-renew.timer':
    ensure => 'running',
    require => Package['letsencrypt'],
  }

}
