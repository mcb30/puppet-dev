# Static configuration

You can inject static arbitrary values into configuration files via
the `ud::configs` [YAML](README.md#yaml) dictionary.  For example, to
configure `sshd` to accept password authentication:

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

Your application's configuration file `/etc/myapp.ini` (as installed
by your application package) would then be edited to include:

```ini
[options]
...
debug = yes
...
```

This mechanism uses [Augeas](https://augeas.net) to modify
configuration files.  You will probably need to use the
[`ud::lenses`](LENSES.md) YAML dictionary to tell Augeas how to
understand your application's configuration files.
