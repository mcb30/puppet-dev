# @summary
#   Configure a standalone SuiteCRM instance
#
# @param name
#   Instance name
#
define ud::suitecrm (
)
{

  # Construct database name and service suffix
  #
  if ( $name == 'default' ) {
    $database = 'suitecrm'
    $suffix = ''
  } else {
    $database = "suitecrm_${name}"
    $suffix = "@${name}"
  }

  # Construct template variables
  #
  $dbname = $database
  $dbuser = $database
  $dbpass = ud::database::password ( $dbname, $dbuser )
  $siteurl = "https://${::fqdn}/suitecrm"

  # Configure SuiteCRM server
  #
  include ud::suitecrm::server

  # Create database
  #
  ud::database { $database:
    type => 'mariadb',
  }

  # Create conf.d fragment
  #
  # We have to create the containing directories manually since Puppet
  # is not capable of expressing "first start the service (to ensure
  # the directories exist), then create the file fragment, then
  # restart the service"
  #
  file { "/etc/suitecrm/${name}":
    ensure => 'directory',
    require => Package['suitecrm'],
  } -> file { "/etc/suitecrm/${name}/conf.d":
    ensure => 'directory',
  } -> file { "/etc/suitecrm/${name}/conf.d/50-puppet.php":
    ensure => 'file',
    content => template('ud/suitecrm-puppet.php'),
    mode => '0640',
    notify => Service["suitecrm${suffix}"],
  }

  # Enable service and timer
  #
  service { ["suitecrm${suffix}", "suitecrm-scheduler${suffix}.timer"]:
    ensure => 'running',
    enable => true,
    require => Package['suitecrm'],
  }

}
