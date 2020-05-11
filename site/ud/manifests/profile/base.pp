# @summary
#   Common base profile applied to all machines
#
# This profile is applied automatically to all machines.  It is used
# to give effect to various automagical YAML parameters such as
# [`ud::users`](README.md#udusers) and
# [`ud::packages`](README.md#udpackages).
#
class ud::profile::base {

  # Manage users and SSH keys
  #
  create_resources('ud::user', lookup('ud::users', Hash, 'deep', {}))

  # Install packages
  #
  ud::package { lookup('ud::packages', Array[String], 'unique', []): }

  # Ensure wheel group exists
  #
  if ! defined(Group['wheel']) {
    group { 'wheel':
      ensure => 'present',
      system => true,
    }
  }

  # Ensure created users can use sudo
  #
  file { '/etc/sudoers.d/ud-wheel-users':
    ensure => 'file',
    content => '%wheel ALL=(ALL) NOPASSWD: ALL',
    mode => '0440',
  }

  # Manage containers
  #
  create_resources('ud::container', lookup('ud::containers', Hash, 'deep', {}))

  # Deploy databases
  #
  create_resources('ud::database', lookup('ud::databases', Hash, 'deep', {}))

  # Deploy webservers
  #
  $web = ud::hashlookup('ud::web')
  if ($web) {
    class { 'ud::profile::apache':
      * => $web
    }
  }

  # Apply static configuration
  #
  ud::config { 'ud::configs':
    values => ud::hashlookup('ud::configs', {}),
  }

}
