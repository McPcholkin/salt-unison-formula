# Minimal client example

unison:
  config:
    email_to: 'unison_admin@gmail.com'
    email_app: 'msmtp'
  msmtp:
    user: 'unison_server@gmail.com'
    password: 'PASSWORD'
  profiles:
    sync:
      delete: False
      config:
        root_local: '/cygdrive/d/unison/sync'
        root_remote: '/srv/unison/sync'
        hostname: unison_server.example.com
        port: 9999

  user:
    # ssh-keygen -t rsa -f unison_rsa
    key_priv: |
      -----BEGIN RSA PRIVATE KEY-----
      *******************************
      -----END RSA PRIVATE KEY-----
    key_pub: |
      ssh-rsa SH9s6 ********** oQ== debian-unison@server

############################################################

# Minimal server config:
unison:
  user:
    key_priv: |
      -----BEGIN RSA PRIVATE KEY-----
      *******************************
      -----END RSA PRIVATE KEY-----
    key_pub: |
      ssh-rsa SH9s6 ********** oQ== debian-unison@server

###########################################################

# More client config options
unison:
  config:
    email_to: 'unison_admin@gmail.com'
    email_app: 'msmtp'
  msmtp:
    user: 'unison_server@gmail.com'
    password: 'PASSWORD'
  profiles:
    sync:
      delete: False
      config:
        root_local: '/cygdrive/d/unison/sync'
        root_remote: '/srv/unison/sync'
        hostname: unison_server.example.com
        port: 9999

    test1:
      config:
        root_local: '/etc/unison/test1'
        root_remote: '/etc/unison/test1'
        hostname: 192.168.1.111
        user: some_user
        group: some_user
        mode: 777
      backup:
        backupcurr: 'Name *'
        backuplocation: 'local'
        maxbackups: 1
        backupprefix: '.backup/bak.$VERSION.'
      merge:
        py: 'diff3 -m CURRENT1 CURRENTARCH CURRENT2 > NEW'
      ignore:
        - '*.some_odd_file_test2'
        - '*.md'
        - '*.py'
        - '*.some_odd_file'

    test1_Sync2:
      delete: False
      config:
        root_local: '/srv/test1_sync2'
        root_remote: '/srv/unison/test1_sync2'
        hostname: 192.168.1.222
      cron:
        minute: '*/30'
        hour: '*'
    

  user:
    groups_optional:
      - 'some_user'
      - 'dialout'
    key_priv: |
      -----BEGIN RSA PRIVATE KEY-----
      *******************************
      -----END RSA PRIVATE KEY-----
    key_pub: |
      ssh-rsa SH9s6 ********** oQ== debian-unison@server
