#!/usr/bin/env python
import json
import shutil
import sys
import os

root = sys.argv[1]
br_json = sys.argv[2]

print("processing {}".format(br_json))
with open(br_json) as file:
    browsers = json.load(file)
    browsers = {each["name"]: each for each in browsers["browsers"]}


for each in sys.argv[3:]:
    name, path = each.split("=")
    targetname = os.path.basename(path)
    if targetname == "chromium":
        targetname = "chrome"
    dirname = os.path.join(root, "{}-{}/{}-linux".format(name, browsers[name]["revision"], targetname))
    target = os.path.join(dirname, targetname)
    os.makedirs(dirname)
    print("symlinking {} to {}".format(path, target))
    os.symlink(path, target)