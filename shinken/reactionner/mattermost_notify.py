#!/usr/local/shinken/bin/python
# Use of this is governed by a license that can be found in doc/license.rst.

"""
Sent shinken notifications
"""
import logging

import requests

import pysc

logger = logging.getLogger(__name__)

emoticons = {
    'CRITICAL': ':skull:',
    'WARNING': ':warning:',
    'DOWN': ':boom:',
}
HOST_FMT = (
    "Host [{host_alias} "
    "({host_address})]({shinken_url}/host/{host_name}) "
    "is **{host_state}** at {long_date_time}.\nDetail: {host_output}"
)
SERVICE_FMT = ('**{service_desc}** is **{service_state}** at '
               '{long_date_time} on [{host_alias} ({host_address})]'
               '({shinken_url}/service/{host_name}/{service_desc})\n'
               'Additional info: {service_output}\n'
               '*Services*:   `{total_service_ok}` :ok:'
               '  `{total_service_warning}` :warning:'
               '  `{total_service_critical}` :x:'
               '  `{total_service_unknown}` :question:'
               '  `{total_service_problem}` :interrobang:'
               )


class MattermostNotify(pysc.Application):

    def get_argument_parser(self):
        argp = super(MattermostNotify, self).get_argument_parser()
        for arg in ('mode',
                    'service-desc', 'service-state', 'long-date-time',
                    'host-alias', 'host-address',
                    'shinken-url', 'host-name',
                    'host-output', 'host-state',
                    'service-output', 'total-service-ok',
                    'total-service-warning',
                    'total-service-critical', 'total-service-unknown',
                    'total-service-problem'):
            argp.add_argument('--' + arg, default='N/A')
        return argp

    def main(self):
        if self.config['mode'] == 'host':
            message = HOST_FMT.format(**self.config)
            state = self.config['host_state']
        else:
            message = SERVICE_FMT.format(**self.config)
            state = self.config['service_state']
        emo = emoticons.get(state, ':loudspeaker:')
        message = {
            'text': emo + " " + message,
            'icon_url': "{0}/static/img/logo.png".format(
                self.config['shinken_url'])}
        resp = requests.post(self.config['hook_url'], json=message)
        if resp.status_code != 200:
            logger.error("Could not send message to Mattermost server."
                         "HTTP code %d. Msg: %s",
                         resp.status_code,
                         resp.text)

if __name__ == "__main__":
    MattermostNotify().run()
