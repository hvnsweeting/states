#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst

import os
import sys

ROBOTS_TXT = """
User-agent: *
Disallow:
"""


def in_directory(dir1, dir2):
    dirs1 = dir1.split(os.sep)
    dirs2 = dir2.split(os.sep)

    for i in range(0, len(dirs1)):
        try:
            if dirs1[i] != dirs2[i]:
                return False
        except IndexError:
            return False
    return True


def common_root_dir():
    my_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(my_dir, '..'))


def main():
    root_dir = common_root_dir()
    default_directory = os.path.abspath(os.path.join(root_dir, '..',
                                                     'salt-doc'))

    if len(sys.argv) > 2:
        print "Invalid argument."
        print "%s [output-directory]"
        print "Default directory: %s" % default_directory
        sys.exit(1)

    # check if it's a valid virtualenv path
    virtualenv_key = 'VIRTUAL_ENV'
    if virtualenv_key not in os.environ:
        print "Please use a Python VirtualEnv"
        sys.exit(1)
    virtual_env = os.path.abspath(os.environ[virtualenv_key])

    if in_directory(virtual_env, root_dir):
        print "Please don't use Python VirtualEnv %s inside %s" % (virtual_env,
                                                                   root_dir)
        sys.exit(1)

    # replace argv to pass to sphinx-build
    try:
        output_dir = sys.argv[1]
        if output_dir.startswith(root_dir):
            print "Please specify an output directory outside %s" % root_dir
            sys.exit(1)
    except IndexError:
        output_dir = default_directory
        print 'Output directory is %s' % default_directory

    os.chdir(root_dir)
    sys.argv[1:] = ['-b', 'singlehtml', '-c', 'doc', '-W', '.', output_dir]

    from pkg_resources import load_entry_point
    sys.exit(
        load_entry_point('Sphinx', 'console_scripts', 'sphinx-build')()
    )

    with open(os.path.join(output_dir, 'robots.txt'), 'w') as robots:
        robots.write(ROBOTS_TXT)

if __name__ == '__main__':
    main()
