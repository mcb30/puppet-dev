# @summary
#   Configure a PHP application server
#
# @param version
#   PHP version
#
class ud::php::server (
  String $version = '7.4',
)
{

  # PHP repository locations
  #
  $remi = 'http://cdn.remirepo.net'

  # Use Remi PHP repository only for CentOS
  #
  # At the time of writing, the Remi PHP repository for Fedora is
  # broken since it includes dependencies that do not exist in
  # upstream Fedora (libzip >= 1.6).  Fedora includes a wider variety
  # of PHP packages than CentOS and so a reasonable compromise seems
  # to be to ignore the Remi PHP repositories for Fedora.
  #
  $use_remi = ($::os['name'] == 'CentOS')

  # Use Apache
  #
  include ud::profile::apache

  # Configure PHP repos
  #
  if ($::os['family'] == 'RedHat') {
    yumrepo { 'remi-modular':
      descr => 'Remi\'s RPM repository (PHP)',
      enabled => $use_remi,
      mirrorlist => ($::os['name'] ? {
        'Fedora' => "${remi}/fedora/\$releasever/modular/\$basearch/mirror",
        'CentOS' => "${remi}/enterprise/\$releasever/modular/\$basearch/mirror",
      }),
      gpgkey => ("${::os['name']}${::os['release']['major']}" ? {
        'CentOS8' => 'https://rpms.remirepo.net/RPM-GPG-KEY-remi2018',
        'Fedora31' => 'https://rpms.remirepo.net/RPM-GPG-KEY-remi2019',
        'Fedora32' => 'https://rpms.remirepo.net/RPM-GPG-KEY-remi2020',
      }),
      tag => ['php'],
    }
  }

  # Enable an appropriate PHP repo module
  #
  # This is slightly complicated by the facts that:
  #
  # a) the installed Puppet versions may not directly support DNF
  #    modules, necessitating the use of a custom exec resource
  #
  # b) there is no trivial way to specify "use the latest PHP version"
  #
  if ($use_remi) {
    exec { 'PHP module reset':
      path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
      command => 'dnf module reset -y php',
      unless => "dnf --cacheonly module list --installed php:remi-${version}",
      tag => ['phpmod'],
    } ~> exec { 'PHP module selection':
      path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
      command => "dnf module install -y php:remi-${version}",
      refreshonly => true,
      tag => ['phpmod'],
    }
  }

  # Install php-fpm
  #
  package { 'php-fpm':
    ensure => 'present',
    tag => 'php',
  } -> service { 'php-fpm':
    ensure => 'running',
    enable => true,
  }

  # Enforce ordering of the custom execs
  #
  Yumrepo <| tag == 'php' |> -> Exec <| tag == 'phpmod' |>
  Exec <| tag == 'phpmod' |> -> Package <| tag == 'php' |>

}
