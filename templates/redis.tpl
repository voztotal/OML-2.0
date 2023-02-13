#!/bin/bash

apt update && apt install -y podman

cat >> /etc/systemd/system/redis.service <<EOF
[Unit]
Description=Podman container-oml-redis-server.service
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run \
  --cidfile=%t/%n.ctr-id \
  --cgroups=no-conmon \
  --sdnotify=conmon \
  --replace \
  --detach \
  --network=host \
  --name=oml-redis-server \
  --volume=oml_redis:/data \
  --rm  \
  docker.io/redislabs/redisgears:1.0.9
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=default.target

EOF

systemctl enable redis
systemctl start redis