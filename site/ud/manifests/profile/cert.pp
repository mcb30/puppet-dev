class ud::profile::cert {
  include ::letsencrypt
  letsencrypt::certonly { $trusted['certname']: }
}
