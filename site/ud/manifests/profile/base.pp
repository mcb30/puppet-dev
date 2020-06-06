# @summary
#   Common base profile applied to all machines
#
# This profile is applied automatically to all machines.  It is used
# to give effect to various automagical YAML parameters such as
# [`ud::users`](USERS.md) and [`ud::packages`](PACKAGES.md).
#
class ud::profile::base {

  # Manage users and SSH keys
  #
  create_resources('ud::user', lookup('ud::users', Hash, 'deep', {}))

  # Include base package requirements
  #
  include ud::package::base

  # Install packages
  #
  ud::package { lookup('ud::packages', Array[String], 'unique', []): }

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
