#!/bin/bash
# This script is used as "action" of hydrascraper.py and it will copy given Hydra build nix store from http://binarycache.vedenemo.dev
# And it add Hydra build ID to working list if copy succeeded
set -e

echo "Hydra Build ID: $1"
echo "Hydra store path:  $2"
nix copy --from http://binarycache.vedenemo.dev $2
nix copy --derivation --from http://binarycache.vedenemo.dev `nix-store --query --deriver $2`
echo "Add build ID and store path to working list"
echo "$1:$2" >> wlist.txt
