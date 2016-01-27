# -*- coding: utf-8 -*-
# Use of this is governed by a license that can be found in doc/license.rst.

'''
Module for interactive with Jenkins API

:configuration: In order to connect to Jenkins, certain configuration is
required in /etc/salt/minion on the relevant minions. Some sample configs might
look like::

  jenkins.base_url: https://jenkins.com
  jenkins.username: meow
  jenkins.token: some_token_get_from_meow_user
'''

__author__ = 'Viet Hung Nguyen <hvn@robotinfra.com>'
__maintainer__ = 'Viet Hung Nguyen <hvn@robotinfra.com>'
__email__ = 'hvn@robotinfra.com'

import logging
import requests

logger = logging.getLogger(__name__)


def latest_build(jobname):
    '''
    Access API of given jobname at jenkins_addr
    and find out latest successful build number.
    '''
    auth = (__salt__['config.option']('jenkins.username'),
            __salt__['config.option']('jenkins.token'))
    base_url = __salt__['config.option']('jenkins.base_url').rstrip('/')
    if not base_url:
        logger.error("Configuration: `jenkins.base_url` "
                     "is required for jenkins module")
        return
    request_url = '{0}/job/{1}/api/json'.format(base_url, jobname)
    logger.info("Connecting to %s", request_url)
    build_number = None
    try:
        r = requests.get(request_url, auth=auth)
        build_number = r.json()['lastStableBuild'].get('number', None)
    except Exception as e:
        logger.error(e, exc_info=True)
    return build_number
