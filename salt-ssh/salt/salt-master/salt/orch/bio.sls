nfs_setup:
  salt.state:
    - tgt: 'bio_type:nfs'
    - tgt_type: 'pillar'
    - highstate: True

student_setup:
  salt.state:
    - tgt: 'bio_type:student'
    - tgt_type: 'pillar'
    - highstate: True
    - require:
      - salt: nfs_setup

teacher_setup:
  salt.state:
    - tgt: 'bio_type:teacher'
    - tgt_type: 'pillar'
    - highstate: True
    - require:
      - salt: nfs_setup
