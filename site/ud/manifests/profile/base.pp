class ud::profile::base {

  # Manage users and SSH keys
  #
  create_resources('ud::user', lookup('ud::users', Hash, 'deep', {}))

  # Install packages
  #
  ud::package { lookup('ud::packages', Array[String], 'unique', []): }

  # Ensure created users can use sudo
  #
  file { '/etc/sudoers.d/ud-wheel-users':
    ensure => 'file',
    content => '%wheel ALL=(ALL) NOPASSWD: ALL',
    mode => '0440',
  }

}
