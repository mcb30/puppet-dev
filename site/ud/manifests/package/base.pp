# @summary
#   Base functionality for `ud::package`
#
# This is included automatically by [`ud::package`](#udpackage).  You should
# not need to use this class directly.
#
class ud::package::base {

  # COPR repository locations
  #
  $copr = 'https://download.copr.fedorainfracloud.org/results'
  $coprpkgs = "${copr}/unipartdigital/pkgs"

  # Enable COPR repository
  #
  if ($::os['family'] == 'RedHat') {
    yumrepo { 'unipartdigital':
      descr => 'Unipart Digital RPM packages',
      baseurl => ($::os['name'] ? {
        'Fedora' => "${coprpkgs}/fedora-\$releasever-\$basearch/",
        'CentOS' => "${coprpkgs}/epel-\$releasever-\$basearch/",
      }),
      gpgkey => "${coprpkgs}/pubkey.gpg",
    }
  }

}
