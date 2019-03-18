{% for user, data in pillar.get('user_data', {}).items() %}
/nfs/persistent/{{user}}:
  file.directory:
    - user: bionfs
    - group: bionfs
    - dir_mode: 755
    - file_mode: 644
    - require:
      - file: /nfs/persistent
      - user: nfs-user
{% endfor %}

/etc/exports:
  file.managed:
    - source: salt://share/exports
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: nfs-package
      - user: nfs-user
    - watch_in:
      - service: rpcbind-service
      - service: nfs-service
