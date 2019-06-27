{% from "unison/map.jinja" import map with context %}

# WARNING! Данный стейт густо усеян костылями и велосипедами.

unison_set_config_dir_owner:
  file.directory:
    - name: {{ map.config.location }}\{{ map.user.name }}
    - user: {{ map.user.name }}

unison_deploy_config_dir:
  file.directory:
    - name: {{ map.config.location }}\{{ map.user.name }}\.unison
    - user: {{ map.user.name }}
    - require:
      - file: unison_set_config_dir_owner

# if key_priv file not exist
{% set key_file_exist = salt['file.file_exists']('C:\\cygwin64\\home\\'~map.user.name~'\\.unison\\key_priv') %}

{% if not key_file_exist %} 
unison_prepare_key_file_p1:
  cmd.run:
    - name: "C:\\cygwin64\\bin\\touch.exe /home/{{ map.user.name }}/.unison/key_priv"
    - reguire:
      - file: unison_deploy_config_dir

unison_prepare_key_file_p2:
  cmd.run:
    - name: "C:\\cygwin64\\bin\\chmod.exe {{ map.user.key_mode }} /home/{{ map.user.name }}/.unison/key_priv"
    - reguire:
      - file: unison_deploy_config_dir
      - cmd: unison_prepare_key_file_p1
{% endif %}

unison_deploy_key:
  file.managed:
    - name: {{ map.config.location }}\{{ map.user.name }}\.unison\key_priv
    - contents_pillar: unison:user:key_priv 
    - user: {{ map.user.name }}
    - win_inheritance: False
    - win_perms_reset: False
    - require:
      - file: unison_deploy_config_dir
{% if not key_file_exist %} 
      - cmd: unison_prepare_key_file_p1
      - cmd: unison_prepare_key_file_p2
{% endif %}


unison_deploy_default_ignore:
  file.managed:
    - name: {{ map.config.location }}\{{ map.user.name }}\.unison\_ignore.prf
    - source: salt://{{ slspath }}/files/ignore.prf.jinja
    - template: jinja
    - user: {{ map.user.name }}
    - makedirs: True
    - defaults:
      ignore: {{ map.ignore }}
    - reguire:
      - file: unison_deploy_config_dir

unison_deploy_default_merge:
  file.managed:
    - name: {{ map.config.location }}\{{ map.user.name }}\.unison\_merge.prf
    - source: salt://{{ slspath }}/files/merge.prf.jinja
    - template: jinja
    - user: {{ map.user.name }}
    - makedirs: True
    - defaults:
      merge: {{ map.merge }}
    - reguire:
      - pkg: unison_deploy_config_dir

unison_deploy_default_backup:
  file.managed:
    - name: {{ map.config.location }}\{{ map.user.name }}\.unison\_backup.prf
    - source: salt://{{ slspath }}/files/backup.prf.jinja
    - template: jinja
    - user: {{ map.user.name }}
    - makedirs: True
    - defaults:
      backup_conf: {{ map.backup }}
    - reguire:
      - file: unison_deploy_config_dir

unison_deploy_log_dir:
  file.directory:
    - name: "c:\\cygwin64\\var\\log\\unison"
    - makedirs: True
    - user: {{ map.user.name }}
    - reguire:
      - file: unison_set_config_dir_owner

unison_deploy_runner_script:
    file.managed:
      - name: {{ map.config.location }}\{{ map.user.name }}\.unison\unison_run.sh
      - source: salt://{{ slspath }}/files/unison_run.sh.jinja
      - template: jinja
      - user: {{ map.user.name }}
      - defaults:
        email_app: {{ map.config.email_app }}
        email_to: {{ map.config.email_to }}
        log_path: {{ map.log.location }}
        debug_lvl: {{ map.config.runer_debug }}
      - reguire:
        - file: unison_deploy_config_dir

