# Databases

You can specify databases to be created via the `ud::databases`
[YAML](README.md#yaml) dictionary.  For example, to create a
PostgreSQL database called `myapp` and to have the database connection
URL injected into your application's configuration file
`/etc/myapp.ini`:

```yaml
ud::databases:
  myapp:
    writer:
      /etc/myapp.ini/database/connection: url
```

Your database will always have three users created:

* A database `owner`, with the ability to modify the database schema
* A database `writer`, with the ability to modify any data
* A database `reader`, with the ability to read any existing data

A LetsEncrypt certificate will be issued and used automatically.  The
database will allow remote logins only over an encrypted connection.

## Connection parameters

For each of the three database users, you can choose to have various
database connection parameters written to your application's
configuration files.  The available connection parameters are:

* `username` - the database username
* `password` - the database password
* `host` - the database DNS hostname
* `port` - the database port number
* `url` - a database URL including all of the above information,
  suitable for use with `psql` or with SQLAlchemy's `create_engine`.

For example, if your Python application has the configuration file
`/etc/myapp.ini` and needs credentials for both administrative and
normal access, you might use:

```yaml
ud::databases:
  myapp:
    writer:
      /etc/myapp.ini/database/connection: url
    owner:
      /etc/myapp.ini/database/admin: url
```

Your application's configuration file `/etc/myapp.ini` (as installed
by your application package) would then be edited to include:

```ini
[database]
...
connection = postgresql://myapp_writer:<password>@<hostname>:5432/myapp?sslmode=verify-full
admin = postgresql://myapp:<password>@<hostname>:5432/myapp?sslmode=verify-full
...
```

This mechanism uses [Augeas](https://augeas.net) to modify
configuration files.  You will probably need to use the
[`ud::lenses`](LENSES.md) YAML dictionary to tell Augeas how to
understand your application's configuration files.

Note that the database connection parameters include passwords that
should not be world-readable.  It is the responsiblity of your
application package to ensure that its configuration files are created
with appropriate permissions.

## Local access

If you are logged in on the database server itself as a user with
[`sudo` access](USERS.md#sudo-access) then you can use `psql` to
connect to your database without supplying a password.  For example:

```shell
psql myapp -U myapp
```

You can use the `-U` option to connect as any of the three database
users (owner, writer, or reader).  For example:

```shell
psql myapp -U myapp_reader
```
