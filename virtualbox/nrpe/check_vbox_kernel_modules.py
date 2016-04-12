#!/usr/local/nagios/bin/python
# -*- coding: utf-8 -*-

"""
NRPE script checks whether the VirtualBox kernel modules are loaded or not
"""

import logging
import re
import subprocess

import nagiosplugin as nap

from pysc import nrpe

__author__ = 'Quan Tong Anh <quanta@robotinfra.com>'
__maintainer__ = 'Quan Tong Anh <quanta@robotinfra.com>'
__email__ = 'quanta@robotinfra.com'

log = logging.getLogger('nagiosplugin.virtualbox.kernel')


class VBoxKernelModules(nap.Resource):
    def probe(self):
        log.debug("VBoxKernelModules.probe started")
        try:
            output = subprocess.check_output(['/etc/init.d/vboxdrv', 'status'])
        except OSError:
            pass
        else:
            kernel_modules = re.findall('vbox', output)
        log.debug("VBoxKernelModules.probe finished")
        return [nap.Metric('kernelmodules', len(kernel_modules), min=0)]


def check_vbox_kernel_modules(config):
    return (
        VBoxKernelModules(),
        nap.ScalarContext('kernelmodules',
                          nap.Range('{}:{}'.format(config['warning'],
                                                   config['warning'])),
                          nap.Range('{}:{}'.format(config['warning'],
                                                   config['warning'])),
                          fmt_metric='{value} kernel modules are loaded')
    )


if __name__ == '__main__':
    nrpe.check(check_vbox_kernel_modules,
               {'warning': 4})
