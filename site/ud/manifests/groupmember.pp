# @summary
#   Manage group membership
#
# Puppet's resource model for group memberships is, quite simply,
# moronic.  It provides no sensible way to express the concept "user A
# (which is not managed by Puppet) should be a member of group B
# (which is not managed by this manifest)".
#
# Provide this shell script monstrosity as a workaround.
#
# @param user
#   User name
#
# @param group
#   Group name
#
define ud::groupmember (
  String $user,
  String $group,
)
{

  # Add user to group the nasty way
  #
  exec { "${user} ${group} membership":
    path => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    command => "gpasswd --add ${user} ${group}",
    unless => "id -Gn ${user} | grep -w ${group}",
  }

  # Defer until after creation of corresponding user and group, if
  # those happen to be managed by Puppet
  #
  User <| name == $user |> -> Exec["${user} ${group} membership"]
  Group <| name == $group |> -> Exec["${user} ${group} membership"]

}
