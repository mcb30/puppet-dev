define ud::container (
  String $image = $name,
  String $command = '',
  Optional[String] $description = "${name} container",
  Array[Variant[Integer, String]] $ports = [],
  Hash $environment = {},
  Hash $volumes = {},
)
{

  $envfile = "/etc/default/${name}.env"
  $portargs = $ports.map |$x| {
    (':' in "${x}") ? {
      true => "--publish ${x}",
      false => "--publish ${x}:${x}",
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
  }

  # Define systemd service
  #
  systemd::unit_file { "${name}.service":
    content => template('ud/container.service.erb'),
    enable => true,
    active => true,
  }

}
