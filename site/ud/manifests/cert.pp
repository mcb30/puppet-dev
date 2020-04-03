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

  # Issue certificate
  #
  letsencrypt::certonly { $::fqdn:
    domains => [$::fqdn] + $aliases,
    plugin => $webroot ? { undef => 'standalone', default => 'webroot' },
    webroot_paths => $webroot ? { undef => [], default => [$webroot] },
    deploy_hook_commands => [
      "chgrp ${group} \${RENEWED_LINEAGE}/privkey.pem",
      "chmod ${mode} \${RENEWED_LINEAGE}/privkey.pem",
    ] + $deploy_hook_commands,
  }

  # Ensure renewal timer is running
  #
  service { 'certbot-renew.timer':
    ensure => 'running',
  }

}
