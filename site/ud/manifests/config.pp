# @summary
#   Apply values to configuration files using Augeas
#
# Take a hash mapping Augeas-style paths to configuration values
# (e.g. `'/etc/ssh/sshd_config/PasswordAuthentication' => 'no'`), and
# use Augeas to apply each value to each path in a single operation.
#
# The [`ud::lenses`](LENSES.md) YAML dictionary may be used to define
# Augeas lenses to be applied for non-standard filename patterns.  For
# example:
#
# ```yaml
# ud::lenses:
#   ini:
#     - /etc/myyapp.ini
#   json:
#     - /etc/myapp/*.json
# ```
#
# @example Disable SSH password authentication
#   ud::config { "sshpw":
#     '/etc/ssh/sshd_config/PasswordAuthentication' => 'no',
#     '/etc/ssh/sshd_config/ChallengeResponseAuthentication' => 'no',
#   }
#
# @param values
#   Hash mapping Augeas-style paths to configuration values
#
define ud::config (
  Hash $values,
)
{

  # Construct lens definitions
  #
  $lenses = ud::hashlookup('ud::lenses', {})
  $set_load_lens = $lenses.map |String $lens, Array[String] $globs| {
    $lensfile = $lens ? {
      'ini' => 'Puppet.lns',
      'json' => 'Json.lns',
      'php' => 'Phpvars.lns',
      'shell' => 'Simplevars.lns',
      'xml' => 'Xml.lns',
      'yaml' => 'Yaml.lns',
      'yml' => 'Yaml.lns',
      default => capitalize($lens + '.lns'),
    }
    "set /augeas/load/UdConfig_${lens}/lens ${lensfile}"
  }
  $set_load_incl = flatten($lenses.map |String $lens, Array[String] $globs| {
    $globs.map |String $glob| {
      "set /augeas/load/UdConfig_${lens}/incl[last() + 1] ${glob}"
    }
  })

  # Construct values
  #
  $set_values = $values.map |String $path, Any $value| {
    "set /files/${path} ${value}"
  }

  # Skip empty Augeas runs
  #
  if ($set_values != '') {

    # Deploy changes
    #
    augeas { $name:
      changes => $set_load_lens + $set_load_incl + $set_values,
    }

    # Defer changes until after all resources that might plausibly
    # create the files that we want to modify
    #
    Package <| |> -> Augeas[$name]
    File <| |> -> Augeas[$name]

  }

}
