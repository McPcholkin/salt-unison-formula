{% from "unison/map.jinja" import map with context %}


unison_add_user:
  user.present:
    - name: {{ map.user.name }}
    - home: {{ map.config.location }}
    - shell: {{ map.user.shell }}
    - empty_password: True
    - system: True
    - fullname: {{ map.user.name }}
    - createhome: False
    {% if map.user.groups_optional %}
    - optional_groups: {{ map.user.groups_optional }}
    {% endif %}

unison_create_config_dir:
  file.directory:
    - name: {{ map.config.location }}
    - user: {{ map.user.name }}
    - group: {{ map.user.group }}
    - mode: 0750
    - makedirs: True
    - require:
      - user: unison_add_user

unison_deploy_key_dir:
  file.directory:
    - name: {{ map.config.location }}/.ssh/
    - user: {{ map.user.name }}
    - group: {{ map.user.group }}
    - mode: 0700
    - makedirs: True
    - require:
      - user: unison_add_user

unison_deploy_key:
  file.managed:
    - name: {{ map.config.location }}/.ssh/key_priv
    - contents_pillar: unison:user:key_priv 
    - user: {{ map.user.name }}
    - group: {{ map.user.group }}
    - mode: 0600
    - require:
      - file: unison_deploy_key_dir

unison_deploy_authorized_keys:
  file.managed:
    - name: {{ map.config.location }}/.ssh/authorized_keys
    - contents_pillar:  unison:user:key_pub
    - user: {{ map.user.name }}
    - group: {{ map.user.group }}
    - mode: 0644
    - require:
      - file: unison_deploy_key_dir