unison_deploy_msmtp_conf:
  file.managed:
    - name: {{ map.config.location }}\{{ map.user.name }}\.msmtprc
    - source: salt://{{ slspath }}/files/msmtprc.jinja
    - template: jinja
    - user: {{ map.user.name }}
    - defaults:
      log_path: {{ map.log.location }}/msmtp.log
      email_user: {{ map.msmtp.user }}
      email_password: {{ map.msmtp.password }}
      email_server: {{ map.msmtp.server }}
      email_port: {{ map.msmtp.port }}
      email_protocol: {{ map.msmtp.protocol }}
    - reguire:
      - file: unison_deploy_config_dir

unison_deploy_diff3_wrapper:
    file.managed:
      - name: {{ map.config.location }}\{{ map.user.name }}\.unison\diff3w.sh
      - source: salt://{{ slspath }}/files/diff3w.sh.jinja
      - template: jinja
      - user: {{ map.user.name }}
      - reguire:
        - file: unison_deploy_config_dir

{% set bash_profile_path = map.config.location~'\\'~map.user.name~'\\.bash_profile' %}
{% if not salt['file.contains'](bash_profile_path, 'set -o igncr') %}

unison_fix_cygwin-bash_cr_error_p1:
  file.line:
    - name: {{ bash_profile_path }}
    - content: 'export SHELLOPTS'
    - location: end
    - mode: insert

unison_fix_cygwin-bash_cr_error_p2:
  file.line:
    - name: {{ bash_profile_path }}
    - content: 'set -o igncr'
    - after: 'export SHELLOPTS'
    - mode: ensure

{% endif %}


# --------------------------
{% set win_task_folder_list = salt['task.list_folders']() %}

{% if 'unison' not in win_task_folder_list %}
# Add task folder
unison_task_folder_create:
  module.run:
    - name: task.create_folder
    - m_name: unison
{% endif %}

# --------------------------

unison_deploy_find_task_script:
  file.managed:
    - name: {{ map.config.location }}\{{ map.user.name }}\.unison\find_task.bat
    - source: salt://{{ slspath }}/files/find_task.bat.jinja
    - template: jinja

unison_deploy_find_task_to_del_script:
  file.managed:
    - name: {{ map.config.location }}\{{ map.user.name }}\.unison\find_task_to_del.bat
    - source: salt://{{ slspath }}/files/find_task_to_del.bat.jinja
    - template: jinja
    - defaults:
      if_exist: True
      if_not_exist: False

