{
  buildPythonApplication,
  pylibftdi,
}:
buildPythonApplication {
  pname = "drcontrol";
  version = "0.13";
  propagatedBuildInputs = [ pylibftdi ];
  src = ./.;
}
