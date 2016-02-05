# -*- coding: utf-8 -*-

# Usage of this is governed by a license that can be found in doc/license.rst.

"""
Get some grains information that is only available in DigitalOcean
"""

__author__ = 'Quan Tong Anh'
__maintainer__ = 'Quan Tong Anh'
__email__ = 'quanta@robotinfra.com'

import json
import logging
import httplib
import socket
import datetime

# Set up logging
log = logging.getLogger(__name__)


def _retrieve_metadata(url):
    """
    Sending an HTTP GET request to the local address 169.254.169.254
    """

    conn = httplib.HTTPConnection("169.254.169.254", 80, timeout=1)
    conn.request('GET', url)
    response = conn.getresponse()
    if response.status != 200:
        return "{}"

    data = response.read()
    return data


def get_host_info():
    """
    Will return grain information about this host that is DigitalOcean specific

    "droplet_id": "9410285",
    "hostname": "test-all-comps",
    "region": "sgp1",
    """

    grains = {'digitalocean': False}
    try:
        json_data = _retrieve_metadata("/metadata/v1.json")
        data = json.loads(json_data)
        if data.get('droplet_id', False):
            grains['digitalocean'] = data
    except (socket.timeout, socket.error) as serr:
        log.info("Metadata service error or "
                 "this is not running in DigitalOcean: {}".format(serr))

    return grains


if __name__ == "__main__":
    print get_host_info()
