"""
This is used to test the ini library compliance with the python version of ini
files.

This reads standard in as a config file and then writes out the same to
standard out. Any parsing or writing error will cause this to write to standard
error and exit with a failure.
"""

import sys
import ConfigParser


def read_config():
    """Reads a config from standard in"""
    config = ConfigParser.ConfigParser()
    config.readfp(sys.stdin)
    return config


def write_config(config):
    """Writes a config to standard out"""
    config.write(sys.stdout)

if __name__ == "__main__":
    write_config(read_config())

# vim: set ai et sw=4 syntax=python :
