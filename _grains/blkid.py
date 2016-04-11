# -*- coding: utf-8 -*-

# Usage of this is governed by a license that can be found in doc/license.rst.

"""
Return all block devices available.
"""

__author__ = 'Diep Pham'
__maintainer__ = 'Diep Pham'
__email__ = 'favadi@robotinfra.com'

import logging

logger = logging.getLogger(__name__)

# Solve the Chicken and egg problem where grains need to run before any
# of the modules are loaded and are generally available for any usage.
import salt.modules.cmdmod

__salt__ = {
    'cmd.run': salt.modules.cmdmod._run_quiet
}


def blkid():
    grains = {"blkid": []}
    output = __salt__['cmd.run']('blkid')
    logger.debug("blkid cmd output: %s",  output)
    for line in output.splitlines():
        device = line.split()[0][:-1]  # remove the `:` character
        grains["blkid"].append(device)
    logger.debug("blkid grains: %s", grains)
    return grains

if __name__ == '__main__':
    print blkid()
