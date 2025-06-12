{ pkgs, ... }:
pkgs.python3Packages.buildPythonPackage {
  pname = "KMTronic";
  format = "setuptools";
  version = "git";
  src = pkgs.lib.cleanSource ./.;
  propagatedBuildInputs = with pkgs.python3Packages; [ pyserial ];
}
