define ud::user (
  String $user = $title,
  String $ensure = 'present',
  Boolean $sudo = true,
  Array[String] $keys = [],
  Array[String] $groups = [],
)
{

  # Home directory
  #
  $home = $user ? { 'root' => '/root', default => "/home/${user}" }

  # Extra groups
  #
  $extras = ($sudo and $user != 'root') ? { true => ['wheel'], false => [] }

  # User account
  #
  user { $user:
    ensure => $ensure,
    home => $home,
    managehome => true,
    purge_ssh_keys => true,
    membership => 'minimum',
    groups => $groups + $extras,
  }

  # SSH key
  #
  $keys.each |String $key| {

    $key_split = split($key, /\s+/)

    # User key
    #
    ssh_authorized_key { "${key_split[2]} (${user})":
      ensure => $ensure,
      user => $user,
      type => $key_split[0],
      key => $key_split[1],
    }

  }

}
