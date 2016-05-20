#!/usr/local/nagios/bin/python
# -*- coding: utf-8 -*-
# Use of this is governed by a license that can be found in doc/license.rst.

'''
Script for testing functionality of a whole mail stack.
Check send normal mail, spam mail and virus email
'''

__author__ = 'Viet Hung Nguyen'
__maintainer__ = 'Viet Hung Nguyen'
__email__ = 'hvn@robotinfra.com'

import imaplib
import logging
import smtplib
import time
import uuid

import nagiosplugin as nap

from pysc import nrpe

log = logging.getLogger('nagiosplugin.dovecot.mail_stack')


def pad_uuid(msg):
    # to make each test unique
    return '. '.join((msg, 'UUID: %s' % uuid.uuid4().hex))


class EmptyMailboxError(Exception):
    pass


class MailStackHealth(nap.Resource):
    def __init__(self,
                 imap_server,
                 smtp_server,
                 username,
                 password,
                 smtp_wait,
                 ssl):
        log.debug("MailStackHealth(%s, %s, %s, <password>, %s, %s)",
                  imap_server, smtp_server, username, smtp_wait, ssl)
        if ssl:
            self.imap = imaplib.IMAP4_SSL(imap_server)
            self.smtp = smtplib.SMTP_SSL(smtp_server, 465)
        else:
            self.imap = imaplib.IMAP4(imap_server)
            self.smtp = smtplib.SMTP(smtp_server)

        log.debug('IMAP login: %s', self.imap.login(username, password))

        # always recreate `spam` mailbox for clean testing, cannot delete INBOX
        # as IMAP server does not allow doing that.
        log.debug(self.imap.delete('spam'))
        log.debug(self.imap.create('spam'))

        # cleanup all mail existing in INBOX
        self.imap.select('INBOX')
        _, _data = self.imap.search(None, 'ALL')
        for num in _data[0].split():
            self.imap.store(num, '+FLAGS', '\\Deleted')
        self.imap.expunge()
        self.imap.close()

        log.debug('SMTP EHLO: %s', self.smtp.ehlo())
        log.debug('SMTP login: %s', self.smtp.login(username, password))

        self.username = username
        self.password = password
        self.waittime = smtp_wait

    def probe(self):
        log.debug("MailStackHealth.probe started")
        inboxtest = spamtest = virustest = False
        try:
            inboxtest = self.test_send_and_receive_email_in_inbox_mailbox()
            spamtest = self.test_send_and_receive_GTUBE_spam_in_spam_folder()
            virustest = self.test_send_virus_email_and_discarded_by_amavis()
        except EmptyMailboxError as e:
            pass

        passed_checks = (spamtest, inboxtest, virustest).count(True)

        log.debug("MailStackHealth.probe finished")
        log.debug("returning all(%s)", str((spamtest, inboxtest, virustest)))
        return [nap.Metric('features', passed_checks, context='working')]

    def send_email(self, subject, rcpts, body, _from=None, wait=0):
        log.debug("Sending email to %s", rcpts)
        if _from is None:
            _from = self.username
        msg = '''\
From: %s
Subject: %s

%s
''' % (_from, subject, body)

        ret = self.smtp.sendmail(_from, rcpts, msg)

        time.sleep(wait)
        log.debug('Send mail from %s, to %s, msg %s, return %s',
                  _from, rcpts, msg, ret)

    def _send_email_for_test(self, subject, body):
        body = pad_uuid(body)
        self.send_email(subject, [self.username], body,
                        wait=self.waittime)

    def _fetch_msg_in_mailbox(self, msg, mailbox, msg_set, msg_parts):
        log.debug('SELECT %s: %s', mailbox, self.imap.select(mailbox))
        log.debug('msg_set: %s, msg_parts: %s', msg_set, msg_parts)
        fetched = self.imap.fetch(msg_set, msg_parts)
        log.debug('Fetched: %s', fetched)
        return fetched

    def grep_msg(self, msg, mailbox='INBOX', msg_set='lastest',
                 msg_parts='(BODY[TEXT])'):
        if msg_set == 'latest':
            msg_set = self.imap.select(mailbox)[1][0]

        if int(msg_set) == 0:
            raise EmptyMailboxError('%s is empty, maybe mail processing takes'
                                    ' too long. Consider raising timeout.' %
                                    mailbox)

        return (msg in
                self._fetch_msg_in_mailbox(msg, mailbox,
                                           msg_set, msg_parts)[1][0][1])

    def test_send_and_receive_GTUBE_spam_in_spam_folder(self):
        # http://en.wikipedia.org/wiki/GTUBE
        body = ('XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-'
                'STANDARD-ANTI-UBE-TEST-EMAIL*C.34X')
        self._send_email_for_test('Testing spam with GTUBE', body)
        found = self.grep_msg(body, 'spam', msg_set='latest')
        return found

    def test_send_and_receive_email_in_inbox_mailbox(self):
        body = 'Test inbox'
        self._send_email_for_test('Testing send email to INBOX', body)
        found = self.grep_msg(body, 'INBOX', msg_set='latest')
        return found

    def test_send_virus_email_and_discarded_by_amavis(self):
        # http://en.wikipedia.org/wiki/EICAR_test_file
        body = (r'X5O!P%@AP[4\PZX54(P^)7CC)7}$'
                r'EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*')
        self._send_email_for_test('Testing send virus email ', body)
        found = self.grep_msg(body, 'INBOX', msg_set='latest')
        # not found the msg means antivirus worked
        return (not found)


class MailFeatureContext(nap.Context):
    def evaluate(self, metric, resource):
        if metric.value == 3:
            state = nap.state.Ok
        elif metric.value == 1 or metric.value == 2:
            state = nap.state.Warn
        else:
            state = nap.state.Critical

        return nap.Result(state, metric=metric)


def check_mail_stack(config):
    return [MailStackHealth(config['imap_server'], config['smtp_server'],
                            config['username'], config['password'],
                            config['smtp_wait'], config['ssl']),
                            MailFeatureContext("working")
                            ]


if __name__ == "__main__":
    nrpe.check(check_mail_stack, {'timeout': 300})
