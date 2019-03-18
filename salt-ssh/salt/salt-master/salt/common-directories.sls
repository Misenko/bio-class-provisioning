/nfs:
  file.directory:
    - user: bionfs
    - group: bionfs
    - dir_mode: 755
    - file_mode: 644
    - require:
      - user: nfs-user

/nfs/persistent:
  file.directory:
    - user: bionfs
    - group: bionfs
    - dir_mode: 755
    - file_mode: 644
    - require:
      - file: /nfs
      - user: nfs-user

/nfs/shared:
  file.directory:
    - user: bionfs
    - group: bionfs
    - dir_mode: 755
    - file_mode: 644
    - require:
      - file: /nfs
      - user: nfs-user
