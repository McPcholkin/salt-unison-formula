{% from "unison/map.jinja" import map with context %}

include:
  - unison.install
  - unison.user

# --------------------- default parameters ---------------------
unison_deploy_default_ignore:
  file.managed:
    - name: {{ map.config.location }}/.unison/_ignore.prf
    - source: salt://{{ slspath }}/files/ignore.prf.jinja
    - template: jinja
    - mode: 755
    - user: {{ map.user.name }}
    - group: {{ map.user.group }}
    - makedirs: True
    - defaults:
      ignore: {{ map.ignore }}
    - reguire:
      - file: unison_deploy_key_dir
      - user: unison_add_user

unison_deploy_default_merge:
  file.managed:
    - name: {{ map.config.location }}/.unison/_merge.prf
    - source: salt://{{ slspath }}/files/merge.prf.jinja
    - template: jinja
    - mode: 755
    - user: {{ map.user.name }}
    - group: {{ map.user.group }}
    - makedirs: True
    - defaults:
      merge: {{ map.merge }}
    - reguire:
      - pkg: unison_deploy_key_dir
      - user: unison_add_user

unison_deploy_default_backup:
  file.managed:
    - name: {{ map.config.location }}/.unison/_backup.prf
    - source: salt://{{ slspath }}/files/backup.prf.jinja
    - template: jinja
    - mode: 755
    - user: {{ map.user.name }}
    - group: {{ map.user.group }}
    - makedirs: True
    - defaults:
      backup_conf: {{ map.backup }}
    - reguire:
      - file: unison_deploy_key_dir
      - user: unison_add_user

# --------------------- end default parameters ---------------------

# --------------------- log ---------------------
unison_deploy_log_dir:
  file.directory:
    - name: {{ map.log.location }}
    - makedirs: True
    - mode: 755
    - user: {{ map.user.name }}
    - group: {{ map.user.group }}
    - reguire:
      - user: unison_add_user

