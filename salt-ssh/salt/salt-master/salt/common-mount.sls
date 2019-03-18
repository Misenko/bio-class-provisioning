shared:
  mount.mounted:
    - name: /nfs/shared
    - device: {{ pillar.get('nfs_ip', '') }}:/nfs/shared
    - fstype: nfs
    - opts: noatime,nodiratime
    - persist: false
    - require:
      - file: /nfs/shared

persistent:
  mount.mounted:
    - name: /nfs/persistent
    - device: {{ pillar.get('nfs_ip', '') }}:/nfs/persistent/{{ pillar.get('username', '')}}
    - fstype: nfs
    - opts: noatime,nodiratime
    - persist: false
    - require:
      - file: /nfs/persistent
