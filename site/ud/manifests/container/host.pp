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

  # Allow containers to access host certificates
  #
  selinux::module { 'container-cert':
    ensure => 'present',
    builder => 'simple',
    source_te => "puppet:///modules/${module_name}/container-cert.te",
  }

}
