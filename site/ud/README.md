# ud

## Module description

This module provides a variety of highly opinionated classes for rapid
deployment of test and development virtual machines.  The deployments
created with this module are not suitable for production usage, but if
you conform to the mechanisms that this module recommends then your
application will find it relatively easy to migrate to a production
setup.

## YAML data

Most common configuration tasks can be carried out solely by creating
YAML files within the `data` directory.

* `data/nodes/<hostname.domainname>.yaml`
* `data/nodes/<hostname>.yaml`
* `data/nodes/<hostname-prefix>.yaml`

These files contain per-host configuration.  You can name the file
using either the fully-qualified DNS name
(e.g. `data/nodes/odoo-test-1.mcb30.devonly.net.yaml`), or the
hostname only (e.g. `data/nodes/odoo-test-1.yaml`) or the hostname
prefix (e.g. `data/nodes/odoo-test.yaml`).

* `data/os/<os.name>.yaml`
* `data/os/<os.family>.yaml`

These files contain per-OS configuration.  You can name the file using
either the operating system name (e.g. `data/os/Fedora.yaml`) or the
operating system family (e.g. `data/os/RedHat.yaml`).

* `data/common.yaml`

This file contains configuration that is applied to all nodes
(including the Puppet master itself).

## Common tasks

* [Installing packages](#udpackages)
* [Creating user accounts](#udusers)
* [Setting configuration file values](#udconfigs)
* [Configuring a web server](#udweb)
* [Running a container](#udcontainers)

### ud::packages

You can specify packages to be installed via the `ud::packages` YAML
array.  For example, to ensure that `emacs` and `vim` are installed on
all hosts, edit `data/common.yaml` to include:

```yaml
ud::packages:
  - emacs
  - vim
```

### ud::users

You can specify user accounts and SSH authorized keys via the
`ud::users` YAML dictionary.  For example, to specify that all hosts
should have a user account `cloud-user` with two SSH authorized keys,
edit `data/common.yaml` to include:

```yaml
ud::users:
  cloud-user:
    keys:
      - ssh-rsa AAAAB3NzaC1.....obMlq0= alice@example.com
      - ssh-rsa AAAAB3NyeKF.....92Gnw2= bob@example.com
```

If you want to specify the same configuration for multiple user
accounts, you can use YAML anchors to avoid repetition.  For example,
to specify that the `root` user should have the same set of SSH
authorized keys as `cloud-user`:

```yaml
ud::users:
  cloud-user: &cloud-user
    keys:
      - ssh-rsa AAAAB3NzaC1.....obMlq0= alice@example.com
      - ssh-rsa AAAAB3NyeKF.....92Gnw2= bob@example.com
  root: *cloud-user
```

All user accounts will have `sudo` access by default.  You can disable
this by setting the `sudo` parameter to `false`.  For example:

```yaml
ud::users:
  alice:
    sudo: false
```

You can specify a list of supplementary groups via the `groups`
parameter.  For example:

```yaml
ud::users:
  alice:
    groups:
      - dbusers
      - sftpusers
```

### ud::configs

You can inject static arbitrary values into configuration files via
the `ud::configs` YAML dictionary.  For example, to configure `sshd`
to accept password authentication:

```yaml
ud::configs:
  /etc/ssh/sshd_config/PasswordAuthentication: "yes"
  /etc/ssh/sshd_config/ChallengeResponseAuthentication: "yes"
```

You can use this mechanism to set values in your application's
configuration files.  For example, if your application has a
configuration file `/etc/myapp.ini` and you want to set the value
`debug=yes` within the `[options]` section:

```yaml
ud::configs:
  /etc/myapp.ini/options/debug: yes
ud::lenses:
  ini:
    - /etc/myapp.ini
```

This mechanism uses [Augeas](https://augeas.net) to modify
configuration files.  You will probably need to use the
[`ud::lenses`](#udlenses) YAML dictionary to tell Augeas how to
understand your application's configuration files.

### ud::lenses

You can tell Puppet how to use Augeas to understand your application's
configuration files via the `ud::lenses` YAML dictionary.  For
example, if you application has a configuration file `/etc/myapp.ini`
using the standard `.ini` file format:

```yaml
ud::lenses:
  ini:
    - /etc/myapp.ini
```

The recognised formats are `ini`, `json`, `php`, `shell`, `xml`, and
`yaml`.

You can use standard shell glob patterns to match file paths.  For
example:

```yaml
ud::lenses:
  json:
    - /etc/*.json
  yaml:
    - /etc/myapp/*.yml
    - /etc/otherapp/*.yml
  php:
    - /usr/share/Adobe/doc/example/android_vm/root/sbin/*.jar
```

### ud::web

You can configure a web server via the `ud::web` YAML dictionary.

A LetsEncrypt certificate will be issued and used automatically.  All
HTTP requests will be redirected to HTTPS.  Your site should receive
an A+ rating from [SSL Labs](https://www.ssllabs.com).

As an example, to specify that the host named `webtest` should run the
default Apache web server to serve static files from the standard
`/var/www/html` directory via HTTPS, create the file
`data/nodes/webtest.yaml` containing:

```yaml
ud::web:
```

To serve static files from an alternative directory, you can use the
`docroot` parameter.  For example, to serve static files from
`/var/www/myapp/static`:

```yaml
ud::web:
  docroot: /var/www/myapp/static
```

For web applications that provide an Apache
[Alias](https://httpd.apache.org/docs/current/mod/mod_alias.html)
directive via a drop-in configuration file, you can use the `app_path`
parameter to specify the default application path.  For example, to
install and run [WordPress](https://wordpress.com):

```yaml
ud::packages:
  - wordpress
ud::web:
  app_path: /wordpress
```

For web applications that run as a service listening for HTTP requests
on a local port, you can use the `app_port` parameter to specify the
application port number.  For example, if [Odoo](https://odoo.com) is
running and listening on its default port 8069:

```yaml
ud::web:
  app_port: 8069
```

If the web server has been provided with additional
`preview.devonly.net` DNS names for legacy IPv4-only access, you can
specify these via the `aliases` parameter.  For example:

```yaml
ud::web:
  aliases:
    - thing-demo.preview.devonly.net
```

### ud::containers

You can specify container images to run via the `ud::containers` YAML
dictionary.  Each container will be run as a `systemd` service using
the `podman` container manager.

As an example, to specify that the host named `flowdemo` should run
the published [Node-RED container
image](https://nodered.org/docs/getting-started/docker) using Apache
as the front-end web server, create the file
`data/nodes/flowdemo.yaml` containing:

```yaml
ud::web:
  app_port: 1880

ud::containers:
  nodered:
    image: docker.io/nodered/node-red
    ports:
      - 1880
```

Running non-trivial services from prebuilt container images is
invariably an exercise in pain, futility, and the tracking down of
information from an impressive variety of mutually contradictory
sources.  This misery is as nothing compared to the experience of
debugging a malfunctioning application distributed only as a prebuilt
container image.

As practice for this unpleasant experience, any further instructions
on using `ud::containers` must be reverse engineered from the rather
sparse documentation for the
[`ud::container`](REFERENCE.md#udcontainer) defined type.
