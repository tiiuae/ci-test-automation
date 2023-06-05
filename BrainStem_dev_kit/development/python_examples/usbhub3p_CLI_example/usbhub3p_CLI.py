import brainstem
#for easy access to error constants
from brainstem.result import Result

import sys
import argparse


class ArgumentParser(object):

    def __init__(self):
        self._parser = argparse.ArgumentParser()
        self._port = 0
        self._enable = 0;
        self._output = sys.stderr

    @property
    def port(self):
        return self._port

    @property
    def enable(self):
        return self._enable

    def print_usage(self):
        return self._parser.print_usage(self._output)

    def print_help(self):
        return self._parser.print_help(self._output)

    def parse_arguments(self, args):

        self._parser.add_argument("-p", "--port", help="Port to enable/disable", type=int, metavar='', choices={0, 1, 2, 3, 4, 5, 6, 7})
        self._parser.add_argument("-e", "--enable", help="Enable/Disable ", type=int, metavar='', choices={0, 1})

        args = self._parser.parse_args(args[1:])

        self._port = args.port
        self._enable = args.enable



def main(argv):
    try:
        print(argv)
        arg_parser = ArgumentParser()
        if arg_parser.parse_arguments(argv):
            return 1

        print("Port: %d" % (arg_parser.port))
        print("Enable: %d" % (arg_parser.enable))

        # Change the brainstem object if you want to connect to a differet module.
        # i.e. As is, this example will NOT connect to anything except a USBHub3c.
        stem = brainstem.stem.USBHub3p()
        # stem = brainstem.stem.USBHub2x4() 

        result = stem.discoverAndConnect(1)
        if result == Result.NO_ERROR:
            if arg_parser.enable:
                e = stem.usb.setPortEnable(arg_parser.port)
            else:
                e = stem.usb.setPortDisable(arg_parser.port)
        else:
            printf("Error Connecting to USBHub3p(). Make sure you are using the correct module object")
        
        stem.disconnect()

    except IOError as e:
        print("Exception - IOError: ", e)
        return 2
    except SystemExit as e:
        return 3

    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))