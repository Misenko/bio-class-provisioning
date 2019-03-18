/etc/sysconfig/nfs:
  file.append:
    - source: salt://nfs/nfs

rpcbind-service:
  service.running:
    - name: rpcbind
    - enable: true
    - require:
      - pkg: nfs-package
    - watch:
      - file: /etc/sysconfig/nfs

nfs-service:
  service.running:
    - name: nfs-server
    - enable: true
    - require:
      - pkg: nfs-package
      - service: rpcbind-service
    - watch:
      - file: /etc/sysconfig/nfs
