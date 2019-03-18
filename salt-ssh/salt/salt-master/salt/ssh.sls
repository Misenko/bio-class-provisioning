{% if pillar.get('bio_image') == 'misenko/bio-class-gaa' %}
set_selinux_ports:
  cmd.run:
    - name: "semanage port -a -t ssh_port_t -p tcp 2222"
    - unless: "semanage port -l | grep ssh_port_t | grep -q 2222"

/etc/ssh/sshd_config:
  file.line:
    - mode: insert
    - after: "#Port 22"
    - content: Port 2222
    - require:
      - cmd: set_selinux_ports

sshd:
  service.running:
    - enable: true
    - watch:
      - file: /etc/ssh/sshd_config
{% endif %}
