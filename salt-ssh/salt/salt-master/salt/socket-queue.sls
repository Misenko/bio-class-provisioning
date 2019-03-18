/etc/sysctl.d/10-queue.conf:
  file.managed:
    - source: salt://queue/10-queue.conf
