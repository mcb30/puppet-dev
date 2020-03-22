class ud::profile::puppet::master {

  $basedir = "${::settings::codedir}/unipart"

  class { 'r10k':
    sources => {
      'unipart' => {
        'remote' => 'https://github.com/unipartdigital/puppet-dev.git',
        'basedir' => $basedir,
      },
    },
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

  service { 'puppetserver':
    ensure => 'running',
    enable => true,
  }

}
