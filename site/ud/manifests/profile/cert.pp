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

}
