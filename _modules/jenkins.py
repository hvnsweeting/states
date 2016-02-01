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

import glob
import logging
import requests

logger = logging.getLogger(__name__)


def _config():
    auth = (__salt__['config.option']('jenkins.username'),
            __salt__['config.option']('jenkins.token'))
    base_url = __salt__['config.option']('jenkins.base_url').rstrip('/')
    return base_url, auth


def latest_stable_build(jobname):
    '''
    Access API of given jobname at jenkins_addr
    and find out latest successful build number.
    '''
    base_url, auth = _config()
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


def download_artifact(filename, jobname, fn_glob, build):
    base_url, auth = _config()
    if build == 'latest':
        build = latest_stable_build(jobname)

    request_url = '{0}/job/{1}/{2}/api/json'.format(base_url, jobname, build)
    try:
        r = requests.get(request_url, auth=auth)
        files = [f['fileName'] for f in r.json()['artifacts']]
        logger.debug("Artifacts of build %d %s: %s", build, jobname, files)
        try:
            artifact_name = glob.fnmatch.filter(files, fn_glob)[0]
        except IndexError:
            raise Exception('No artifact file matched glob "%s"' % fn_glob)
    except Exception as e:
        logger.error(e, exc_info=True)
        raise

    url = '{0}/job/{1}/{2}/artifact/{2}/{3}'.format(base_url, jobname, build,
                                                    artifact_name)
    response = requests.get(url, stream=True, auth=auth)
    with open(filename, 'wb') as fd:
        for chunk in response.iter_content(chunk_size=1024):
            fd.write(chunk)
