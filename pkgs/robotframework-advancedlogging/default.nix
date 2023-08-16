{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  robotframework,
}:
buildPythonPackage rec {
  version = "2.0.0";
  pname = "robotframework-advancedlogging";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "peterservice-rnd";
    repo = "robotframework-advancedlogging";
    rev = "4f982c09804024273f25de946b43a3a72428a296";
    sha256 = "sha256-eMdlj8zWP7DVh+U6DHJFiPNFyPENrLDWBh0qF2g6dWM=";
  };

  # unit tests are impure
  # doCheck = false;

  propagatedBuildInputs = [
    robotframework
  ];

  meta = with lib; {
    description = "RobotFramework Advanced Logging Library.";
    homepage = "RobotFramework Advanced Logging Library";
    license = licenses.asl20;
  };
}
