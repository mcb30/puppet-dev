# @summary
#   Puppet master role
#
class ud::role::puppet::master {
  include ud::profile::base
  include ud::profile::puppet::master
}
