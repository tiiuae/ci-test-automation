# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  python3,
  writeShellApplication,
}:
writeShellApplication {
  name = "nightly-analyze";
  runtimeInputs = [ (python3.withPackages (ps: [ ps.robotframework ps.jinja2 ])) ];
  text = ''
    exec python3 ${../../tools/nightly-analysis}/nightly_analyze.py "$@"
  '';
}
