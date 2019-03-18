clean_dead:
  salt.runner:
    - name: manage.down
    - removekeys: True
