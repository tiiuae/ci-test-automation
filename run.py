#!/usr/bin/env python
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2022-2023 Ville-Pekka Juntunen <ville-pekka.juntunen@unikie.com>
# SPDX-FileCopyrightText: 2022-2023 Unikie
# SPDX-FileCopyrightText: 2022-2023 Technology Innovation Institute (TII)
import sys
import argparse

from robot import run_cli           # use cli versions as you can pass cli arguments to them straight up

from os.path import abspath, dirname, exists as path_exists, join as path_join
#
#
CURDIR = abspath(dirname(__file__))
TESTROOT = path_join(CURDIR, "Robot-Framework/test-suites")
# LIBROOT = path_join(CURDIR, 'libs')
# MODIFIERSROOT = path_join(CURDIR, 'modifiers')

TIMEOUT = '60s'

class RunParser(object):
    def __init__(self):
        self.parser = argparse.ArgumentParser(description="Main script to work with test assets.")
        self.parser.add_argument('-i', '--force_tag', nargs=1, action='append', help='Force tag argument for running RF suites')
        self.parser.add_argument('-v', '--variable', nargs=1, action='append', help='Variable(s) for RF suites')
        self.args = self.parser.parse_args()

    def parse_arguments(self, args):
        print(args)

def main(cli_args):
    parser = RunParser()
    parser.parse_arguments(parser.args)
    #print(parser.args)
    # run_args = ["--include", parser.args.force_tag, "--variable", parser.args.variable, TESTROOT]
    # var_args = ["--variable", parser.args.variable]
    # print(run_args)
    # rc = run_cli(run_args)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
