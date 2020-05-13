# @summary
#   Configure PostgreSQL for operating system local users
#
# This is intended to be invoked automatically by
# [`ud::postgresql::user`](#udpostgresqluser).  You should not need to
# use this defined type directly.
#
# @param name
#   Operating system local user name
#
# @param sudo
#   User is privileged
#
# @param home
#   User home directory
#
define ud::postgresql::localuser (
  Boolean $sudo,
  String $home,
)
{

  # Fix PostgreSQL TLS certificate verification
  #
  file { "${home}/.postgresql":
    ensure => 'directory',
    owner => $name,
    group => $name,
  }
  file { "${home}/.postgresql/root.crt":
    ensure => 'link',
    target => '/etc/pki/tls/certs/ca-bundle.crt',
    owner => $name,
    group => $name,
    replace => false,
  }

  # Create virtual resource to allow peer authentication for privileged users
  #
  if ($sudo) {
    @ud::postgresql::server::peerauth { $name:
    }
  }

}
