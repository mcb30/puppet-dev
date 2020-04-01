define ud::user (
  String $ensure = 'present',
  Boolean $sudo = true,
  Array[String] $keys = [],
  Array[String] $groups = [],
)
{

  # Home directory
  #
  $home = $name ? { 'root' => '/root', default => "/home/${name}" }

  # Extra groups
  #
  $extras = ($sudo and $name != 'root') ? { true => ['wheel'], false => [] }

  # User account
  #
  user { $name:
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
    ssh_authorized_key { "${key_split[2]} (${name})":
      ensure => $ensure,
      user => $name,
      type => $key_split[0],
      key => $key_split[1],
    }

  }

}
