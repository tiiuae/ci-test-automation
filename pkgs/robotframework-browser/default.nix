{
  lib,
  stdenv,
  pkgs,
  dream2nix,
  runCommand,
  which,
  buildPythonPackage,
  robotframework,
  fetchpatch2,
  fetchPypi,
  fetchFromGitHub,
  playwright-driver,
  poetry-core,
  robotframework-pythonlibcore,
  overrides,
  seedir,
  grpcio,
  wrapt,
  setuptools,
  cython,
  c-ares,
  openssl,
  six,
  pkg-config,
  zlib,
}:
let
  protobuf = buildPythonPackage rec {
    pname = "protobuf";
    version = "5.28.3";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-ZLrbxJGApeQB83P5znqx0Ytj991KnNxDySufC0gc73s=";
    };

    build-system = [ setuptools ];
  };
  grpcio = buildPythonPackage rec {
    pname = "grpcio";
    format = "setuptools";
    version = "1.67.0";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-4JCyVT4Noch1RJyOdQc91EFd1xyb3mpAYkD99MDuRnw=";
    };

    outputs = [
      "out"
      "dev"
    ];

    nativeBuildInputs = [
      cython
      pkg-config
    ];

    buildInputs = [
      c-ares
      openssl
      zlib
    ];
    propagatedBuildInputs =
      [
        six
        protobuf
      ];
    preBuild =
    ''
      export GRPC_PYTHON_BUILD_EXT_COMPILER_JOBS="$NIX_BUILD_CORES"
      if [ -z "$enableParallelBuilding" ]; then
        GRPC_PYTHON_BUILD_EXT_COMPILER_JOBS=1
      fi
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      unset AR
    '';

  GRPC_BUILD_WITH_BORING_SSL_ASM = "";
  GRPC_PYTHON_BUILD_SYSTEM_OPENSSL = 1;
  GRPC_PYTHON_BUILD_SYSTEM_ZLIB = 1;
  GRPC_PYTHON_BUILD_SYSTEM_CARES = 1;
  };

  # the pypi source archive does not ship tests
  doCheck = false;
  robotframework-assertion-engine = buildPythonPackage rec {
    pname = "robotframework-assertion-engine";
    version = "3.0.3";
    format = "pyproject";

    src = fetchFromGitHub {
      owner = "MarketSquare";
      repo = "AssertionEngine";
      rev = "v${version}";
      sha256 = "sha256-RPaCf5IzLEUVsolpWvTD/ShXrFo+GAkVaEfmwSBGQdM=";
    };

    nativeBuildInputs = [ poetry-core ];
    propagatedBuildInputs = [
      robotframework
      robotframework-pythonlibcore
    ];

  };

  version = "18.9.1";
  pname = "robotframework-browser";
  rf-browser-sources = fetchPypi {
    inherit pname version;
    sha256 = "sha256-+6RXnLOtZJzQOoz3fu5T8gEphgf6x8/PHbP3iqrp/WI=";
  };
  browser-wrapper-sources =  stdenv.mkDerivation {
    preferLocalBuild = true;
    pname = "browser-wrapper-sources";
    inherit version;
    src = rf-browser-sources;
    buildPhase = "";
    installPhase = ''
      cp -rv Browser/wrapper $out
    '';
  };
  browser-wrapper = dream2nix.lib.evalModules {
    packageSets.nixpkgs = pkgs; 
    modules = [
      ({ dream2nix, config, ...}: {
        imports = [
          dream2nix.modules.dream2nix.nodejs-package-lock-v3
          dream2nix.modules.dream2nix.nodejs-granular-v3
        ];
        mkDerivation.src = browser-wrapper-sources;
        deps = {...}: { inherit stdenv; };
        nodejs-package-lock-v3 = {
          packageLockFile = "${config.mkDerivation.src}/package-lock.json";
        };
        nodejs-granular-v3.overrides."grpc-tools".mkDerivation.postPatch = ''
          find ${pkgs.grpc-tools}
          substituteInPlace package.json --replace-fail "node-pre-gyp install" "cp ${pkgs.grpc-tools}/bin/protoc bin/ && cp ${pkgs.grpc-tools}/bin/grpc_node_plugin bin";
        '';
        mkDerivation.postPatch = ''
          substituteInPlace package.json --replace-fail "node ./node/build.wrapper.js" "echo Nope" 
        '';
        mkDerivation.nativeBuildInputs = [ which ];
        mkDerivation.postInstall = ''
          mkdir -p $out/bin
          which node
          makeWrapper "$(which node)" "$out/bin/node" \
            --prefix NODE_PATH : ${placeholder "out"}/lib/node_modules \
            --set-default PLAYWRIGHT_BROWSERS_PATH "${playwright-driver.passthru.browsers}"
        '';
        name = "browser-wrapper";
        inherit version;
      })
    ];
  };
in
buildPythonPackage rec {
  inherit pname version;
  format = "setuptools";
  src = rf-browser-sources;

  postPatch = ''
    substituteInPlace Browser/playwright.py --replace-fail '"node"' '"${browser-wrapper}/bin/node"'
  '';

  postInstall = ''
    ln -sf ${browser-wrapper}/lib/node_modules $out/lib/python3.11/site-packages/Browser/wrapper/node_modules 
  '';

#  patches = [
#     (fetchpatch2 {
#       url = "https://github.com/MarketSquare/robotframework-browser/commit/d4456964ba3bae455f5de4a09d465a61d1c4a6ca.patch";
#       sha256 = "sha256-GIM8yFWJoT3iNS0w7y1ofzE2ivsdS1BmUB2QDpmmjXo=";
#     })
#   ];

  doCheck = false; # Tests failing
  preCheck = ''
    export PLAYWRIGHT_BROWSERS_PATH=${playwright-driver.browsers}
  '';

  pythonImportsCheck = [ "Browser" ];

  propagatedBuildInputs = [
    browser-wrapper # FIXME
    robotframework
    robotframework-assertion-engine
    robotframework-pythonlibcore
    overrides
    seedir
    protobuf
    grpcio
    wrapt
  ];

  meta = with lib; {
    description = "Robot Framework Browser library powered by Playwright.";
    homepage = "https://github.com/MarketSquare/robotframework-browser";
    license = licenses.asl20;
  };
}
