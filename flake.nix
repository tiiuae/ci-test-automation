{
  description = "A flake for for running Robot Framework tests";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
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
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = rec {
        ghaf-robot = pkgs.callPackage ./pkgs/ghaf-robot {
          PyP100 = self.packages.${system}.PyP100;
          plugp100 = self.packages.${system}.plugp100;
          robotframework-advancedlogging = self.packages.${system}.robotframework-advancedlogging;
          robotframework-jsonlibrary = self.packages.${system}.robotframework-jsonlibrary;
          robotframework-retryfailed = self.packages.${system}.robotframework-retryfailed;
          robotframework-seleniumlibrary = self.packages.${system}.robotframework-seleniumlibrary;
          robotframework-seriallibrary = self.packages.${system}.robotframework-seriallibrary;
        };
        robotframework-jsonlibrary = pkgs.python3Packages.callPackage ./pkgs/robotframework-jsonlibrary {};
        robotframework-retryfailed = pkgs.python3Packages.callPackage ./pkgs/robotframework-retryfailed {};
        robotframework-seleniumlibrary = pkgs.python3Packages.callPackage ./pkgs/robotframework-seleniumlibrary {};
        robotframework-seriallibrary = pkgs.python3Packages.callPackage ./pkgs/robotframework-seriallibrary {};
        robotframework-advancedlogging = pkgs.python3Packages.callPackage ./pkgs/robotframework-advancedlogging {};
        pkcs7 = pkgs.python3Packages.callPackage ./pkgs/pkcs7 {}; # Requirement of PyP100
        PyP100 = pkgs.python3Packages.callPackage ./pkgs/PyP100 {inherit pkcs7;};
        plugp100 = pkgs.python3Packages.callPackage ./pkgs/plugp100 {};
        default = ghaf-robot;
      };

      # Development shell
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          iperf
          (python3.withPackages (ps:
            with ps; [
              robotframework
              self.packages.${system}.robotframework-jsonlibrary
              self.packages.${system}.robotframework-retryfailed
              self.packages.${system}.robotframework-seleniumlibrary
              self.packages.${system}.robotframework-seriallibrary
              self.packages.${system}.robotframework-advancedlogging
              self.packages.${system}.PyP100
              self.packages.${system}.plugp100
              robotframework-sshlibrary
              pyserial
              python-kasa
              pytz
              pandas
            ]))
        ];
      };

      # Allows formatting files with `nix fmt`
      formatter = pkgs.alejandra;
    });
}
