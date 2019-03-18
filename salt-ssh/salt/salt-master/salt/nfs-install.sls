nfs-package:
  pkg.installed:
    - pkgs: [ 'nfs-utils' ]

nfs-user:
  group.present:
    - name: bionfs
    - gid: 1000
    - system: False
  user.present:
    - name: bionfs
    - shell: /bin/bash
    - home: /home/bionfs
    - uid: 1000
    - gid: 1000
    - system: false
    - require:
      - group: nfs-user
