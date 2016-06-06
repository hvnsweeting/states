# Usage of this is governed by a license that can be found in doc/license.rst.

import collections
import pickle
import logging

from salt.modules import pillar

DATA_KEY = 'pillar.get'

logger = logging.getLogger('pillar_common')


def __virtual__():
    # HACK: load the core pillar module with the variables injected by salt
    try:
        # the commented one seem unnecessary
        #pillar.__salt__ = __salt__
        pillar.__pillar__ = __pillar__
        pillar.__opts__ = __opts__
        pillar.__grains__ = __grains__
        pillar.__context__ = __context__
        logger.debug("Pillar Common Proxy Initialized")
        return 'pillar'
    except NameError:
        logger.info("Pillar Common Proxy can't load at this point, try again"
                    "later", exc_info=True)
        return False


# copy the core pillar context
__proxyenabled__ = pillar.__proxyenabled__
for name in dir(pillar):
    if not name.startswith("_"):
        globals()[name] = getattr(pillar, name)


_cached_calls = None


def reset():
    '''
    Reset pillar usage list.
    '''
    global _cached_calls
    __salt__['data.update'](DATA_KEY, None)
    _cached_calls = None


def get(key, default=KeyError, *args, **kwargs):
    """
    Proxy function for stock :py:func:`salt.modules.pillar.get` which raises a
    ``KeyError`` if a default value is not provided and an non-existent pillar
    is requested.

    It also keeps a record of the requested pillars and the provided default
    values if :ref:`pillar-__test__` is set to ``True``, which is used in
    :mod:`_states.qa`
    """
    DEBUG = pillar.get('__test__', False)

    if DEBUG:
        calls = __salt__['pillar.get_calls']()
        if default not in calls[key]:
            calls[key].append(default)
            __salt__['pillar.get_calls'](value=calls)

    ret = pillar.get(key, default)
    if ret is KeyError:
        raise KeyError("Pillar key does not exist: %s" % key)
    return ret


def get_calls(value=Exception, *args, **kwargs):
    """
    Returns a list of ``pillar.get`` calls made since :func:`clear`
    was last called.

    if `value` is provided, it records a new list (returns the value before
    changing it)

    :param value: If provided, it's saved as the list of calls.
    :type value: defaultdict(list)
    """
    global _cached_calls

    if _cached_calls is None:
        _cached_calls = __salt__['data.getval'](DATA_KEY)
        if _cached_calls is None:
            _cached_calls = collections.defaultdict(list)
        else:
            _cached_calls = pickle.loads(_cached_calls)

    if value != Exception:
        _cached_calls = value
        __salt__['data.update'](DATA_KEY, value=pickle.dumps(value))

    return _cached_calls


def get_call_desc():
    """
    Returns a string with the description of the calls to :func:`pillar.get`.
    """
    return ["{}: {}".format(key, "|".join(map(str, val)))
            for key, val in __salt__['pillar.get_calls']().iteritems()]
