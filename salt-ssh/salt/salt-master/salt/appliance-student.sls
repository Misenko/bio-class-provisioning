docker-appliance:
  docker_container.running:
    - image: {{ pillar.get('bio_image') }}
    - environment:
      - PASSWORD: {{ pillar.get('password') }}
    - binds:
      - /nfs/shared:/data/shared
      - /nfs/persistent:/home/student
    - port_bindings:
      {% if pillar.get('bio_image') == 'misenko/bio-class-gaa' %}
      - 0.0.0.0:22:22
      - 0.0.0.0:80:8787
      {% else %}
      - 0.0.0.0:2222:22
      - 0.0.0.0:8787:8787
      {% endif %}
    - require:
      - service: docker-service
      - file: ssh-access
      - mount: persistent
      - mount: shared
      - docker_image: {{ pillar.get('bio_image') }}
      {% if pillar.get('bio_image') == 'misenko/bio-class-gaa' %}
      - file: /etc/ssh/sshd_config
      {% endif %}

{{ pillar.get('bio_image') }}:
  docker_image.present:
    - force: True
