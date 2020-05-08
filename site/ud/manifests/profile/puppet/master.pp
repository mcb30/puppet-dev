# @summary
#   Configure Puppet master
#
# See the [design document](PUPPET.md) for detailed information.
#
# @param repo
#   Local Puppet repository name
#
class ud::profile::puppet::master (
  Optional[String] $repo = $facts['puppet_repo'],
)
{

  # Require a LetsEncrypt certificate (acquired through any means) for
  # use by the webhook service
  #
  include ud::cert

  # Base directory to which this repository is deployed via r10k
  #
  $basedir = "${settings::codedir}/unipart"

  # Hiera YAML configuration
  #
  $keysdir = "${settings::confdir}/keys"
  $hiera_eyaml_paths = [
    'nodes/%{trusted.certname}.eyaml',
    'nodes/%{trusted.hostname}.eyaml',
    'common.eyaml',
  ]
  $hiera_yaml_paths = [
    'nodes/%{trusted.certname}.yaml',
    'nodes/%{trusted.hostname}.yaml',
    'nodes/%{facts.hostprefix}.yaml',
    'os/%{facts.os.name}%{facts.os.major}.yaml',
    'os/%{facts.os.name}.yaml',
    'os/%{facts.os.family}.yaml',
    'common.yaml',
  ]

  # Local Puppet repository configuration
  #
  $repohost = 'git.unipart.io'
  $repourl = "git@${repohost}:${repo}.git"
  $keyfile = "${settings::confdir}/id_deploy"

  # r10k webhook configuration
  #
  $hookport = '8088'
  $hookuser = 'puppet'
  $hookpass = autosecret::sha256('r10k', 'webhook')

  # Install packages required for unipart-puppet-setup tool
  #
  package { ['python3', 'python3-requests']:
    ensure => 'installed',
  }

  # Create /etc/puppet for consistency with distro Puppet packages
  #
  file { '/etc/puppet':
    ensure => 'link',
    target => '/etc/puppetlabs/puppet',
    replace => false,
  }

  # Create directory for custom fact created by unipart-puppet-setup tool
  #
  file { '/var/lib/puppet':
    ensure => 'directory',
    replace => false,
  }
  file { '/var/lib/puppet/facts.d':
    ensure => 'link',
    target => '/opt/puppetlabs/facter/facts.d',
    replace => false,
  }

  # Install unipart-puppet-setup tool
  #
  file { '/usr/bin/unipart-puppet-setup':
    ensure => 'file',
    source => "puppet:///modules/${module_name}/unipart-puppet-setup",
    mode => '0755',
  }

  # Create a deploy key for use with the local Puppet repository
  #
  ssh_keygen { 'deploy':
    user => 'root',
    filename => $keyfile,
    comment => "deploy@${::fqdn}",
  }

  # Configure SSH access to the local Puppet repository
  #
  if ($repo) {

    sshkey { $repohost:
      type => 'ssh-rsa',
      key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDpBhT8N+as8YKC5L0H43hiCTywiwgdQksgk0B97YN21UtZTaTLdL2f0K3rO4OEBS0Yo7fiByw3lW46+/+nlWycs4RG636IjgLO+ZgZt22NMMlCH/UEJcWVTVMlLQe/M6Nk3OeDE6lMUYXj91ECLy/ngZ1zssnEqTDvnJi+841TWqsz/ugI49LTzu4IdFlqMJxXw5sU1YsYtQBFOng2E4/y6e1nFhKWv9v27AaaEwSrHOkwMdEChMqNjooYuvJjwx2utSuc+eLOA8avS0F9hhnJt9zlpBJl45KtQ8XpS2ZThQegIhJb6rk6aadZhgsJpHHd9Xoc3wzR2ZDPLwoDWs8b',
    }

    file { '/etc/ssh/ssh_config.d/50-r10k-deploy.conf':
      ensure => 'file',
      content => "Host ${repohost}\n  IdentityFile ${keyfile}\n",
    }

  }

  # Configure r10k for access to both this repository and the local
  # Puppet repository
  #
  class { 'r10k':
    sources => {
      'unipart' => {
        'remote' => 'https://github.com/unipartdigital/puppet-dev.git',
        'basedir' => $basedir,
      },
    } + ($repo ? {
      undef => {},
      default => {
        'project' => {
          'remote' => $repourl,
          'basedir' => "${settings::codedir}/environments",
        },
      },
    }),
  }

  # Install r10k-deploy service and timer
  #
  systemd::unit_file { 'r10k-deploy.service':
    source => "puppet:///modules/${module_name}/r10k-deploy.service",
    enable => true,
  }
  systemd::unit_file { 'r10k-deploy.timer':
    source => "puppet:///modules/${module_name}/r10k-deploy.timer",
    enable => true,
    active => true,
  }

  # Prevent r10k lockfile from being deleted when service is stopped
  #
  systemd::dropin_file { 'webhook-preserve-dir.conf':
    source => "puppet:///modules/${module_name}/webhook-preserve-dir.conf",
    unit => 'webhook.service',
  }

  # Configure Hiera environment layer
  #
  class { 'hiera':
    hiera_version => '5',
    hiera5_defaults => {
      data_hash => 'yaml_data',
      datadir => 'data',
    },
    hierarchy => [{
      name => 'Local environment secrets',
      paths => $hiera_eyaml_paths,
      lookup_key => 'eyaml_lookup_key',
      options => {
        pkcs7_private_key => "${keysdir}/private_key.pkcs7.pem",
        pkcs7_public_key => "${keysdir}/public_key.pkcs7.pem",
      },
    }, {
      name => 'Local environment',
      paths => $hiera_yaml_paths,
    }, {
      name => 'Defaults (matching development branch)',
      datadir => "${basedir}/%{environment}/data",
      paths => $hiera_yaml_paths,
    }, {
      name => 'Defaults',
      datadir => "${basedir}/production/data",
      paths => $hiera_yaml_paths,
    }],
    hiera_yaml => "${settings::confdir}/hiera.yaml",
    puppet_conf_manage => false,
    master_service => 'puppetserver',
    datadir_manage => false,
    eyaml => true,
    keysdir => $keysdir,
  }

  # Provide /usr/bin/eyaml and configure for editing secrets
  #
  file { '/usr/bin/eyaml':
    ensure  => 'link',
    target  => '/opt/puppetlabs/puppet/bin/eyaml',
  }
  file { '/etc/eyaml':
    ensure => 'directory',
  }
  file { '/etc/eyaml/config.yaml':
    ensure => 'file',
    content => to_yaml({
      pkcs7_private_key => "${keysdir}/private_key.pkcs7.pem",
      pkcs7_public_key => "${keysdir}/public_key.pkcs7.pem",
    }),
  }

  # Configure Puppet module path
  #
  ini_setting { 'puppet.conf basemodulepath':
    notify => Service['puppetserver'],
    path => "${settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'basemodulepath',
    value => join(["${basedir}/production/site",
                   "${basedir}/production/modules",
                   "${settings::codedir}/modules",
                   "/opt/puppetlabs/puppet/modules"], ':'),
  }

  # Configure Hiera global layer
  #
  ini_setting { 'puppet.conf hiera_config':
    notify => Service['puppetserver'],
    path => "${settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'hiera_config',
    value => "${basedir}/production/hiera-global.yaml",
  }

  # Use stock site.pp (which just delegates to Hiera)
  #
  ini_setting { 'puppet.conf default_manifest':
    notify => Service['puppetserver'],
    path => "${settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'default_manifest',
    value => "${basedir}/production/manifests",
  }

  # Enable autosigning
  #
  ini_setting { 'puppet.conf autosign':
    notify => Service['puppetserver'],
    path => "${settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'autosign',
    value => 'true',
  }

  # Start Puppet master
  #
  service { 'puppetserver':
    ensure => 'running',
    enable => true,
  }

  # Configure r10k webhook
  #
  class { 'r10k::webhook::config':
    use_mcollective => false,
    enable_ssl => true,
    protected => true,
    user => $hookuser,
    pass => $hookpass,
    configfile_mode => '0600',
    bind_address => '*',
    port => $hookport,
    public_key_path => "/etc/letsencrypt/live/${::fqdn}/fullchain.pem",
    private_key_path => "/etc/letsencrypt/live/${::fqdn}/privkey.pem",
    notify => Service['webhook'],
  }
  class { 'r10k::webhook':
    require => Class['r10k::webhook::config'],
    user => 'root',
    group => 'root',
  }
  file { '/etc/webhook.url':
    ensure => 'file',
    owner => 'root',
    group => 'root',
    mode => '0600',
    content => "https://${hookuser}:${hookpass}@${::fqdn}:${hookport}/payload",
  }

}
