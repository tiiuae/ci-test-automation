{
  lib,
  python3Packages,
  libftdi,
}:
python3Packages.buildPythonApplication {
  pname = "drcontrol";
  version = "0.13";
  propagatedBuildInputs = [python3Packages.pylibftdi];
  src = ./.;
}
