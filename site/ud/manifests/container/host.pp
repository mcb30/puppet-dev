class ud::container::host (
)
{

  # Install podman
  #
  package { 'podman':
    ensure => 'installed',
  }

  # Configure networking
  #
  file { '/etc/cni/net.d/50-ud-bridge.conflist':
    ensure => 'file',
    source => "puppet:///modules/${module_name}/50-ud-bridge.conflist",
  }

}
