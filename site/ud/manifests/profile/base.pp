class ud::profile::base {

  # Manage users and SSH keys
  #
  create_resources('ud::user', lookup('ud::users', {merge => 'deep'}))

  # Install packages
  #
  ud::package { lookup('ud::packages', {merge => 'unique'}): }

  # Ensure created users can use sudo
  #
  file { '/etc/sudoers.d/ud-wheel-users':
    ensure => 'file',
    content => '%wheel ALL=(ALL) NOPASSWD: ALL',
    mode => '0440',
  }

}
