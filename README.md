# finemas.macos

Ansible collection that sets up an Apple Silicon Mac: Homebrew packages, macOS defaults, dotfiles and a launchd-driven `ansible-pull`.

Target: Apple Silicon (arm64), macOS 15 or newer, Homebrew in `/opt/homebrew`. Requires ansible-core 2.17 or newer.

## Install

Install from a git tag (not published on Galaxy yet):

```yaml
# requirements.yml
collections:
  - name: https://github.com/Finemas/ansible-collection-macos.git
    type: git
    version: v0.1.0
```

```sh
ansible-galaxy collection install -r requirements.yml
```

## Roles

| Role | Purpose | Status |
|------|---------|--------|
| `homebrew` | Install Homebrew, taps, formulae, casks and Mac App Store apps | planned |
| `defaults` | Apply macOS `defaults` settings | planned |
| `dotfiles` | Link dotfiles into the home directory | planned |
| `pull` | Run `ansible-pull` periodically via launchd | planned |

## Testing

```sh
tests/run.sh <role> [scenario] [--inventory localhost|vm]
```

Runs `tests/integration/<role>/<scenario>/converge.yml` twice (the second run must report `changed=0`), then `verify.yml`. `tests/vm.sh up|down` manages a disposable [Tart](https://tart.run) macOS VM for the `vm` inventory.

## Credits

Inspired by [geerlingguy/ansible-collection-mac](https://github.com/geerlingguy/ansible-collection-mac) (MIT).

## License

MIT, see [LICENSE](LICENSE).
