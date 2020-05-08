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

### ud::packages

You can specify packages to be installed in the `ud::packages` YAML
array.  For example, to ensure that `emacs` and `vim` are installed on
all hosts, edit `data/common.yaml` to include:

```yaml
ud::packages:
  - emacs
  - vim
```

### ud::users

You can specify user accounts and SSH authorized keys in the
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
