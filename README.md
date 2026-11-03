<!--
    Copyright 2022-2026 TII (SSRC) and the Ghaf contributors
    SPDX-License-Identifier: CC-BY-SA-4.0
-->

# ci-test-automation

Robot framework suites, libraries and requirements for running tests to ghaf-project nixOS with real HW.

## Nix Flake usage

### Basic test running

To enter a shell which has the `ghaf-robot` wrapper for running the Robot
Framework, run `nix shell`.

Alternatively, you can build the package with `nix build` and the wrapper will
appear at `result/bin/ghaf-robot`.

### Devshell

To enter a devshell, where you can run `robot` (instead of the wrapper) and all
the Python dependencies are available, run `nix develop`.

The shell includes Robotidy for formatting Robot Framework files. Preview changes with:

```sh
robotidy --diff Robot-Framework
```

To apply the formatting, enable overwrite explicitly:

```sh
robotidy --overwrite Robot-Framework
```

## drcontrol.py

For more information, see [drcontrol-README.md](./drcontrol/drcontrol-README.md).

## kmtronic_4ch_control.py and kmtronic_4ch_status.py

For more information, see [README.md](./KMTronic/README.md).

## Git commit hook

When contributing to this repo you should take the git commit hook into use.

The hooks check the commit message for common mistakes against [current Ghaf commit message guidelines](https://github.com/tiiuae/ghaf/blob/main/CONTRIBUTING.md#commit-message-guidelines) and refuse commits when staged Robot Framework files need Robotidy formatting.

### Installing git hooks

Entering ``nix develop`` installs commit message and the Robotidy pre-commit hooks automatically. You can also install the commit message hook separately with ``./githooks/install-git-hooks.sh``.

If you have branches before the git hooks were committed to the repo, you'll have to either rebase them on top of main branch or cherry pick the git hooks commit into your branch.

Also note that any existing commit messages in any branch won't be checked, only new commit messages will be checked.

If you encounter any issues with the hooks, please report them. You can remove either hook by deleting its symlink from ``.git/hooks``.

## Licensing

This repository uses following licenses:

| License Full Name | SPDX Short Identifier | Description
| --- | --- | ---
| Apache License 2.0 | [Apache-2.0](https://spdx.org/licenses/Apache-2.0.html) | Source code
| GNU General Public License | [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) | Source code: drcontrol
| Creative Commons Attribution Share Alike 4.0 International | [CC-BY-SA-4.0](https://spdx.org/licenses/CC-BY-SA-4.0.html) | Documentation

See [LICENSE.Apache-2.0](./LICENSES/LICENSE.Apache-2.0), [LICENSE.GPLv3](./LICENSES/LICENSE.GPLv3), and [LICENSE.CC-BY-SA-4.0](./LICENSES/LICENSE.CC-BY-SA-4.0) for the full license text.
