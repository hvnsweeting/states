# -*- coding: utf-8 -*-
# Usage of this is governed by a license that can be found in doc/license.rst.

import logging
import os
import pickle
import yaml
import StringIO
import collections
from ast import literal_eval

logger = logging.getLogger(__name__)

__virtualname__ = 'qa'


def __virtual__():
    return __virtualname__


def _import_debug():
    logger.debug("packages: %s", __salt__['pkg.list_pkgs']().keys())
    logger.debug("pip list: %s", __salt__['pip.list']())


def _get_doctrees(docs_dir):
    '''
    .. todo:: doc me

    :param docs_dir:
    :return:
    '''
    # TODO: switch to __salt__['file.find']
    pillars = []
    monitors = []
    for d, _, files in os.walk(os.path.join(docs_dir, '.doctrees')):
        for f in files:
            if f == "pillar.doctree":
                pillars.append(os.path.join(d, f))
            if f == "monitor.doctree":
                monitors.append(os.path.join(d, f))

    base_len = len(docs_dir.rstrip(os.sep).split(os.sep)) + 1
    # default value: two-tuple
    doctrees = collections.defaultdict(lambda: [None, None])

    def get_name(filename):
        return '.'.join(filename.split(os.sep)[base_len:-2])

    # load pillar doctrees
    _import_debug()
    for filename in pillars:
        with open(filename) as f:
            if filename.endswith(".doctrees/doc/pillar.doctree"):
                name = 'common'
            else:
                # the name is the path - the doc/pillar.rst bit
                name = get_name(filename)
                assert name, ("Couldn't extract the formula name "
                              "from %s" % filename)
            try:
                doctrees[name][0] = pickle.load(f)
                try:
                    from docutils import nodes
                    logger.debug("Docutils from %s", nodes.__file__)
                except ImportError, err:
                    logger.error("Can't find docutils")
                    pass
            except ImportError, err:
                raise err

    # load monitors doctrees
    for filename in monitors:
        with open(filename) as f:
            name = get_name(filename)
            assert name, "Couldn't extract the formula name from %s" % filename
            doctrees[name][1] = pickle.load(f)

    return doctrees


def _render(data):
    try:
        return literal_eval(data)
    except (SyntaxError, ValueError):
        # this cannot be rendered as a primitive, try with the salt renderer
        # NOTE: because `return` is used above, we can avoid try block nesting
        pass

    try:
        import salt
        return salt.template.compile_template_str(
            data, default=__opts__['renderer'],
            renderers=salt.loader.render(__opts__, __salt__))
    except (NameError, ImportError):
        # this was called from outside of salt or even from a system that
        # doesn't have salt installed. Render as simple yaml instead
        return yaml.load(StringIO.StringIO(data))


