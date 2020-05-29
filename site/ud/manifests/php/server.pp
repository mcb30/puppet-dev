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

  # Use Apache
  #
  include ud::profile::apache

  # Configure PHP repos
  #
  if ($::os['family'] == 'RedHat') {
    yumrepo { 'remi-modular':
      descr => 'Remi\'s RPM repository (PHP)',
      mirrorlist => ($::os['name'] ? {
        'Fedora' => "${remi}/fedora/\$releasever/modular/\$basearch/mirror",
        'CentOS' => "${remi}/enterprise/\$releasever/modular/\$basearch/mirror",
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
  if ($::os['family'] == 'RedHat') {
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
