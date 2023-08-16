{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pycryptodome,
  pkcs7,
  requests,
}:
buildPythonPackage rec {
  version = "0.1.2";
  pname = "PyP100";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "fishbigger";
    repo = "TapoP100";
    rev = "43f51a03ab7a647f81682f7b39ceb2afdd04d3a1";
    sha256 = "sha256-aMrjoh4n5Ygu1hT8BYW2Zez4s33FZqoscN9O2Uga4Ls=";
  };

  # unit tests are impure
  # doCheck = false;

  propagatedBuildInputs = [
    pycryptodome
    pkcs7
    requests
  ];

  meta = with lib; {
    description = "A library for controlling the Tp-link Tapo P100/P105/P110 plugs and L530/L510E bulbs.";
    homepage = "https://github.com/fishbigger/TapoP100";
    license = licenses.mit;
  };
}
