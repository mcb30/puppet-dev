# @summary
#   Configure a `podman` container to run as a `systemd` service
#
# This is intended to be invoked automatically by
# [`ud::profile::base`](#udprofilebase) based on the YAML dictionary
# [`ud::containers`](CONTAINERS.md).  You should not need to use this
# defined type directly.
#
# @param image
#   Container image name
#
# @param command
#   Container startup command
#
# @param description
#   `systemd` service description
#
# @param ports
#   List of exposed port mappings
#
# @param environment
#   Dictionary of environment variables
#
# @param volumes
#   Dictionary of volumes
#
# @param cert
#   Allow container to access host TLS certificate
#
# @param wrappers
#   Dictionary of host commands to map to container commands
#
define ud::container (
  String $image = $name,
  String $command = '',
  Optional[String] $description = "${name} container",
  Array[Variant[Integer, String]] $ports = [],
  Hash $environment = {},
  Hash $volumes = {},
  Boolean $cert = false,
  Hash $wrappers = {},
)
{

  $envfile = "/etc/default/${name}.env"
  $portargs = $ports.map |$x| {
    (':' in "${x}") ? {
      true => "--publish ${x}",
      false => "--publish 127.0.0.1:${x}:${x}",
    }
  }.join(' ')
  $volargs = $volumes.map |$k, $v| {
    "--volume ${k}:${v}"
  }.join(' ')

  # Configure host
  #
  include ud::container::host

  # Environment file
  #
  file { $envfile:
    ensure => 'file',
    owner => 'root',
    group => 'root',
    mode => '0640',
    content => $environment.map |$k, $v| { "${k}=${v}\n" }.join(''),
  } ~> Service["${name}.service"]

  # Certificate access
  #
  if $cert {

    # Ensure certificate exists
    #
    include ud::cert

    # Mount certificates inside container
    #
    $certargs = [
      "/etc/letsencrypt/live/${::fqdn}",
      "/etc/letsencrypt/archive/${::fqdn}",
    ].map |$x| { "--volume ${x}:${x}:ro" }.join(' ')

  } else {
    $certargs = ''
  }

  # Define systemd service
  #
  systemd::unit_file { "${name}.service":
    content => template('ud/container.service.erb'),
    enable => true,
    active => true,
  }

  # Create command wrappers
  #
  $wrappers.each |$host_cmd, $container_cmd| {
    file { "/usr/local/bin/${host_cmd}":
      ensure => 'file',
      mode => '0755',
      content => [
        "#!/bin/sh\n",
        "exec /usr/bin/podman exec -i -t ${name} ${container_cmd} \"\$@\"\n",
      ].join(''),
    }
  }

}
