class ud::profile::puppet::master (
  Optional[String] $repo = $facts['puppet_repo'],
)
{

  include ud::cert

  $basedir = "${settings::codedir}/unipart"

  $repohost = 'git.unipart.io'
  $repourl = "git@${repohost}:${repo}.git"
  $keyfile = "${settings::confdir}/id_deploy"

  $keysdir = "${settings::confdir}/keys"

  $hookport = '8088'
  $hookuser = 'puppet'
  $hookpass = autosecret::sha256('r10k', 'webhook')

  package { ['python3', 'python3-requests']:
    ensure => 'installed',
  }

  file { '/etc/puppet':
    ensure => 'link',
    target => '/etc/puppetlabs/puppet',
    replace => false,
  }

  file { '/var/lib/puppet':
    ensure => 'directory',
    replace => false,
  }

  file { '/var/lib/puppet/facts.d':
    ensure => 'link',
    target => '/opt/puppetlabs/facter/facts.d',
    replace => false,
  }

  file { '/usr/bin/unipart-puppet-setup':
    ensure => 'file',
    source => "puppet:///modules/${module_name}/unipart-puppet-setup",
    mode => '0755',
  }

  ssh_keygen { 'deploy':
    user => 'root',
    filename => $keyfile,
    comment => "deploy@${::fqdn}",
  }

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

  systemd::unit_file { 'r10k-deploy.service':
    source => "puppet:///modules/${module_name}/r10k-deploy.service",
    enable => true,
  }

  systemd::unit_file { 'r10k-deploy.timer':
    source => "puppet:///modules/${module_name}/r10k-deploy.timer",
    enable => true,
    active => true,
  }

  systemd::dropin_file { 'webhook-preserve-dir.conf':
    source => "puppet:///modules/${module_name}/webhook-preserve-dir.conf",
    unit => 'webhook.service',
  }

  class { 'hiera':
    hiera_version => '5',
    hiera5_defaults => {
      data_hash => 'yaml_data',
      datadir => 'data',
    },
    hierarchy => [{
      name => 'Encrypted secrets',
      paths => [
        'nodes/%{trusted.certname}.eyaml',
        'nodes/%{trusted.hostname}.eyaml',
        'common.eyaml',
      ],
      lookup_key => 'eyaml_lookup_key',
      options => {
        pkcs7_private_key => "${keysdir}/private_key.pkcs7.pem",
        pkcs7_public_key => "${keysdir}/public_key.pkcs7.pem",
      },
    }, {
      name => 'Default hierarchy',
      paths => [
        'nodes/%{trusted.certname}.yaml',
        'nodes/%{trusted.hostname}.yaml',
        'nodes/%{facts.hostprefix}.yaml',
        'os/%{facts.os.name}%{facts.os.major}.yaml',
        'os/%{facts.os.name}.yaml',
        'os/%{facts.os.family}.yaml',
        'common.yaml',
      ],
    }],
    hiera_yaml => "${settings::confdir}/hiera.yaml",
    master_service => 'puppetserver',
    datadir_manage => false,
    eyaml => true,
    keysdir => $keysdir,
  }

  file { "${settings::confdir}/data":
    ensure => 'link',
    target => "${basedir}/production/data",
  }

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

  ini_setting { 'puppet.conf default_manifest':
    notify => Service['puppetserver'],
    path => "${settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'default_manifest',
    value => "${basedir}/production/manifests",
  }

  ini_setting { 'puppet.conf autosign':
    notify => Service['puppetserver'],
    path => "${settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'autosign',
    value => 'true',
  }

  service { 'puppetserver':
    ensure => 'running',
    enable => true,
  }

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
