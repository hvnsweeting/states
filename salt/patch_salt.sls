{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - salt.minion.deps
  - salt.minion.config

patch_salt_fix_require_sls:
  file:
    - managed
    - name: {{ grains['saltpath'] }}/state.py
    - user: root
    - group: root
    - mode: 644
    - source: salt://salt/patch/state.py

patch_salt_utils:
  file:
    - managed
    - name: {{ grains['saltpath'] }}/utils/__init__.py
    - user: root
    - group: root
    - mode: 644
    - source: salt://salt/patch/utils.py

patch_salt_utils_dictupdate:
  file:
    - managed
    - name: {{ grains['saltpath'] }}/utils/dictupdate.py
    - source: salt://salt/patch/dictupdate.py
    - user: root
    - group: root
    - mode: 644

patch_salt_log_setup_fix_deadlock:
  file:
    - managed
    - name: {{ grains['saltpath'] }}/log/setup.py
    - user: root
    - group: root
    - mode: 644
    - source: salt://salt/patch/log_setup.py

patch_salt_fileclient_fix_communication:
  file:
    - managed
    - name: {{ grains['saltpath'] }}/fileclient.py
    - user: root
    - group: root
    - mode: 644
    - source: salt://salt/patch/fileclient.py

patch_salt_sentry_logging_handler:
  file:
    - managed
    - name: {{ grains['saltpath'] }}/log/handlers/sentry_mod.py
    - source: salt://salt/patch/sentry_mod.py
    - user: root
    - group: root
    - mode: 644
