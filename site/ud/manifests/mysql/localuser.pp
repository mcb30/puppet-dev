# @summary
#   Configure MySQL for operating system local users
#
# This is intended to be invoked automatically by
# [`ud::mysql::user`](#udmysqluser).  You should not need to use this
# defined type directly.
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
define ud::mysql::localuser (
  Boolean $sudo,
  String $home,
)
{

  # Create virtual resource to allow peer authentication for privileged users
  #
  if ($sudo) {
    @ud::mysql::server::peerauth { $name:
    }
  }

}
