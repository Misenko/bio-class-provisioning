/nfs/users:
  file.directory:
    - user: bionfs
    - group: bionfs
    - dir_mode: 755
    - file_mode: 644
    - require:
      - file: /nfs
