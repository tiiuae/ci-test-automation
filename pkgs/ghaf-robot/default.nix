{
  PyP100,
  plugp100,
  python3,
  robotframework-advancedlogging,
  robotframework-retryfailed,
  robotframework-seriallibrary,
  stdenv,
  writeShellApplication,
}:
writeShellApplication {
  name = "ghaf-robot";
  runtimeInputs = [
    (python3.withPackages (ps: [
      # These are taken from nixpkgs
      ps.robotframework
      ps.robotframework-sshlibrary
      ps.pyserial
      ps.python-kasa

      # These are taken from this flake
      robotframework-advancedlogging
      robotframework-retryfailed
      robotframework-seriallibrary
      PyP100
      plugp100
    ]))
  ];
  text = ''
    # A shell script which runs Robot Framework in an environment where all the
    # required dependency Python modules are present.
    exec robot "$@"
  '';
}
