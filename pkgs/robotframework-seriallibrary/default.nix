{
  lib,
  buildPythonPackage,
  fetchpatch2,
  fetchPypi,
  robotframework,
  pyserial,
  poetry-core,
}:
buildPythonPackage rec {
  version = "0.4.3";
  pname = "robotframework-seriallibrary";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-8gvv5cEQbdjdyp9govGL9ex9Xwb28JoD+ma65Ud35rs";
  };

  patches = [
    (fetchpatch2 {
      url = "https://patch-diff.githubusercontent.com/raw/whosaysni/robotframework-seriallibrary/pull/23.diff";
      sha256 = "sha256-fuPH+LkCuZBFCWRc1oCsTiqq/i2EsYJwaUh4hrdIJnw=";
    })
  ];

  # unit tests are impure
  # doCheck = false;

  nativeBuildInputs = [
    poetry-core
  ];

  propagatedBuildInputs = [
    robotframework
    pyserial
  ];

  meta = with lib; {
    description = "Robot Framework test library for serial connection";
    homepage = "https://github.com/whosaysni/robotframework-seriallibrary/blob/develop";
    license = licenses.asl20;
  };
}
