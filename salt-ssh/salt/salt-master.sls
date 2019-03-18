saltstack:
  pkgrepo.managed:
    - humanname: SaltStack repo for Red Hat Enterprise Linux $releasever
    - baseurl: https://repo.saltstack.com/yum/redhat/$releasever/$basearch/${SALT_REPO_VERSION}
    - gpgcheck: True
    - enabled: True
    - gpgkey: https://repo.saltstack.com/yum/redhat/$releasever/$basearch/${SALT_REPO_VERSION}/SALTSTACK-GPG-KEY.pub https://repo.saltstack.com/yum/redhat/$releasever/$basearch/${SALT_REPO_VERSION}/base/RPM-GPG-KEY-CentOS-7

salt-master:
  pkg.installed:
    - require:
      - pkgrepo: saltstack
  service.running:
    - enable: True
    - require:
      - pkg: salt-master
      - file: /etc/salt/master
      - file: /srv/salt

python2-pip:
  pkg.installed

oca:
  pip.installed:
    - require:
      - pkg: python2-pip

/etc/salt/master:
  file.append:
    - makedirs: True
    - source: salt://salt-master/master

/srv/salt:
  file.recurse:
    - source: salt://salt-master/salt
