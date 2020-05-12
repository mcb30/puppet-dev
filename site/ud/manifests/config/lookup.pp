# @summary
#   Apply values to configuration files using Augeas and a lookup hash
#
# Take a hash mapping Augeas style paths to lookup keys
# (e.g. `'/etc/myapp.ini/db/password' => 'password'`) and a second
# hash mapping lookup keys to values (e.g. `'password' =>
# 'supersecret'`), and use Augeas to apply the looked-up value to each
# path in a single operation.
#
# This allows a manifest to construct a hash of configuration values
# (such as database connection parameters) and apply these
# configuration values to arbitrary custom file formats.
#
# As with [`ud::config`](#udconfig), the [`ud::lenses`](LENSES.md)
# YAML dictionary may be used to define Augeas lenses to be applied
# for non-standard filename patterns.
#
# @example Database passwords
#   ud::config::lookup { "database passwords":
#     paths => {
#       '/etc/myapp.ini/db/user' => 'username',
#       '/etc/myapp.ini/db/password' => 'password',
#     },
#     values => {
#       'username' => 'dbuser',
#       'password' => 'supersecret',
#     },
#   }
#
# @param paths
#   Hash mapping Augeas-style paths to lookup keys
#
# @param values
#   Hash mapping lookup keys to configuration values
#
define ud::config::lookup (
  Hash $paths = {},
  Hash $values = {},
)
{

  # Apply values via lookup hash
  #
  ud::config { $name:
    values => hash(flatten($paths.map |String $path, String $key| {
      [$path, $values[$key]]
    })),
  }

}
