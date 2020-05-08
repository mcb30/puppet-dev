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
