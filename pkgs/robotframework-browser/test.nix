{ pkgs, robotframework-browser }:

pkgs.writers.writePython3Bin "robotframework-browser-test" {
  libraries = [ robotframework-browser ];
} (builtins.readFile ./test.py)
