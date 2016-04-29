# -*- coding: utf-8 -*-
'''
Extract an archive

.. versionadded:: 2014.1.0
'''

import logging
import os
import tarfile
from contextlib import closing

log = logging.getLogger(__name__)

__virtualname__ = 'archive'


def __virtual__():
    '''
    Only load if the npm module is available in __salt__
    '''
    return __virtualname__ \
        if [x for x in __salt__ if x.startswith('archive.')] \
        else False


def compareChecksum(fname, target, checksum):
    if os.path.exists(fname):
        compare_string = '{0}:{1}'.format(target, checksum)
        with salt.utils.fopen(fname, 'r') as f:
            while True:
                current_line = f.readline()
                if not current_line:
                    break
                if current_line.endswith('\n'):
                    current_line = current_line[:-1]
                if compare_string == current_line:
                    return True
    return False


def extracted(name,
              source,
              archive_format,
              tar_options=None,
              source_hash=None,
              source_hash_update=None,
              if_missing=None,
              keep=False):
    '''
    .. versionadded:: 2014.1.0

    State that make sure an archive is extracted in a directory.
    The downloaded archive is erased if successfully extracted.
    The archive is downloaded only if necessary.

    .. note::

        If ``if_missing`` is not defined, this state will check for ``name``
        instead.  If ``name`` exists, it will assume the archive was previously
        extracted successfully and will not extract it again.

    .. code-block:: yaml

        graylog2-server:
          archive.extracted:
            - name: /opt/
            - source: https://github.com/downloads/Graylog2/graylog2-server/graylog2-server-0.9.6p1.tar.lzma
            - source_hash: md5=499ae16dcae71eeb7c3a30c75ea7a1a6
            - tar_options: J
            - archive_format: tar
            - if_missing: /opt/graylog2-server-0.9.6p1/

    .. code-block:: yaml

        graylog2-server:
          archive.extracted:
            - name: /opt/
            - source: https://github.com/downloads/Graylog2/graylog2-server/graylog2-server-0.9.6p1.tar.gz
            - source_hash: md5=499ae16dcae71eeb7c3a30c75ea7a1a6
            - archive_format: tar
            - if_missing: /opt/graylog2-server-0.9.6p1/

    name
        Directory name where to extract the archive

    source
        Archive source, same syntax as file.managed source argument.

    source_hash
        Hash of source file, or file with list of hash-to-file mappings.
        It uses the same syntax as the file.managed source_hash argument.

    archive_format
        tar, zip or rar

    if_missing
        Some archives, such as tar, extract themselves in a subfolder.
        This directive can be used to validate if the archive had been
        previously extracted.

    tar_options
        Required if used with ``archive_format: tar``, otherwise optional.
        It needs to be the tar argument specific to the archive being extracted,
        such as 'J' for LZMA or 'v' to verbosely list files processed.
        Using this option means that the tar executable on the target will
        be used, which is less platform independent.
        Main operators like -x, --extract, --get, -c, etc. and -f/--file are
        **shoult not be used** here.
        If this option is not set, then the Python tarfile module is used.
        The tarfile module supports gzip and bz2 in Python 2.

    keep
        Keep the archive in the minion's cache
    '''
    ret = {'name': name, 'result': None, 'changes': {}, 'comment': ''}
    valid_archives = ('tar', 'rar', 'zip')

    if archive_format not in valid_archives:
        ret['result'] = False
        ret['comment'] = '{0} is not supported, valid formats are: {1}'.format(
            archive_format, ','.join(valid_archives))
        return ret

    if if_missing is None:
        if_missing = name
    if source_hash and source_hash_update:
        hash = source_hash.split("=")
        source_file = '{0}.{1}'.format(os.path.basename(source), hash[0])
        hash_fname = os.path.join(__opts__['cachedir'],
                            'files',
                            __env__,
                            source_file)
        if compareChecksum(hash_fname, name, hash[1]):
            ret['result'] = True
            ret['comment'] = 'Hash {0} has not changed'.format(hash[1])
            return ret
    elif (
        __salt__['file.directory_exists'](if_missing)
        or __salt__['file.file_exists'](if_missing)
    ):
        ret['result'] = True
        ret['comment'] = '{0} already exists'.format(if_missing)
        return ret

    log.debug('Input seem valid so far')
    filename = os.path.join(__opts__['cachedir'],
                            'files',
                            __env__,
                            '{0}.{1}'.format(if_missing.replace('/', '_'),
                                             archive_format))
    if not os.path.exists(filename):
        if __opts__['test']:
            ret['result'] = None
            ret['comment'] = \
                'Archive {0} would have been downloaded in cache'.format(source)
            return ret

        log.debug('Archive file {0} is not in cache, download it'.format(source))
        data = {
            filename: {
                'file': [
                    'managed',
                    {'name': filename},
                    {'source': source},
                    {'source_hash': source_hash},
                    {'makedirs': True},
                    {'saltenv': __env__}
                ]
            }
        }
        file_result = __salt__['state.single']('file.managed',
                                               filename,
                                               source=source,
                                               source_hash=source_hash,
                                               makedirs=True,
                                               saltenv=__env__)
        log.debug('file.managed: {0}'.format(file_result))
        # get value of first key
        try:
            file_result = file_result[file_result.iterkeys().next()]
        except AttributeError:
            pass

        try:
            if not file_result['result']:
                log.debug('failed to download {0}'.format(source))
                return file_result
        except TypeError:
            if not file_result:
                log.debug('failed to download {0}'.format(source))
                return file_result
    else:
        log.debug('Archive file {0} is already in cache'.format(name))

    if __opts__['test']:
        ret['result'] = None
        ret['comment'] = 'Archive {0} would have been extracted in {1}'.format(
            source, name)
        return ret

    __salt__['file.makedirs'](name)

    if archive_format in ('zip', 'rar'):
        log.debug('Extract {0} in {1}'.format(filename, name))
        files = __salt__['archive.un{0}'.format(archive_format)](filename,
                                                                 name)
    else:
        if tar_options is None:
            with closing(tarfile.open(filename, 'r')) as tar:
                files = tar.getnames()
                tar.extractall(name)
        else:
            log.debug('Untar {0} in {1}'.format(filename, name))

            tar_opts = tar_options.split(' ')

            tar_cmd = ['tar']
            tar_shortopts = 'x'
            tar_longopts = []

            for position, opt in enumerate(tar_opts):
                if opt.startswith('-'):
                    tar_longopts.append(opt)
                else:
                    if position > 0:
                        tar_longopts.append(opt)
                    else:
                        append_opt = opt
                        append_opt = append_opt.replace('x', '').replace('f', '')
                        tar_shortopts = tar_shortopts + append_opt

            tar_cmd.append(tar_shortopts)
            tar_cmd.extend(tar_longopts)
            tar_cmd.extend(['-f', filename])

            results = __salt__['cmd.run_all'](tar_cmd, cwd=name, python_shell=False)
            if results['retcode'] != 0:
                ret['result'] = False
                ret['changes'] = results
                return ret
            if 'bsdtar' in __salt__['cmd.run']('tar --version', python_shell=False):
                files = results['stderr']
            else:
                files = results['stdout']
            if not files:
                files = 'no tar output so far'
    if len(files) > 0:
        ret['result'] = True
        ret['changes']['directories_created'] = [name]
        if if_missing != name:
            ret['changes']['directories_created'].append(if_missing)
        ret['changes']['extracted_files'] = files
        ret['comment'] = '{0} extracted in {1}'.format(source, name)
        if not keep:
            os.unlink(filename)
    else:
        __salt__['file.remove'](if_missing)
        ret['result'] = False
        ret['comment'] = 'Can\'t extract content of {0}'.format(source)
    return ret
