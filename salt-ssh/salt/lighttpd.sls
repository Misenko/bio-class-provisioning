lighttpd:
  pkg.installed: []
  service.running:
    - enable: True
    - require:
      - pkg: lighttpd
      - file: /etc/lighttpd/lighttpd.conf
      - file: /var/www/lighttpd/minion/contextualization.sh

/etc/lighttpd/lighttpd.conf:
  file.append:
    - makedirs: True
    - source: salt://lighttpd/lighttpd.conf

/var/www/lighttpd/minion/contextualization.sh:
  file.managed:
    - makedirs: True
    - source: salt://lighttpd/contextualization.sh
