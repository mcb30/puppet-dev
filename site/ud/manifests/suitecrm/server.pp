# @summary
#   Configure a SuiteCRM server
#
# This is intended to be invoked automatically by
# [`ud::suitecrm`](#udsuitecrm).  You should not need to use this
# class directly.
#
class ud::suitecrm::server (
)
{

  # Configure PHP
  #
  include ud::php::server

  # Install SuiteCRM
  #
  package { 'suitecrm':
    ensure => 'present',
    notify => Service['httpd'],
  }

}
