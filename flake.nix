{
  description = "A flake for for running Robot Framework tests";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    systems = with flake-utils.lib.system; [
      x86_64-linux
      aarch64-linux
    ];
  in
    flake-utils.lib.eachSystem systems (system: let
      pkgs = nixpkgs.legacyPackages.${system}.appendOverlays [
        (self: super: {
          python3 = let
            python = let
              packageOverrides = pyself: pysuper: {
                asyncclick = pysuper.asyncclick.overridePythonAttrs (old: {
                  version = "8.1.8.0-async";
                  src = self.fetchFromGitHub {
                    owner = "python-trio";
                    repo = "asyncclick";
                    rev = "995a2ff3e31826c87cc419fa26e5c019bd115927"; # Matching $version tag, I used commit hash instead tag, because they tends to delete tags (avnik)
                    sha256 = "sha256-J294pYuNOSm7v2BbwDpzn3uelAnZ3ip2U1gWuchhOtA=";
                  };
                  nativeBuildInputs = with pysuper; [flit-core] ++ (old.nativeBuildInputs or []);
                });
              };
            in
              super.python3.override {
                inherit packageOverrides;
                self = python;
              };
          in
            python;
        })
      ];
    in {
      packages = rec {
        ghaf-robot = pkgs.callPackage ./pkgs/ghaf-robot {
          PyP100 = self.packages.${system}.PyP100;
          plugp100 = self.packages.${system}.plugp100;
          robotframework-advancedlogging = self.packages.${system}.robotframework-advancedlogging;
          robotframework-jsonlibrary = self.packages.${system}.robotframework-jsonlibrary;
          robotframework-retryfailed = self.packages.${system}.robotframework-retryfailed;
          robotframework-seriallibrary = self.packages.${system}.robotframework-seriallibrary;
          robotframework-debuglibrary = self.packages.${system}.robotframework-debuglibrary;
        };
        robotframework-jsonlibrary = pkgs.python3Packages.callPackage ./pkgs/robotframework-jsonlibrary {};
        robotframework-retryfailed = pkgs.python3Packages.callPackage ./pkgs/robotframework-retryfailed {};
        robotframework-seriallibrary = pkgs.python3Packages.callPackage ./pkgs/robotframework-seriallibrary {};
        robotframework-advancedlogging = pkgs.python3Packages.callPackage ./pkgs/robotframework-advancedlogging {};
        robotframework-debuglibrary = pkgs.python3Packages.callPackage ./pkgs/robotframework-debuglibrary {};
        pkcs7 = pkgs.python3Packages.callPackage ./pkgs/pkcs7 {}; # Requirement of PyP100
        PyP100 = pkgs.python3Packages.callPackage ./pkgs/PyP100 {inherit pkcs7;};
        plugp100 = pkgs.python3Packages.callPackage ./pkgs/plugp100 {};
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
          (python3.withPackages (ps:
            with ps; [
              robotframework
              self.packages.${system}.robotframework-jsonlibrary
              self.packages.${system}.robotframework-retryfailed
              self.packages.${system}.robotframework-seriallibrary
              self.packages.${system}.robotframework-advancedlogging
              self.packages.${system}.robotframework-debuglibrary
              self.packages.${system}.PyP100
              self.packages.${system}.plugp100
              robotframework-sshlibrary
              pyserial
              python-kasa
              pytz
              pandas
              pyscreeze
              python3Packages.opencv4
              paramiko
            ]))
        ];
      };

      # Allows formatting files with `nix fmt`
      formatter = pkgs.alejandra;
    });
}
