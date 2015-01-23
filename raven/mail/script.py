#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Do not edit this file, this is handled by Salt and your changes will be lost.

# Use of this source code is governed by a BSD license that can be
# found in the doc/license.rst file.
#
# Author: Bruno Clermont <bruno@robotinfra.com>
# Maintainer: Quan Tong Anh <quanta@robotinfra.com>

"""
RavenMail: Emulate /usr/bin/mail(x) but send mail to a Sentry server instead.
"""

import os
import sys

import pysc


class Mail(pysc.Application):
    """
    Send an email
    """
    def get_argument_parser(self):
        argp = super(Mail, self).get_argument_parser()
        argp.add_argument('-s', '--subject', help="Subject")
        argp.add_argument('extra_args', nargs='*')
        return argp

    def main(self):
        # consume standard input early
        body = os.linesep.join(sys.stdin.readlines())
        if not len(body):
            sys.stderr.write("Empty stdin, nothing to report")
            sys.stderr.write(os.linesep)
            sys.exit(1)

        # init raven quickly, so if something is wrong it get logged early
        from raven import Client
        dsn = self.config['sentry_dsn']
        if not dsn.startswith("requests+"):
            dsn = "requests+" + dsn
        client = Client(dsn=dsn)

        if self.config['subject']:
            msg = os.linesep.join((self.config['subject'], body))
        else:
            msg = body
        client.captureMessage(msg, extra=os.environ)

if __name__ == "__main__":
    try:
        Mail().run()
    except Exception as e:
        # pysc log will not work here, initialize and use new one.
        # only doing it here, or it might affect pysc's logging feature.
        import logging
        import logging.handlers
        log = logging.getLogger('raven.mail')
        syslog = logging.handlers.SysLogHandler()
        syslog.setFormatter(logging.Formatter("%(name)s %(message)s"))
        log.addHandler(syslog)
        log.setLevel(logging.ERROR)

        log.error(e, exc_info=True)
