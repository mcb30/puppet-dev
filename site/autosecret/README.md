# autosecret

## Module description

Puppet manifests often need to deploy secret values such as
passwords.  The same secret password will often need to be provided
via several manifests: for example, a manifest that creates a
database user needs to use the same secret password as the manifest
that creates the configuration file for the web application that
will eventually connect to the database.

This problem has traditionally been solved by creating a dedicated
Hiera [eyaml](https://github.com/voxpupuli/hiera-eyaml) entry for each
unique secret.  This does not scale well, since it adds an additional
manual step to a new deployment whenever secrets are required.

The `autosecret::hash` function provides an alternative mechanism that
allows an arbitrary number of secrets to be constructed from a single
base secret.  For example:

```puppet
# In the database server manifest:
mysql::db { 'wordpress':
    user        => 'wordpress',
    password    => autosecret::sha256('wordpress', 'database'),
}

# In the web application server manifest:
class { 'wordpress':
    db_user     => 'wordpress',
    db_password => autosecret::sha256('wordpress', 'database'),
}
```

The secret value is constructed by computing a hash over a single
base secret (specified in the `autosecret::base` class parameter)
and the list of nonce parameters.

Where multiple manifests need access to the same secret value (as in
the above example), use the same list of nonce parameters to generate
an identical password.

To generate different secret values (for services that should not be
using the same password), use differing lists of nonce parameters to
generate different passwords.  For example:

```puppet
$wp_password = autosecret::sha256('wordpress', 'database')

$mw_password = autosecret::sha256('mediawiki', 'database')

$edi_password = autosecret::sha256('sftp', 'incoming', $customer_name)
```

## Base secret

You can optionally choose an explicit base secret by specifying an
abitrary value for the `autosecret::base` class parameter.  For
example:

```yaml
---
autosecret::base: ENC[PKCS7,aGVsbG8gd29ybGQ=]
```

Changing the base secret will change all generated passwords.  You
can share a single base secret to effectively share an entire set of
passwords between multiple deployments.

If you do not specify an explicit base secret, then a random base
secret will be generated and stored in the file
`${settings::privatedir}/autosecret` when the function is first
called.

## Functions

The module provides three functions:

* [`autosecret::sha256`](REFERENCE.md#autosecretsha256): Construct a
  secret value using SHA-256

* [`autosecret::sha1`](REFERENCE.md#autosecretsha251): Construct a
  secret value using SHA-1

* [`autosecret::hash`](REFERENCE.md#autosecrethash): Construct a
  secret value using any hash function

You should use `autosecret::sha256` unless you have a particular need
to use an alternative hash function.
