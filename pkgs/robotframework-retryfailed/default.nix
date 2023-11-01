{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  robotframework,
}:
buildPythonPackage rec {
  version = "0.2.0";
  pname = "robotframework-retryfailed";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "MarketSquare";
    repo = "robotframework-retryfailed";
    rev = "115eca8ad03a1e0e08a71251cc69bc41bd70f0f5";
    sha256 = "sha256-Ls8ZGbM3Ucm5+vqrFOmz9NiEisxyRSYw5P+oqrXo/Ck=";
  };

  # unit tests are impure
  # doCheck = false;

  propagatedBuildInputs = [
    robotframework
  ];

  meta = with lib; {
    description = "A listener to automatically retry tests or tasks based on flags.";
    homepage = "https://github.com/MarketSquare/robotframework-retryfailed";
    license = licenses.asl20;
  };
}
