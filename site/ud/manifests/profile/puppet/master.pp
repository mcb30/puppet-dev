class ud::profile::puppet::master {

  $basedir = "${::settings::codedir}/unipart"

  $project = split($trusted['domain'], '\.')[0]
  $repohost = 'git.unipart.io'
  $repourl = "git@${repohost}:unipart/$project-puppet.git"
  $keyfile = "${::settings::confdir}/id_deploy"

  ssh_keygen { 'deploy':
    user => 'root',
    filename => $keyfile,
    comment => "$project-puppet deploy key",
  }

  file { '/etc/ssh/ssh_config.d/50-r10k-deploy.conf':
    ensure => 'file',
    content => "Host ${repohost}\n  IdentityFile ${keyfile}\n",
  }

  class { 'r10k':
    sources => {
      'unipart' => {
        'remote' => 'https://github.com/unipartdigital/puppet-dev.git',
        'basedir' => $basedir,
      },
    },
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
