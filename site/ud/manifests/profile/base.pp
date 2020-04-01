class ud::profile::base {

  # Manage users and SSH keys
  #
  create_resources('ud::user', lookup('ud::users', {merge => 'deep'}))

  # Install packages
  #
  package { lookup('ud::packages', {merge => 'unique'}):
    ensure => 'present',
  }

}
