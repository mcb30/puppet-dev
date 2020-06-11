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
database will allow [remote logins](#remote-access) only over an
encrypted connection.

## Connection parameters

For each of the three database users, you can choose to have various
database connection parameters written to your application's
configuration files.  The available connection parameters are:

* `database` - the database name
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

## Remote access

You can use the [connection parameters](#connection-parameters) to
connect to your database from other virtual machines within your
project or from the outside world.

You can use network Security Groups to control which machines are
allowed to attempt a connection to your database.  The database will
require all connections to be authenticated and encrypted using TLS.
The database URL [connection parameter](#connection-parameters)
already includes all of the information required to establish a
suitably encrypted connection.

For example, you can use the database URL to connect remotely using
`psql` for debugging:

```console
$ psql postgresql://myapp_writer:<password>@<hostname>:5432/myapp?sslmode=verify-full
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
myapp=>
```

## Deployment

You can deploy a database configuration across multiple machines using
the `ud::databases` [YAML](README.md#yaml) dictionary.  For each
database, you can use the `server` parameter to specify the machine
that should be the database server.

For example, suppose that your project will include:

* A database server called `dbserver` hosting a single database
  `myapp`
* Two application servers called `appserver-1` and `appserver-2` that
  will each read the file `/etc/myapp.ini` to get the database
  connection URL.

You can achieve this by editing your `data/common.yml` to include:

```yaml
ud::databases:
  myapp:
    server: dbserver
```

and your `data/nodes/appserver.yml` to include:

```yaml
ud::databases:
  myapp:
    writer:
      /etc/myapp.ini/database/connection: url
```

Your virtual machine called `dbserver` will then configure itself as a
database server and will create the database `myapp` along with its
three users (owner, writer and reader).  You can SSH to `dbserver` as
a user with [`sudo` access](USERS.md#sudo-access) and use `psql myapp
-U myapp` to inspect and modify the database for debugging.

Your two virtual machines called `appserver-1` and `appserver-2` will
both configure themselves as database clients.  The file
`/etc/myapp.ini` on both machines will be updated to include:

```ini
[database]
...
connection = postgresql://myapp_writer:<password>@dbserver.<domainname>:5432/myapp?sslmode=verify-full
...
```

Your application servers will read this database connection URL and
can then automatically connect to your database server using the
appropriate user name, password, and encryption mechanism.

## Database types

You can use the `type` parameter to choose a database other than
PostgreSQL.  For example, to deploy a MariaDB database:

```yaml
ud::databases:
  myapp:
    type: mariadb
```

The supported database types are `postgresql`, `mysql`, and `mariadb`
(which is a synonym for `mysql`).

### Limitations of the `mysql` type

The MySQL/MariaDB client does not verify the server's TLS certificate,
and therefore does not provide any guarantee of a secure connection.

The MySQL/MariaDB server cannot associate a single [local
user](#local-access) with more than one database user, and so will
treat any local user with [`sudo` access](USERS.md#sudo-access) as
being a database superuser.
