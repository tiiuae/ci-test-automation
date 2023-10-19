{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  requests,
  certifi,
  cryptography,
  jsons,
  aiohttp,
  semantic-version,
  scapy,
}:
buildPythonPackage rec {
  version = "3.12.0";
  pname = "plugp100";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "petretiandrea";
    repo = "plugp100";
    rev = "b0757fa4cb5408a714d57157e487fb0d565ed246";
    sha256 = "sha256-j6S8qSuqRlIjozz/2/HdOAjNJhzIRNINwfcEOK4bH5E=";
  };

  # unit tests are impure
  # doCheck = false;

  propagatedBuildInputs = [
    requests
    certifi
    cryptography
    jsons
    aiohttp
    semantic-version
    scapy
  ];

  dontUseSetuptoolsCheck = true;

  meta = with lib; {
    description = "A library for controlling the Tp-link Tapo P100/P105/P110 plugs and L530/L510E bulbs.";
    homepage = "https://github.com/petretiandrea/plugp100";
    license = licenses.mit;
  };
}
