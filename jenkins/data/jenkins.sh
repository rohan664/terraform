#!/bin/bash

set -Eeuo pipefail
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${registry_id}.dkr.ecr.${aws_region}.amazonaws.com
export TMPDIR=/var/tmp
docker-compose --file /home/${instance_user}/docker-compose.yml up --force-recreate --detach
