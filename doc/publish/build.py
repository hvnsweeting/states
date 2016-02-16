#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst

__author__ = 'Diep Pham'
__maintainer__ = 'Diep Pham'
__email__ = 'favadi@robotinfra.com'

import logging
import subprocess
import os

import pysc

logger = logging.getLogger(__name__)


class PublishDoc(pysc.Application):

    defaults = {"config": "/etc/doc-publish.yml"}

    def main(self):
        config = self.config
        virtualenv = config["virtualenv"]

        logger.debug("Running git pull in %s", config["cwd"])
        subprocess.check_call(
            ["git", "fetch", "origin", config["rev"]],
            cwd=config["cwd"],
        )
        subprocess.check_call(
            ["git", "reset", "--hard", "FETCH_HEAD"],
            cwd=config["cwd"],
        )

        # build docs
        logger.debug("Building doc")
        env = os.environ
        env["VIRTUAL_ENV"] = virtualenv
        subprocess.check_call(
            [os.path.join(virtualenv, "bin", "python"),
             os.path.join("doc", "build.py"),
             config["output"],
             'publish',
             ],
            cwd=config["cwd"],
            env=env,
        )

if __name__ == "__main__":
    PublishDoc().run()
