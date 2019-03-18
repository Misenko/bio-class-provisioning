docker-dependencies:
  pkg.installed:
    - pkgs:
      - yum-utils
      - device-mapper-persistent-data
      - lvm2

docker-repo:
  pkgrepo.managed:
    - humanname: Docker CE Stable - $basearch
    - baseurl: https://download.docker.com/linux/centos/7/$basearch/stable
    - name: docker-ce-stable
    - gpgcheck: 1
    - gpgkey: https://download.docker.com/linux/centos/gpg

docker-package:
  pkg.installed:
    - ignore_epoch: True
    - pkgs:
      - docker-ce: '${DOCKER_VERSION}'
      - python-docker-py
    - require:
      - pkg: docker-dependencies
      - pkgrepo: docker-repo

docker-configuration:
  file.managed:
    - name: /etc/docker/daemon.json
    - source: salt://appliance/daemon.json
    - makedirs: True
    - require:
      - pkg: docker-package

docker-service:
  service.running:
    - name: docker
    - enable: True
    - watch:
      - file: docker-configuration
    - require:
      - pkg: docker-package
      - file: docker-configuration

ssh-access:
  file.copy:
    - name: /nfs/persistent/.ssh/authorized_keys
    - source: /root/.ssh/authorized_keys
    - makedirs: True
    - force: true
    - user: bionfs
    - group: bionfs
    - require:
      - mount: persistent

pass-file:
  file.managed:
    - name: /nfs/persistent/rstudio-pass
    - source: salt://appliance/rstudio-pass
    - user: bionfs
    - group: bionfs
    - mode: 644
    - template: jinja
    - allow_empty: false
    - require:
      - mount: persistent
