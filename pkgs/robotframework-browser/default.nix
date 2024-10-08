{
  lib,
  buildPythonPackage,
  robotframework,
  fetchpatch2
}:
buildPythonPackage rec {
  version = "18.9.1";
  pname = "robotframework-browser";
  format = "pyproject";

 patches = [
   (fetchpatch2 {
     url = "https://github.com/MarketSquare/robotframework-browser/commit/d4456964ba3bae455f5de4a09d465a61d1c4a6ca.patch";
     sha256 = "sha256-GIM8yFWJoT3iNS0w7y1ofzE2ivsdS1BmUB2QDpmmjXo=";
   })
 ];

  doCheck = false; # Tests failing
  propagatedBuildInputs = [
    robotframework
  ];

  meta = with lib; {
    description = "Robot Framework Browser library powered by Playwright.";
    homepage = "https://github.com/MarketSquare/robotframework-browser";
    license = licenses.asl20;
  };
}
