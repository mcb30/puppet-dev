# Users

You can specify user accounts and SSH authorized keys via the
`ud::users` [YAML](README.md#yaml) dictionary.  For example, to
specify that all hosts should have a user account `cloud-user` with
two SSH authorized keys, edit your `data/common.yaml` to include:

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

The list of SSH authorized keys is definitive for the user: any other
keys present in the user's `authorized_keys` file will be removed.

## Sudo access

All user accounts will have `sudo` access by default.  You can disable
this by setting the `sudo` parameter to `false`.  For example:

```yaml
ud::users:
  alice:
    sudo: false
```

## Extra groups

You can specify a list of supplementary groups via the `groups`
parameter.  For example:

```yaml
ud::users:
  alice:
    groups:
      - dbusers
      - sftpusers
```
