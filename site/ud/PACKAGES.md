# Packages

You can specify packages to be installed via the `ud::packages`
[YAML](README.md#yaml) array.  For example, to ensure that `emacs` and
`vim` are installed on all hosts, edit your `data/common.yaml` to
include:

```yaml
ud::packages:
  - emacs
  - vim
```
