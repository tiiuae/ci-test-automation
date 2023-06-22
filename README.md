<!--
    Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
    SPDX-License-Identifier: CC-BY-SA-4.0
-->

# ci-test-automation

Jenkinsfiles, Robot framework suites, libraries and requirements for running tests to ghaf-project nixOS with real HW.

## drcontrol.py

For more information, see [drcontrol-README.md](./drcontrol/drcontrol-README.md).

## Git commit hook

When contributing to this repo you should take the git commit hook into use.

This hook will check the commit message for most trivial mistakes against [current Ghaf commit message guidelines](https://github.com/tiiuae/ghaf/blob/main/CONTRIBUTING.md#commit-message-guidelines)

### Installing git hooks

Just run ``install_hooks.sh`` in repository main directory, and you should be good to go. Commit message checking script will then run when you commit something.

If you have branches before the git hooks were committed to the repo, you'll have to either rebase them on top of main branch or cherry pick the git hooks commit into your branch.

Also note that any existing commit messages in any branch won't be checked, only new commit messages will be checked.

If you encounter any issues with the git commit message hook, please report them. And while waiting for a fix, you may remove the hook by running ``rm -f .git/hooks/commit-msg`` in the main directory of the repository.

## Licensing

This repository uses following licenses:

| License Full Name | SPDX Short Identifier | Description
| --- | --- | ---
| Apache License 2.0 | [Apache-2.0](https://spdx.org/licenses/Apache-2.0.html) | Source code
| GNU General Public License | [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html) | Source code: drcontrol
| Creative Commons Attribution Share Alike 4.0 International | [CC-BY-SA-4.0](https://spdx.org/licenses/CC-BY-SA-4.0.html) | Documentation

See [LICENSE.Apache-2.0](./LICENSES/LICENSE.Apache-2.0), [LICENSE.GPLv3](./LICENSES/LICENSE.GPLv3), and [LICENSE.CC-BY-SA-4.0](./LICENSES/LICENSE.CC-BY-SA-4.0) for the full license text.
