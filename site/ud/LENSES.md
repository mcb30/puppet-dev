# Augeas lenses

You can tell Puppet how to use Augeas to understand your application's
configuration files via the `ud::lenses` [YAML](README.md#yaml)
dictionary.  For example, if you application has a configuration file
`/etc/myapp.ini` using the standard `.ini` file format:

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
