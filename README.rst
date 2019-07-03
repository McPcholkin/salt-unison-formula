======================
salt-unison-formula
======================

This state install and configure unison as automatic sync service on linux and windows hosts.   

WARNING!!! state under testing now!!!      

WARNING!!! Windows need cygwin to run unison!!!   

To use this state for windows hosts on host must be installed **cygwin** and packets: *msmtp, unison*   


.. note::
See the full `Salt Formulas installation and usage instructions <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
  :local:

``unison``
------------
Installs the needed packages, apply config, add user, add cron jobs.



