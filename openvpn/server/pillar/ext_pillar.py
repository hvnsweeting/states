#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst

"""
Ext pillar that inject minion OpenVPN keys
"""

import os
import logging

# TODO:
# the whole openvpn_client pillar key is an example
# maybe need a better name
OPENVPN_PILLAR_KEY = "openvpn_client"
OPENVPN_DIR = "/etc/openvpn"
OPENVPN_CLIENT_SUBDIR = "clients"

logger = logging.getLogger("ext_pillar_openvpn")


def _vpn_file(minion_id, openvpn_server, extension):
    return os.path.join(
        OPENVPN_DIR,
        openvpn_server,
        OPENVPN_CLIENT_SUBDIR,
        os.extsep.join((minion_id, extension))
    )


def ext_pillar(minion_id, pillar):
    """
    :param minion_id: name of minion to generate pillars for
    :param pillar: existing already rendered pillars
    """
    # this works only if some pillar key are turned on
    try:
        instances = pillar[OPENVPN_PILLAR_KEY]['instances']
    except KeyError:
        instances = {}

    output = {OPENVPN_PILLAR_KEY: {'instances': {}}}
    for instance in instances:
        openvpn_pillar = {}
        if os.path.exists(_vpn_file(minion_id, instance, 'conf')):
            logger.debug("Found existing client %s for %s", minion_id, instance)
            for extension in ("crt", "key", "conf"):
                with open(_vpn_file(minion_id, instance, extension)) as fh:
                    openvpn_pillar[extension] = fh.read()
            with open(os.path.join(OPENVPN_DIR, instance, "ca.crt")) as fh:
                openvpn_pillar["ca"] = fh.read()
            output[OPENVPN_PILLAR_KEY]['instances'][instance] = openvpn_pillar
        else:
            logger.debug("No client %s for %s, create one", minion_id, instance)
            # here run __salt__["tls.create_ca_signed_cert"] OR
            # os.system() the equivalent of to create the SSL certs
            # raise NotImplementedError("need quanta")
            # if actually __salt__ works, we need to switch from low-level python
            # to salt API in the rest of the code
    return output
