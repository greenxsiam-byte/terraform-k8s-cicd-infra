#!/bin/bash
# Installs Jenkins + Docker + kubectl on Ubuntu 22.04
set -euxo pipefail

# Ubuntu 22.04 ships the SSM agent via snap — make sure it's enabled.
# This is what lets you connect with `aws ssm start-session` instead of SSH.
snap install amazon-ssm-agent --classic || true
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service || true

apt-get update
apt-get install -y openjdk-17-jdk curl gnupg apt-transport-https ca-certificates

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list

apt-get update
apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# Install kubectl so Jenkins can deploy to the k8s cluster
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Let the jenkins user run kubectl / docker commands
usermod -aG sudo jenkins
