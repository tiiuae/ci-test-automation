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
  chromium,
  ffmpeg,
  makeWrapper
}:
let
  # RF Browser require newer, exact this version
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

  # RF Browser require newer, exact this version
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

  # Missing dependency for RF Browser
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

  # Extract JS wrapper source from python' one
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

  # Build NodeJS part using dream2nix magic
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
          # FIXME: could we avoid IFD here?
          packageLockFile = "${config.mkDerivation.src}/package-lock.json";
        };

        # Use prebuilts from nixpkgs, otherwise node-pre-gyp try to download binaries during build time
        nodejs-granular-v3.overrides."grpc-tools".mkDerivation.postPatch = ''
          find ${pkgs.grpc-tools}
          substituteInPlace package.json --replace-fail "node-pre-gyp install" "cp ${pkgs.grpc-tools}/bin/protoc bin/ && cp ${pkgs.grpc-tools}/bin/grpc_node_plugin bin";
        '';

        # We don't need really build, just create node_modules
        mkDerivation.postPatch = ''
          substituteInPlace package.json --replace-fail "node ./node/build.wrapper.js" "echo Nope"
        '';

        # Make a wrapper of `node` with injected node_modules and PLAYWRIGHT_BROWSERS_PATH
        mkDerivation.nativeBuildInputs = [ which ];
        mkDerivation.postInstall = ''
          mkdir -p $out/bin $out/browsers
          python ${./make-browsers.py} \
            $out/browsers \
            $out/lib/node_modules/browser-wrapper/node_modules/playwright-core/browsers.json \
            chromium=${chromium}/bin/chromium \
            ffmpeg=${ffmpeg}/bin/ffmpeg
          ln -sf $(which node) $out/bin/node
          ln -sf $out/browsers $out/lib/node_modules/browser-wrapper/node_modules/playwright-core/.local-browsers
        '';
        name = "browser-wrapper";
        inherit version;
      })
    ];
  };
  node-wrapper = runCommand "node-and-browser-wrapper" {
    runLocal = true;
    nativeBuildInputs = [ pkgs.python3 makeWrapper ];
  } ''
    mkdir -p $out/bin
    ln -sf ${browser-wrapper}/browsers $out/browsers
    makeWrapper "${browser-wrapper}/bin/node" "$out/bin/node" \
      --prefix NODE_PATH : ${browser-wrapper}/lib/node_modules/browser-wrapper/node_modules/ \
      --set-default PLAYWRIGHT_BROWSERS_PATH "${placeholder "out"}/browsers"
    cat $out/bin/node
  '';
in
buildPythonPackage rec {
  inherit pname version;
  format = "setuptools";
  src = rf-browser-sources;

  # Hijack our node wrapper
  postPatch = ''
    substituteInPlace Browser/playwright.py --replace-fail '"node"' '"${node-wrapper}/bin/node"'
  '';

  # playwright.py check if this directory exists in runtime, so inject symlink here as well
  postInstall = ''
    ln -sf ${browser-wrapper}/lib/node_modules/browser-wrapper/node_modules $out/lib/python3.11/site-packages/Browser/wrapper/node_modules
  '';

#  patches = [
#     (fetchpatch2 {
#       url = "https://github.com/MarketSquare/robotframework-browser/commit/d4456964ba3bae455f5de4a09d465a61d1c4a6ca.patch";
#       sha256 = "sha256-GIM8yFWJoT3iNS0w7y1ofzE2ivsdS1BmUB2QDpmmjXo=";
#     })
#   ];

  doCheck = false; # Tests failing
  preCheck = ''
    export PLAYWRIGHT_BROWSERS_PATH=${node-wrapper}/browsers
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