{#
# not used if used user SYSTEM
unison_deploy_GetSID_script:
  file.managed:
    - name: {{ map.config.location }}\{{ map.user.name }}\.unison\GetSID.bat
    - source: salt://{{ slspath }}/files/GetSID.bat.jinja
    - template: jinja
#}

# --------------------------

{% if map.profiles is mapping %}
{% for profile in map.profiles %}
{% if salt['pillar.get']('unison:profiles:'~profile~':delete', False) %}

unison_delete_profile-{{ profile }}:
  file.absent:
    - name: {{ map.config.location }}\{{ map.user.name }}\.unison\{{ profile }}.prf

unison_check_task-{{ profile }}_exist:
  cmd.run:
    - name: {{ map.config.location }}\{{ map.user.name }}\.unison\find_task_to_del.bat unison_{{ profile }}
    - stateful: True

unison_delete_task_for_profile-{{ profile }}:
  cmd.run:
    - name: schtasks /delete /f /tn unison\unison_{{ profile }}
    - onchanges:
      - cmd: unison_check_task-{{ profile }}_exist
 
{#
# deprecated
unison_delete_task_xml_file_for_profile_{{ profile }}:
  file.absent:
    - name: {{ map.config.location }}\\{{ map.user.name }}\\.unison\\{{ profile }}.xml
#}

{% else %}


# ----- define values ------
{% set root_local = salt['pillar.get']('unison:profiles:'~profile~':config:root_local', map.config.root_local ) %}
{% set remote_port = salt['pillar.get']('unison:profiles:'~profile~':config:port', map.config.port) %}
{% set remote_host = salt['pillar.get']('unison:profiles:'~profile~':config:hostname', map.config.hostname) %}
{% set remote_path = salt['pillar.get']('unison:profiles:'~profile~':config:root_remote', map.config.root_remote) %}
{% set root_remote = 'ssh://'~map.user.name_win~'@'~remote_host~':'~remote_port~'/'~remote_path %}

{% set config_batch = salt['pillar.get']('unison:profiles:'~profile~':config:batch', map.config.batch) %}
{% set config_silent = salt['pillar.get']('unison:profiles:'~profile~':config:silent', map.config.silent) %}

{% set config_sshargs_custom = salt['pillar.get']('unison:profiles:'~profile~':config:sshargs', map.config.sshargs) %}

{% set config_sshargs = config_sshargs_custom~' -i ~/.unison/key_priv' %}

{% set config_terse = salt['pillar.get']('unison:profiles:'~profile~':config:terse', map.config.terse) %}
{% set config_debug = salt['pillar.get']('unison:profiles:'~profile~':config:debug', map.config.debug) %}

{% set config_logfile = salt['pillar.get']('unison:profiles:'~profile~':config:logfile', map.log.location~'/'~profile~'.log') %}

{% set config_perms = salt['pillar.get']('unison:profiles:'~profile~':config:perms', map.config.perms) %}
{% set config_dontchmod = salt['pillar.get']('unison:profiles:'~profile~':config:dontchmod', map.config.dontchmod) %}

{% set custom_backup = salt['pillar.get']('unison:profiles:'~profile~':backup', False) %}

{% set custom_merge = salt['pillar.get']('unison:profiles:'~profile~':merge', False) %}

{% set custom_ignore = salt['pillar.get']('unison:profiles:'~profile~':ignore', False) %}

# --------------------------

{% if 'cannot' in salt['cmd.run']('C:\\cygwin64\\bin\\ls.exe '~root_local) %}
# if local dir not exist
unison_create_profile-{{ profile }}_directory:
  cmd.run:
    - name: "C:\\cygwin64\\bin\\mkdir.exe -p {{ root_local }}"
    - reguire:
      - file: unison_deploy_config_dir
{% endif %}

unison_deploy_profile-{{ profile }}:
    file.managed:
      - name: {{ map.config.location }}\{{ map.user.name }}\.unison\{{ profile }}.prf
      - source: salt://{{ slspath }}/files/default.prf.jinja
      - template: jinja
      - user: {{ map.user.name }}
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

{#
# deprecated
unison_check_task-{{ profile }}_exist:
  cmd.run:
    - name: {{ map.config.location }}\{{ map.user.name }}\.unison\find_task.bat unison_{{ profile }}
    - stateful: True
#}

{#
# Not used if user = SYSTEM
{% set get_sid_script = map.config.location~'\\'~map.user.name~'\\.unison\\GetSID.bat' %}
{% if salt['file.file_exists'](get_sid_script) %}
{% set user_sid = salt['cmd.run'](get_sid_script~' '~map.user.name, None) %}
{% endif %}
#}

{#
# deprecated
unison_create_task_xml_file_for_profile_{{ profile }}:
  file.managed:
    - name: {{ map.config.location }}\\{{ map.user.name }}\\.unison\\{{ profile }}.xml
    - source: salt://{{ slspath }}/files/win_task.xml.jinja
    - template: jinja
    - defaults:
      hostname: {{ salt['grains.get']("host") | upper }}
      username: {{ map.user.name }}
      #                           2007-01-01T00:00:00
      #start_time: {{ None|strftime("%Y-%m-%dT%H:%M:%S") }}
      userID: {{ user_sid }}
      profile: {{ profile }}
      command: {{ map.config.win_command }}
      arguments: "-l -c \"/home/{{ map.user.name }}/.unison/unison_run.sh {{ profile }}\""
      workdir: {{ map.config.location }}\{{ map.user.name }}
    - required_in:
      - module: unison_create_task_from_file_for_profile_{{ profile }}
#}

{#
# Not working if run minion as user SYSTEM (default)
# deprecated
unison_create_task_from_file_for_profile_{{ profile }}:
  cmd.run:
    - name: 'schtasks /f /create /xml {{ map.config.location }}\{{ map.user.name }}\.unison\{{ profile }}.xml /tn "\unison\unison_{{ profile }}"'
    - onchanges: 
      - cmd: unison_check_task-{{ profile }}_exist
      - file: unison_create_task_xml_file_for_profile_{{ profile }}
#}
 

{% set find_task_path = map.config.location~'\\'~map.user.name~'\\.unison\\find_task.bat unison_'~profile %}

{#
# DEBUG
{% set task_exist = salt['cmd.run'](find_task_path) %}
Debug:
  test.show_notification:
    - name: Echo
    - text: Responce_{{ task_exist }}
#}

{% set find_task_script = map.config.location~'\\'~map.user.name~'\\.unison\\find_task.bat' %}
{% if salt['file.file_exists'](find_task_script) %}

{% if 'False' in  salt['cmd.run'](find_task_path) %}
 
# xml_vars
{% set xml_hostname = salt['grains.get']("host") | upper %}
{% set xml_username = map.user.name %}
{% set xml_profile = profile %}
{% set xml_command = map.config.win_command %}
{% set xml_arguments = '-l -c \"/home/'~map.user.name~'/.unison/unison_run.sh '~profile~'\"' %}
{% set xml_workdir = map.config.location~'\\'~map.user.name %}
# ------------------------------------------------------------

# this solution is ugly, it always return FALSE but it works...
unison_create_task_from_file_for_profile_{{ profile }}_it_always_FALSE:
  module.run:
    - name: task.create_task_from_xml
    - m_name: unison_{{ profile }}
    - location: "\\unison"
    - xml_text: '<?xml version="1.0" encoding="UTF-16"?><Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"><RegistrationInfo><Author>{{ xml_hostname }}\{{ xml_username }}</Author><Description>Unison task for profile - {{ xml_profile }}</Description><URI>\unison\unison_{{ xml_profile }}</URI></RegistrationInfo><Triggers><RegistrationTrigger><Repetition><Interval>PT1H</Interval><StopAtDurationEnd>false</StopAtDurationEnd></Repetition><ExecutionTimeLimit>PT4H</ExecutionTimeLimit><Enabled>true</Enabled><Delay>PT15M</Delay></RegistrationTrigger></Triggers><Principals><Principal id="{{ xml_username }}"><LogonType>S4U</LogonType><DisplayName>{{ xml_username }}</DisplayName><RunLevel>HighestAvailable</RunLevel></Principal></Principals><Settings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries><StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><AllowHardTerminate>true</AllowHardTerminate><StartWhenAvailable>false</StartWhenAvailable><RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable><IdleSettings><StopOnIdleEnd>true</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleSettings><AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled><Hidden>true</Hidden><RunOnlyIfIdle>false</RunOnlyIfIdle><WakeToRun>false</WakeToRun><ExecutionTimeLimit>PT8H</ExecutionTimeLimit><Priority>7</Priority></Settings><Actions Context="{{ xml_username }}"><Exec id="Execute_ID1"><Command>{{ xml_command }}</Command><Arguments>{{ xml_arguments }}</Arguments><WorkingDirectory>{{ xml_workdir }}</WorkingDirectory></Exec></Actions></Task>'
    - reguire:
      - file: unison_deploy_find_task_script

# end create task
{% endif %}
#  end if find_task_script exist 
{% endif %}


{% endif %}

{% endfor %}

{% else %}

# if storage dir not exist
{% if not salt['cmd.run']('C:\\cygwin64\\bin\\ls.exe '~map.config.storage, False) %}
unison_create_profile-{{ profile }}_directory:
  cmd.run:
    - name: "C:\\cygwin64\\bin\\mkdir.exe -p {{ map.config.storage }}"
    - reguire:
      - file: unison_deploy_config_dir
{% endif %}

{% endif %}


