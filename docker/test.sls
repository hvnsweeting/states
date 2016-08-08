{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - docker
  - docker.nrpe

test:
  cmd:
    - run
    - name: docker ps
    - require:
      - sls: docker
      - sls: docker.nrpe
  monitoring:
    - run_all_checks
    - order: last
