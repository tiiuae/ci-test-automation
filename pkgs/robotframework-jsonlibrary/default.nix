{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  robotframework,
  jsonpath-ng,
  jsonschema,
}:
buildPythonPackage rec {
  version = "0.2.0";
  pname = "robotframework-jsonlibrary";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "robotframework-thailand";
    repo = "robotframework-jsonlibrary";
    rev = "ca8bdfec6366529ecd0ed5e93c694787a3f9f57b";
    sha256 = "sha256-1DCxZ/2V2MuKZHDLvjHz73Bq/K2tY03sgRgHvmRY9VQ=";
  };

  doCheck = false; # Tests failing
  propagatedBuildInputs = [
    robotframework
    jsonpath-ng
    jsonschema
  ];

  meta = with lib; {
    description = "Robot Framework test library for manipulating JSON Object. You can manipulate your JSON object using JSONPath";
    homepage = "https://github.com/robotframework-thailand/robotframework-jsonlibrary";
    license = licenses.unlicense;
  };
}
