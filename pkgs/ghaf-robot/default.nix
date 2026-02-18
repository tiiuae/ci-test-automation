{
  PyP100,
  iperf,
  imagemagick,
  ffmpeg,
  plugp100,
  python3,
  robotframework-advancedlogging,
  robotframework-jsonlibrary,
  robotframework-retryfailed,
  robotframework-seriallibrary,
  robotframework-debuglibrary,
  stdenv,
  writeShellApplication,
}:
writeShellApplication {
  name = "ghaf-robot";
  runtimeInputs = [
    iperf
    imagemagick
    ffmpeg
    (python3.withPackages (ps: [
      # These are taken from nixpkgs
      ps.robotframework
      ps.robotframework-sshlibrary
      ps.pyserial
      ps.python-kasa
      ps.pytz
      ps.pandas
      ps.pyscreeze
      ps.pytesseract
      ps.opencv4
      ps.evdev
      ps.matplotlib

      # These are taken from this flake
      robotframework-advancedlogging
      robotframework-jsonlibrary
      robotframework-retryfailed
      robotframework-seriallibrary
      robotframework-debuglibrary
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
