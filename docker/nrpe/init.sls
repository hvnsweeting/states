{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

include:
  - apt.nrpe
  - pip.nrpe

{{ passive_check('docker') }}
