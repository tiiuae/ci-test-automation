{
  description = "A flake for for running Robot Framework tests";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
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
        packages.ghaf-robot = pkgs.callPackage ./Robot-Framework {};
        packages.robotframework-seriallibrary = pkgs.python3Packages.callPackage ./pkgs/robotframework-seriallibrary {
        packages.default = self.packages.${system}.ghaf-robot;
      };

      # Development shell
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          (python3.withPackages (ps:
            with ps; [
              robotframework
              self.packages.${system}.robotframework-seriallibrary
              robotframework-sshlibrary
              pyserial
            ]))
        ];
      };

      # Allows formatting files with `nix fmt`
      formatter = pkgs.alejandra;
    });
}
