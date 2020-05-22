# @summary
#   Base functionality for `ud::user`
#
# This is included automatically by [`ud::user`](#uduser).  You should
# not need to use this class directly.
#
class ud::user::base {

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

}
