{% from "unison/map.jinja" import map with context %}

install_unison:
  pkg.installed:
    - pkgs: {{ map.pkgs }}
