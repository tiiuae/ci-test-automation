{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  robotframework,
}:
buildPythonPackage rec {
  version = "v2.5.0";
  pname = "robotframework-debuglibrary";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "xyb";
    repo = "robotframework-debuglibrary";
    rev = "v2.5.0";
    sha256 = "sha256-GgS6qj5wl3l3DmGRsmgr6oKvatdIWyz+Ys9X8yHWLRY=";
  };

  doCheck = false; # Tests failing
  propagatedBuildInputs = [
    robotframework
  ];

  meta = with lib; {
    description = "Robotframework-DebugLibrary is a debug library for RobotFramework, which can be used as an interactive shell(REPL) also.";
    homepage = "https://github.com/xyb/robotframework-debuglibrary";
    license = licenses.bsd3;
  };
}
