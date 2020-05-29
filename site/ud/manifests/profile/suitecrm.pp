# @summary
#   Configure a default standalone SuiteCRM instance
#
class ud::profile::suitecrm (
)
{

  # Configure the default SuiteCRM instance
  #
  ud::suitecrm { 'default':
  }

}
