class ud::profile::cert (
  Array[String] $aliases = [],
  Optional[String] $webroot = undef,
)
{

  include ::letsencrypt

  # Issue certificate
  #
  letsencrypt::certonly { $trusted['certname']:
    domains => [$::fqdn] + $aliases,
    plugin => $webroot ? { undef => 'standalone', default => 'webroot' },
    webroot_paths => $webroot ? { undef => [], default => [$webroot] },
  }

  # Ensure renewal timer is running
  #
  service { 'certbot-renew.timer':
    ensure => 'running',
  }

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

  # Allow for key to be readable by non-root services
  #
  group { 'certkeys':
    ensure => 'present',
    system => true,
  }
  file { "/etc/letsencrypt/live/${::fqdn}/privkey.pem":
    ensure => 'file',
    links => 'follow',
    content => '',
    replace => false,
    mode => '0640',
    group => 'certkeys',
  }

}
