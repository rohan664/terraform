#!/bin/bash

set -Eeuo pipefail
sudo apt update -y
sudo apt install docker.io -y
sudo usermod -a -G docker ${instance_user}
sudo systemctl enable docker
sudo systemctl start docker
sudo apt install -y openjdk-17-jdk
sudo apt install unzip -y
if ! command -v aws &> /dev/null; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install -y
else 
  echo "AWS CLI is already installed"
fi
sudo curl --fail --silent --show-error --location \
  "https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)" \
  --output /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
sudo chown root:docker /usr/bin/docker-compose

echo -n ${docker_compose} | base64 -d -w 0 | tee /home/${instance_user}/docker-compose.yml
chown ${instance_user}:${instance_user} /home/${instance_user}/docker-compose.yml

echo -n ${casc} | base64 -d -w 0 | tee /home/${instance_user}/casc.yaml
chown ${instance_user}:${instance_user} /home/${instance_user}/casc.yaml
chmod 644 /home/${instance_user}/casc.yaml

echo -n ${casc_secrets} | base64 -d -w 0 | tee /home/${instance_user}/casc-secrets.yaml
chown ${instance_user}:${instance_user} /home/${instance_user}/casc-secrets.yaml
chmod 644 /home/${instance_user}/casc-secrets.yaml

#!/bin/bash

# assume casc_secrets is a base64 encoded YAML string
echo -n "${casc_secrets}" | base64 -d -w 0 > /home/${instance_user}/casc-secrets.yaml
chown ${instance_user}:${instance_user} /home/${instance_user}/casc-secrets.yaml
chmod 644 /home/${instance_user}/casc-secrets.yaml

echo -n ${startup_script} | base64 -d -w 0 | tee /home/${instance_user}/jenkins.sh
chmod +x /home/${instance_user}/jenkins.sh
chown ${instance_user}:${instance_user} /home/${instance_user}/jenkins.sh

echo -n ${jenkins_service} | base64 -d -w 0 | sudo tee /etc/systemd/system/jenkins.service
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

sudo chmod 666 /var/run/docker.sock

echo -n ${cleanup_script} | base64 -d -w 0 | tee /home/${instance_user}/cleanup.sh
sudo chmod +x "/home/${instance_user}/cleanup.sh"

(sudo crontab -l; echo "${cleanup_schedule} /home/${instance_user}/cleanup.sh") | sudo crontab -

