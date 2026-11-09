{
  description = "A flake for for running Robot Framework tests";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      git-hooks,
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
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            robotidy = {
              enable = true;
              name = "Robotidy";
              entry = "${./githooks/check-robotidy.sh}";
              extraPackages = [ pkgs.robotframework-tidy ];
              files = "\\.(robot|resource)$";
              pass_filenames = true;
            };
          };
        };
      in
      {
        checks.pre-commit = pre-commit-check;

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
          buildInputs = (with pkgs; [
            file
            grafana-loki
            imagemagick
            ffmpeg
            iperf
            sshpass
            robotframework-tidy

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
                matplotlib
                rapidfuzz
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
          ]) ++ pre-commit-check.enabledPackages;

          shellHook = pre-commit-check.shellHook + ''
            export PYTHONPATH="${./Robot-Framework}''${PYTHONPATH:+:$PYTHONPATH}"
            if [ -x ./githooks/install-git-hooks.sh ]; then
              if ! ./githooks/install-git-hooks.sh; then
                echo "Git hooks were not installed. Resolve the hook conflict or run the installer manually." >&2
              fi
            fi
          '';
        };

        # Allows formatting files with `nix fmt`
        formatter = pkgs.nixfmt-tree;
      }
    );
}
