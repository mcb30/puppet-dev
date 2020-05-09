# @summary
#   Look up a (possibly empty) hash in Hiera
#
# @param key
#   Lookup key
#
# @param default
#   Default value if not found
#
# @return [Optional[Hash]]
#   Hash value
#
function ud::hashlookup (
  String $key,
  Optional[Hash] $default = undef,
) >> Optional[Hash]
{

  # Perform raw lookup.  This will return undef if the key is present
  # but has no children
  $raw = lookup($key, Optional[Hash], 'deep', {__absent__ => true})

  # Compute desired result
  ($raw and $raw[__absent__]) ? {

    # Raw lookup found nothing
    true => $default,

    default => ($raw ? {

      # Raw lookup found an empty value
      undef => {},

      # Raw lookup found an actual hash
      default => $raw,

    }),
  }
}