def _parse_pillar(document, root_name="pillar"):
    """
    Returns a dictionary with all necessary data a given document. It expects
    the document to have the structure described above
    """
    try:
        from docutils import nodes
        logger.debug("Docutils from %s", nodes.__file__)
    except ImportError, err:
        logger.error("Can't find docutils")
        _import_debug()
        raise err

    ret = {
        '_errors': [],
        'mandatory': {
            '_errors': [],
            'keys': [],
            'examples': [],
        },
        'optional': {},
        'conditional': {},
    }

    # if document is None, return an empty dictionary
    if not document:
        return ret

    # get "pillar" sections
    pillar_sections = filter(lambda x: (x.tagname == 'section' and
                                        root_name in x.attributes['names']),
                             document.children)
    # should be unique
    if len(pillar_sections) != 1:
        ret['_errors'].append(
            SyntaxError("Bad number of Pillar sections: %d" %
                        len(pillar_sections)))
    for p in pillar_sections:
        # find mandatory
        mandatory_sections = filter(lambda x: (
            x.tagname == 'section' and
            'mandatory' in x.attributes['names']), p.children)
        # should be unique
        if len(mandatory_sections) > 1:
            ret['_errors'].append(
                SyntaxError("Bad number of mandatory keys sections: %d" %
                            len(mandatory_sections)))

        for mandatory in mandatory_sections:
            # find example. Examples are literals straight under the
            # "mandatory" section, after a paragraph that starts with
            # "Example:"
            for i, child in enumerate(mandatory.children):
                if child.tagname == 'paragraph':
                    if child.astext().startswith("Example:"):
                        if len(mandatory.children) < i:
                            # it says "Example:" but there's no example literal
                            ret['mandatory']['_errors'].append(
                                SyntaxError("Missing literal example "
                                            "section"))
                        elif (mandatory.children[i+1].tagname !=
                              'literal_block'):
                            # it says "Example:" but there's no example literal
                            ret['mandatory']['_errors'].append(
                                SyntaxError("Missing literal example section"))
                        else:
                            example = mandatory.children[i+1]
                            ret['mandatory']['examples'].append(
                                _render(example.astext()))

                        break
            # I expect the keys to be defined directly as the titles of the
            # second level
            titles = mandatory.traverse(
                lambda x: (isinstance(x, nodes.title) and
                           not x.parent == mandatory),
                include_self=False)
            #: rendered titles
            keys = map(lambda x: x.astext(), titles)
            ret['mandatory']['keys'].extend(keys)

        # find optional
        optional_sections = filter(lambda x: (
            x.tagname == 'section' and
            'optional' in x.attributes['names']), p.children)
        # should be unique
        if len(optional_sections) > 1:
            ret["_errors"].append(
                SyntaxError("Bad number of optional sections: %d" %
                            len(optional_sections)))

        for optional in optional_sections:
            # find optional keys
            keys = filter(lambda x: x.tagname == 'section', optional.children)
            for key in keys:
                data = {
                    '_errors': [],
                }
                default = None

                # I expect the keys to be defined directly as the titles of the
                # second level
                titles = key.traverse(nodes.title, include_self=False)
                #: rendered titles
                ttitles = map(lambda x: x.astext(), titles)
                assert len(ttitles) == 1, ('too many titles for '
                                           'optional section')
                name = ttitles[0]

                default_sections = filter(
                    lambda c: (c.tagname != 'comment' and
                               c.astext().startswith("Default:")),
                    key.children)
                if not default_sections:
                    data['_errors'].append(SyntaxError("No default sections"))
                elif len(default_sections) > 1:
                    data['_errors'].append(
                        SyntaxError("There's more than one default section"))
                else:
                    # I know default_sections is a list of 1
                    child, = default_sections
                    defaults = child.traverse(
                        lambda x: (x.parent == child and
                                   isinstance(x, nodes.literal)),
                        include_self=False)
                    if not defaults:
                        data['_errors'].append(
                            SyntaxError("No default values"))
                    try:
                        default = _render(defaults[0].astext())
                    except Exception, e:
                        default = e

                data['default'] = default

                ret['optional'][name] = data

        # find conditional
        conditional_sections = filter(lambda x: (
            x.tagname == 'section' and
            'conditional' in x.attributes['names']), p.children)
        # should be unique
        if len(conditional_sections) > 1:
            ret["_errors"].append(
                SyntaxError("Bad number of conditional sections: %d" %
                            len(conditional_sections)))

        for conditional in conditional_sections:
            # find conditional keys
            keys = filter(lambda x: x.tagname == 'section',
                          conditional.children)
            for key in keys:
                data = {
                    '_errors': [],
                }

                # I expect the keys to be defined directly as the titles of the
                # second level
                titles = key.traverse(nodes.title, include_self=False)
                #: rendered titles
                ttitles = map(lambda x: x.astext(), titles)
                assert len(ttitles) == 1, ('too many titles for '
                                           'optional section')
                name = ttitles[0]

                default = None
                default_sections = filter(
                    lambda c: (c.tagname != 'comment' and
                               c.astext().startswith("Default:")),
                    key.children)
                if len(default_sections) > 1:
                    data['_errors'].append(
                        SyntaxError("There's more than one default section"))
                elif default_sections:
                    # I know default_sections is a list of 1
                    child, = default_sections
                    defaults = child.traverse(
                        lambda x: (x.parent == child and
                                   isinstance(x, nodes.literal)),
                        include_self=False)
                    if not defaults:
                        data['_errors'].append(
                            SyntaxError("No default values"))
                    elif len(defaults) > 1:
                        data['_errors'].append(
                            SyntaxError("Multiple default values: %s" %
                                        " | ".join(d.astext()
                                                   for d in defaults)))
                    try:
                        default = _render(defaults[0].astext())
                    except Exception, e:
                        default = e

                data['default'] = default

                ret['conditional'][name] = data

    return ret


