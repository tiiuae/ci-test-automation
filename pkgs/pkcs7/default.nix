{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
}:
buildPythonPackage rec {
  version = "0.1.2";
  pname = "pkcs7";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "jeppeter";
    repo = "pypkcs7";
    rev = "f8ec81ef4dc7ef061cb15e35b869dccc544e6ddc";
    sha256 = "sha256-MAta84Z0q/C5AUU+tNAPQuqPFLgPDbw8J3OCN4g4LB4=";
  };

  postPatch = ''
    # Delete everything between ##importdebugstart and ##importdebugend
    # from file src/pkcs7/__init_debug__.py
    sed -i '/^##importdebugstart/,/^##importdebugend/d' src/pkcs7/__init_debug__.py
    # Rename src/pkcs7/__init_debug__.py to src/pkcs7/__init__.py
    mv src/pkcs7/__init_debug__.py src/pkcs7/__init__.py
    # Install
    python make_setup.py
    # Move sources to folder, where setup.py search for them
    mv src/pkcs7 pkcs7
  '';

  pythonImportsCheck = ["pkcs7"];
  # unit tests are impure
  # doCheck = false;

  meta = with lib; {
    description = "python package pkcs7 conform for the RFC5652.";
    homepage = "https://github.com/jeppeter/pypkcs7";
    license = licenses.mit;
  };
}
