# Web server

You can configure a web server via the `ud::web`
[YAML](README.md#yaml) dictionary.

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

## Document root

To serve static files from an alternative directory, you can use the
`docroot` parameter.  For example, to serve static files from
`/var/www/myapp/static`:

```yaml
ud::web:
  docroot: /var/www/myapp/static
```

## Application paths

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

## Application ports

For web applications that run as a service listening for HTTP requests
on a local port, you can use the `app_port` parameter to specify the
application port number.  For example, if [Odoo](https://odoo.com) is
running and listening on its default port 8069:

```yaml
ud::web:
  app_port: 8069
```

## Alias names

If the web server has been provided with additional
`preview.devonly.net` DNS names for legacy IPv4-only access, you can
specify these via the `aliases` parameter.  For example:

```yaml
ud::web:
  aliases:
    - thing-demo.preview.devonly.net
```
