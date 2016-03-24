{#- Usage of this is governed by a license that can be found in doc/license.rst -#}

hostname:
  file:
    - managed
    - template: jinja
    - name: /etc/hostname
    - user: root
    - group: root
    - mode: 644
    - contents: {{ grains['id'] }}
  host: {#- API #}
    - present
    - name: {{ grains['id'] }}
    - ip: 127.0.0.1
    - require:
      - host: localhost
{%- if not grains['virtual_subtype'] == 'Docker' %}
  cmd:
  {%- if grains['id'] != grains['localhost'] %}
    - run
  {%- else %}
    - wait
  {%- endif %}
    - name: hostname `cat /etc/hostname`
    - require_in:
      - host: hostname
    - watch:
      - file: hostname
{%- endif %}

localhost:
  host:
    - present
    - name: localhost
    - ip: 127.0.0.1

{%- for ip, hostnames in salt['pillar.get']('hostname:present', {}).iteritems() %}
  {%- for hostname in hostnames %}
hostname_{{ hostname }}_{{ ip }}:
  host:
    - present
    - name: {{ hostname }}
    - ip: {{ ip }}
    - require_in:
      - host: hostname
  {%- endfor %}
{%- endfor %}

{%- for ip, hostname in salt['pillar.get']('hostname:absent', {}).iteritems() %}
  {%- for hostname in hostnames %}
hostname_{{ hostname }}_{{ ip }}_absent:
  host:
    - absent
    - name: {{ hostname }}
    - ip: {{ ip }}
    - require_in:
      - host: hostname
  {%- endfor %}
{%- endfor %}

{%- set ipv6_hosts = {
    "::1": ["ip6-localhost", "ip6-loopback", ],
    "fe00::0": ["ip6-localnet", ],
    "ff00::0": ["ip6-mcastprefix", ],
    "ff02::1": ["ip6-allnodes", ],
    "ff02::2": ["ip6-allrouters", ],
    "ff02::3": ["ip6-allhosts", ],
}%}
{%- for ip, hosts in ipv6_hosts.iteritems() %}
hostname_ipv6_{{ loop.index }}:
  host:
    - present
    - ip: {{ ip }}
    - names: {{ hosts|yaml }}
    - require_in:
      - host: hostname
{%- endfor %}
