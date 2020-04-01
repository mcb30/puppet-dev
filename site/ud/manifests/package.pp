define ud::package (
  String $ensure = 'present',
)
{

  # Install package, if not already managed elsewhere
  #
  if ! defined(Package[$name]) {
    package { $name:
      ensure => $ensure,
    }
  }

}
