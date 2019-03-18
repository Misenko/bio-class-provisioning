base:
  '*':
    - nfs-install
    - common-directories
    - access
  'I@bio_type:student or I@bio_type:teacher':
    - appliance-common
    - common-mount
    - ssh
  'I@bio_type:teacher':
    - teacher-directories
    - teacher-mount
    - appliance-teacher
  'I@bio_type:student':
    - appliance-student
  'I@bio_type:nfs':
    - nfs-server
    - share
    - socket-queue
