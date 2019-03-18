xkimle:
  ssh_auth.present:
    - user: root
    - source: salt://access/xkimle.public
    - enc: ssh-rsa
    - comment: maintenance
