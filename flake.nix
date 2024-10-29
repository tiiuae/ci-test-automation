{
  description = "A flake for for running Robot Framework tests";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    blank.url = "github:divnix/blank";
    dream2nix = {
      url = "github:nix-community/dream2nix";
      inputs.nixpkgs.follows = "nixpkgs";

      # Blank unused inputs, to prevent unneeded downloads
      inputs.pyproject-nix.follows = "blank";
      inputs.purescript-overlay.follows = "blank";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    dream2nix,
    ...
  }: let
    systems = with flake-utils.lib.system; [
      x86_64-linux
      aarch64-linux
    ];
  in
    flake-utils.lib.eachSystem systems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in rec {
      packages = rec {
        ghaf-robot = pkgs.callPackage ./pkgs/ghaf-robot {
          PyP100 = self.packages.${system}.PyP100;
          plugp100 = self.packages.${system}.plugp100;
          robotframework-advancedlogging = self.packages.${system}.robotframework-advancedlogging;
          robotframework-jsonlibrary = self.packages.${system}.robotframework-jsonlibrary;
          robotframework-retryfailed = self.packages.${system}.robotframework-retryfailed;
          robotframework-seriallibrary = self.packages.${system}.robotframework-seriallibrary;
        };
        robotframework-jsonlibrary = pkgs.python3Packages.callPackage ./pkgs/robotframework-jsonlibrary {};
        robotframework-retryfailed = pkgs.python3Packages.callPackage ./pkgs/robotframework-retryfailed {};
        robotframework-seriallibrary = pkgs.python3Packages.callPackage ./pkgs/robotframework-seriallibrary {};
        robotframework-browser = pkgs.python3Packages.callPackage ./pkgs/robotframework-browser { inherit dream2nix; };
        robotframework-browser-test = pkgs.python3Packages.callPackage ./pkgs/robotframework-browser/test.nix { inherit robotframework-browser; };
        robotframework-advancedlogging = pkgs.python3Packages.callPackage ./pkgs/robotframework-advancedlogging {};
        pkcs7 = pkgs.python3Packages.callPackage ./pkgs/pkcs7 {}; # Requirement of PyP100
        PyP100 = pkgs.python3Packages.callPackage ./pkgs/PyP100 {inherit pkcs7;};
        plugp100 = pkgs.python3Packages.callPackage ./pkgs/plugp100 {};
        default = ghaf-robot;
      };

      apps = {
        robotframework-browser-test = {
          program = "${packages.robotframework-browser-test}/bin/robotframework-browser-test";
          type = "app";
        };
      };

      # Development shell
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          iperf
          file
          imagemagick
          (python3.withPackages (ps:
            with ps; [
              robotframework
              self.packages.${system}.robotframework-jsonlibrary
              self.packages.${system}.robotframework-retryfailed
              self.packages.${system}.robotframework-seriallibrary
              self.packages.${system}.robotframework-advancedlogging
              self.packages.${system}.PyP100
              self.packages.${system}.plugp100
              robotframework-sshlibrary
              pyserial
              python-kasa
              pytz
              pandas
              pyscreeze
              python3Packages.opencv4
            ]))
        ];
      };

      # Allows formatting files with `nix fmt`
      formatter = pkgs.alejandra;
    });
}