def _parse_monitor(document):
    from docutils import nodes

    ret = {
        '_errors': [],
        'mandatory': [],
        'optional': [],
    }
    if not document:
        return ret

    # get "monitor" sections
    monitor_sections = filter(lambda x: (x.tagname == 'section' and
                                         'monitor' in x.attributes['names']),
                              document.children)
    # should be unique
    if len(monitor_sections) != 1:
        ret['_errors'].append(
            SyntaxError("Bad number of Monitor sections: %d" %
                        len(monitor_sections)))
    for m in monitor_sections:
        mandatory_sections = filter(
            lambda x: (x.tagname == 'section' and
                       'mandatory' in x.attributes['names']),
            m.children)
        if len(mandatory_sections) > 1:
            ret['_errors'].append(
                SyntaxError("Bad number of mandatory monitor sections: %d" %
                            len(mandatory_sections)))
        for mandatory in mandatory_sections:
            checks = mandatory.traverse(nodes.section, include_self=False)
            # the name is the first title in each section
            titles = [c.traverse(nodes.title, include_self=False)[0].astext()
                      for c in checks]
            ret['mandatory'].extend(titles)

        optional_sections = filter(lambda x: (
            x.tagname == 'section' and
            'optional' in x.attributes['names']), m.children)
        if len(optional_sections) > 1:
            ret['_errors'].append(
                SyntaxError("Bad number of optional monitor sections: %d" %
                            len(optional_sections)))

        for optional in optional_sections:
            checks = optional.traverse(nodes.section, include_self=False)
            # the name is the first title in each section
            titles = [c.traverse(nodes.title, include_self=False)[0].astext()
                      for c in checks]
            ret['optional'].extend(titles)

    return ret


def _example_pillars(parsed_doctree):
    """
    Returns a list of pillar dictionaries as they have been documented in
    doc/pillar.rst

    :param parsed_doctree: the return value of :func:`parse_doctrees`
    """
    ret = []
    for fdata in parsed_doctree.itervalues():
        # this supports each mandatory section having more than one example
        # although it is reported as an error elsewhere
        ret.extend(fdata['mandatory']['examples'])
    return ret


def parse_doctrees(docs_dir):
    '''
    Parse sphinx doctrees

    :param docs_dir: TODO FIX ME
    :return: a dictionary
             like::

                 {
                     formula: {
                         <structure documented in _parse_pillar()>
                         '_monitor': _parse_monitor()
                     }
                 }
    '''
    ret = {}
    doctrees = _get_doctrees(docs_dir)
    for name, (pillar, monitor) in doctrees.iteritems():
        try:
            if name != 'common':
                ret[name] = _parse_pillar(pillar)
            else:
                ret[name] = _parse_pillar(pillar, root_name='global pillar')
        except Exception, e:
            ret[name] = {'_errors': [e]}
        try:
            # HACK, TODO:
            # it should really be ret = { 'pillar': parse_pillar,
            #                             'monitor': parse_monitor}
            #   but that means changes in several places now.
            ret[name]['_monitor'] = _parse_monitor(monitor)
        except Exception, e:
            ret[name]['_monitor'] = {'_errors': [e], 'checks': []}
    return ret
