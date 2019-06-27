
{% set os_family = salt['grains.get']('os_family', None) %}

{% if os_family == 'Windows' %}

include:
  - unison.win

{% else %}

include:
  - unison.install
  - unison.config
  - unison.user

{% endif %}
