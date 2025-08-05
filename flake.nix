{
  description = "A flake for for running Robot Framework tests";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      systems = with flake-utils.lib.system; [
        x86_64-linux
        aarch64-linux
      ];
    in
    flake-utils.lib.eachSystem systems (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        callPythonPackage = pkgs.python3Packages.callPackage;
      in
      {
        packages = rec {
          pkcs7 = callPythonPackage ./pkgs/pkcs7 { }; # Requirement of PyP100
          PyP100 = callPythonPackage ./pkgs/PyP100 { inherit pkcs7; };
          plugp100 = callPythonPackage ./pkgs/plugp100 { };

          robotframework-jsonlibrary = callPythonPackage ./pkgs/robotframework-jsonlibrary { };
          robotframework-retryfailed = callPythonPackage ./pkgs/robotframework-retryfailed { };
          robotframework-seriallibrary = callPythonPackage ./pkgs/robotframework-seriallibrary { };
          robotframework-advancedlogging = callPythonPackage ./pkgs/robotframework-advancedlogging { };
          robotframework-debuglibrary = callPythonPackage ./pkgs/robotframework-debuglibrary { };

          KMTronic = pkgs.callPackage ./KMTronic { };
          ghaf-robot = pkgs.callPackage ./pkgs/ghaf-robot {
            inherit
              PyP100
              plugp100
              robotframework-advancedlogging
              robotframework-jsonlibrary
              robotframework-retryfailed
              robotframework-seriallibrary
              robotframework-debuglibrary
              ;
          };
          default = ghaf-robot;
        };

        # Development shell
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            file
            grafana-loki
            imagemagick
            ffmpeg
            iperf

            (python3.withPackages (
              ps:
              (with ps; [
                robotframework
                robotframework-sshlibrary
                pyserial
                python-kasa
                pytz
                pandas
                pyscreeze
                pytesseract
                opencv4
                paramiko
                evdev
              ])
              ++ (with self.packages.${system}; [
                robotframework-jsonlibrary
                robotframework-retryfailed
                robotframework-seriallibrary
                robotframework-advancedlogging
                robotframework-debuglibrary
                PyP100
                plugp100
                KMTronic
              ])
            ))
          ];
        };

        # Allows formatting files with `nix fmt`
        formatter = pkgs.nixfmt-tree;
      }
    );
}