unison_deploy_log_rotation_conf:
    file.managed:
      - name: {{ map.log.logrotate_location }}/unison
      - source: salt://{{ slspath }}/files/logrotate.conf.jinja
      - template: jinja
      - mode: 644
      - user: root
      - group: root
      - defaults:
        logpath: {{ map.log.location }}/*.log
        log_conf: {{ map.log.logrotate_config }}
      - reguire:
        - pkg: install_unison
    cmd.run:
      - name: logrotate -d -f {{ map.log.logrotate_location }}/unison
      - reguire:
        - pkg: install_unison
        - file: unison_deploy_log_rotation_conf
      - watch:
        - file: unison_deploy_log_rotation_conf
      - onchanges:
        - file: unison_deploy_log_rotation_conf

# --------------------- end log ---------------------
 
# --------------------- runner script ---------------------
unison_deploy_runner_script:
    file.managed:
      - name: {{ map.config.location }}/unison_run.sh
      - source: salt://{{ slspath }}/files/unison_run.sh.jinja
      - template: jinja
      - mode: 750
      - user: {{ map.user.name }}
      - group: {{ map.user.group }}
      - defaults:
        email_app: {{ map.config.email_app }}
        email_to: {{ map.config.email_to }}
        log_path: {{ map.log.location }}
        debug_lvl: {{ map.config.runer_debug }}
      - reguire:
        - pkg: install_unison

# --------------------- end runner script ---------------------

# --------------------- mail config ---------------------
unison_deploy_msmtp_conf:
  file.managed:
    - name: {{ map.config.location }}/.msmtprc
    - source: salt://{{ slspath }}/files/msmtprc.jinja
    - template: jinja
    - mode: 600
    - user: {{ map.user.name }}
    - group: {{ map.user.group }}
    - defaults:
      log_path: {{ map.log.location }}/msmtp.log
      email_user: {{ map.msmtp.user }}
      email_password: {{ map.msmtp.password }}
      email_server: {{ map.msmtp.server }}
      email_port: {{ map.msmtp.port }}
      email_protocol: {{ map.msmtp.protocol }}
    - reguire:
      - user: unison_add_user
      - pkg: install_unison 

# --------------------- end mail config ---------------------

# --------------------- diff wrapper  ---------------------
unison_deploy_diff3_wrapper:
    file.managed:
      - name: {{ map.config.location }}/diff3w.sh
      - source: salt://{{ slspath }}/files/diff3w.sh.jinja
      - template: jinja
      - mode: 750
      - user: {{ map.user.name }}
      - group: {{ map.user.group }}
      - reguire:
        - pkg: install_unison

# --------------------- end diff wrapper  ---------------------

# --------------------- profiles  ---------------------

# if profiles present start
{% if map.profiles is mapping %}

# for profiles start
{% for profile in map.profiles %}

# if profile need delete start
{% if salt['pillar.get']('unison:profiles:'~profile~':delete', False) %}

# --------------------- delete profiles  ---------------------
 
unison_delete_profile-{{ profile }}:
  file.absent:
    - name: {{ map.config.location }}/.unison/{{ profile }}.prf

unison_delete_task_for_profile-{{ profile }}:
  cron.absent:
    - name: {{ map.config.location }}/unison_run.sh  {{ profile }}
    - user: {{ map.user.name }}

# --------------------- end delete profiles  ---------------------

# if profile not need delete, create profile
{% else %}

# --------------------- create profile ---------------------

unison_create_profile-{{ profile }}_directory:
  file.directory:
    - name: {{ salt['pillar.get']('unison:profiles:'~profile~':config:root_local') }}
    {% if salt['pillar.get']('unison:profiles:'~profile~':config:user') %}
    - user: {{ salt['pillar.get']('unison:profiles:'~profile~':config:user') }}
    {% else %}
    - user: {{ map.user.name }}
    {% endif %}
    {% if salt['pillar.get']('unison:profiles:'~profile~':config:group') %}
    - group: {{ salt['pillar.get']('unison:profiles:'~profile~':config:group') }}
    {% else %}
    - group: {{ map.user.group }}
    {% endif %}
    - makedirs: True
    {% if salt['pillar.get']('unison:profiles:'~profile~':config:mode') %}
    - mode: {{ salt['pillar.get']('unison:profiles:'~profile~':config:mode') }}
    {% else %}
    - mode: 775
    {% endif %}
    - reguire:
      - file: unison_deploy_key_dir
      - user: unison_add_user

# --------------------- define variables for profile file ---------------------

{% set root_local = salt['pillar.get']('unison:profiles:'~profile~':config:root_local', map.config.root_local ) %}
{% set remote_port = salt['pillar.get']('unison:profiles:'~profile~':config:port', map.config.port) %}
{% set remote_host = salt['pillar.get']('unison:profiles:'~profile~':config:hostname', map.config.hostname) %}
{% set remote_path = salt['pillar.get']('unison:profiles:'~profile~':config:root_remote', map.config.root_remote) %}
{% set root_remote = 'ssh://'~map.user.name~'@'~remote_host~':'~remote_port~'/'~remote_path %}

{% set config_batch = salt['pillar.get']('unison:profiles:'~profile~':config:batch', map.config.batch) %}
{% set config_silent = salt['pillar.get']('unison:profiles:'~profile~':config:silent', map.config.silent) %}

{% set config_sshargs_custom = salt['pillar.get']('unison:profiles:'~profile~':config:sshargs', map.config.sshargs) %}

{% set config_sshargs = config_sshargs_custom~' -i '~map.config.location~'/.ssh/key_priv' %}

{% set config_terse = salt['pillar.get']('unison:profiles:'~profile~':config:terse', map.config.terse) %}
{% set config_debug = salt['pillar.get']('unison:profiles:'~profile~':config:debug', map.config.debug) %}

{% set config_logfile = salt['pillar.get']('unison:profiles:'~profile~':config:logfile', map.log.location~'/'~profile~'.log') %}

{% set config_perms = salt['pillar.get']('unison:profiles:'~profile~':config:perms', map.config.perms) %}
{% set config_dontchmod = salt['pillar.get']('unison:profiles:'~profile~':config:dontchmod', map.config.dontchmod) %}

{% set custom_backup = salt['pillar.get']('unison:profiles:'~profile~':backup', False) %}

{% set custom_merge = salt['pillar.get']('unison:profiles:'~profile~':merge', False) %}

{% set custom_ignore = salt['pillar.get']('unison:profiles:'~profile~':ignore', False) %}

# --------------------- end define variables for profile file ---------------------

unison_deploy_profile-{{ profile }}:
    file.managed:
      - name: {{ map.config.location }}/.unison/{{ profile }}.prf
      - source: salt://{{ slspath }}/files/default.prf.jinja
      - template: jinja
      - mode: 755
      - user: {{ map.user.name }}
      - group: {{ map.user.group }}
      - defaults:
        root_local: {{ root_local }}
        root_remote: {{ root_remote }}
        batch: {{ config_batch }}
        silent: {{ config_silent }}
        terse: {{ config_terse }}
        sshargs: {{ config_sshargs }}
        debug: {{ config_debug }}
        logfile: {{ config_logfile }}
        perms: {{ config_perms }}
        dontchmod: {{ config_dontchmod }}
        config_backup: {{ custom_backup }} 
        config_merge: {{ custom_merge }}
        config_ignore: {{ custom_ignore }}
      - reguire:
        - file: unison_deploy_key_dir
        - user: unison_add_user
      - require_in:
        - cron: unison_create_task_for_profile-{{ profile }}

# --------------------- end create profile ---------------------


# --------------------- create profile cron job ---------------------

# --------------------- define variables for profile cron job ---------------------

{% set cron_minute = salt['pillar.get']('unison:profiles:'~profile~':cron:minute', range(1, 59) | random) %}
{% set cron_hour = salt['pillar.get']('unison:profiles:'~profile~':cron:hour', map.cron.hour) %}
{% set cron_daymonth = salt['pillar.get']('unison:profiles:'~profile~':cron:daymonth', map.cron.daymonth) %}
{% set cron_month = salt['pillar.get']('unison:profiles:'~profile~':cron:month', map.cron.month) %}
{% set cron_dayweek = salt['pillar.get']('unison:profiles:'~profile~':cron:dayweek', map.cron.dayweek) %}

# --------------------- end define variables for profile cron job ---------------------

unison_create_task_for_profile-{{ profile }}:
  cron.present:
    - name: {{ map.config.location }}/unison_run.sh {{ profile }}
    - user: {{ map.user.name }}
    - minute: '{{ cron_minute }}'
    - hour: '{{ cron_hour }}'
    - daymonth: '{{ cron_daymonth }}'
    - month: '{{ cron_month }}'
    - dayweek: '{{ cron_dayweek }}'

# --------------------- end create profile cron job ---------------------


# end create profile 
{% endif %}

# for profiles end
{% endfor %}

# if profiles not present, it probably server
{% else %}

# create server storage dir
unison_deploy_server_directory:
  file.directory:
    - name: {{ map.config.storage }}
    - makedirs: True
    - mode: 755
    - user: {{ map.user.name }}
    - group: {{ map.user.group }}
    - reguire:
      - user: unison_add_user

# if profiles present end
{% endif %}

