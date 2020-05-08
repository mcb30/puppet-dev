# @summary
#   Construct a secret value using any hash function
#
# @param hash [String]
#   Function name for the hash algorithm used, e.g. `sha256`
#
# @param nonces [String]
#   List of nonce values used to identify the secret
#
# @return [String]
#   Secret value
#
function autosecret::hash (
  String $hash = 'sha256',
  String *$nonces
) >> String
{

  # If a base secret is specified (eg in Hiera), use that
  #
  $lookup = 'autosecret::base'
  $lookup_base = lookup($lookup, {'default_value' => undef})

  # If no base secret is specified, generate a random secret in the
  # Puppet private information directory.  These commands are run
  # directly on the Puppet master at the time of function invocation
  # rather than using declared resources, since the base secret value
  # needs to be known before this function can return.
  #
  if $lookup_base {
    debug("autosecret using ${lookup}")
    $base = $lookup_base
  } else {
    $basefile = "${settings::privatedir}/autosecret"
    if ! find_file($basefile) {
      warning("autosecret generating ${basefile}")
      generate('/usr/bin/touch', $basefile)
      generate('/usr/bin/chmod', '0600', $basefile)
      generate('/usr/bin/dd', 'if=/dev/random', 'bs=16', 'count=1',
               "of=${basefile}")
    }
    debug("autosecret using ${basefile}")
    $base = call($hash, binary_file($basefile))
  }

  # Construct derived secret from base secret and nonces
  #
  $inputs = ['prefix'] + $nonces + ['suffix']
  $inputs.reduce($base) |$memo, $value| {
    call($hash, "${memo}:${value}")
  }
}
