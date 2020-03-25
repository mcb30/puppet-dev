class ud::profile::puppet::master (
  Optional[String] $repo = $facts['puppet_repo'],
)
{

  $basedir = "${::settings::codedir}/unipart"

  $repohost = 'git.unipart.io'
  $repourl = "git@${repohost}:${repo}.git"
  $keyfile = "${::settings::confdir}/id_deploy"

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

  if ($repo) {

    sshkey { $repohost:
      type => 'ssh-rsa',
      key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDpBhT8N+as8YKC5L0H43hiCTywiwgdQksgk0B97YN21UtZTaTLdL2f0K3rO4OEBS0Yo7fiByw3lW46+/+nlWycs4RG636IjgLO+ZgZt22NMMlCH/UEJcWVTVMlLQe/M6Nk3OeDE6lMUYXj91ECLy/ngZ1zssnEqTDvnJi+841TWqsz/ugI49LTzu4IdFlqMJxXw5sU1YsYtQBFOng2E4/y6e1nFhKWv9v27AaaEwSrHOkwMdEChMqNjooYuvJjwx2utSuc+eLOA8avS0F9hhnJt9zlpBJl45KtQ8XpS2ZThQegIhJb6rk6aadZhgsJpHHd9Xoc3wzR2ZDPLwoDWs8b',
    }

    ssh_keygen { 'deploy':
      user => 'root',
      filename => $keyfile,
      comment => "deploy@${::fqdn}",
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
          'basedir' => "${::settings::codedir}/environments",
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

  ini_setting { 'puppet.conf hiera_config':
    notify => Service['puppetserver'],
    path => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'hiera_config',
    value => "${basedir}/production/hiera.yaml",
  }

  file { "${::settings::confdir}/hiera.yaml":
    ensure => 'link',
    target => "${basedir}/production/hiera.yaml",
  }

  ini_setting { 'puppet.conf basemodulepath':
    notify => Service['puppetserver'],
    path => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'basemodulepath',
    value => join(["${basedir}/production/site",
                   "${basedir}/production/modules",
                   "${::settings::codedir}/modules",
                   "/opt/puppetlabs/puppet/modules"], ':'),
  }

  ini_setting { 'puppet.conf default_manifest':
    notify => Service['puppetserver'],
    path => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'default_manifest',
    value => "${basedir}/production/manifests",
  }

  ini_setting { 'puppet.conf autosign':
    notify => Service['puppetserver'],
    path => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'autosign',
    value => 'true',
  }

  service { 'puppetserver':
    ensure => 'running',
    enable => true,
  }

}
