users:
  mount.mounted:
    - name: /nfs/users
    - device: {{ pillar.get('nfs_ip', '') }}:/nfs/persistent
    - fstype: nfs
    - persist: false
    - require:
      - file: /nfs/users
