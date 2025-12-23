#!/bin/bash
# Setup script for test server container

set -e

echo "Setting up test server..."

# Update package list
apt-get update

# Install SSH server
apt-get install -y openssh-server sudo python3 python3-pip

# Create deploy user
useradd -m -s /bin/bash -G sudo deploy
echo "deploy:deploy" | chpasswd
echo "deploy ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure SSH
mkdir -p /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chown -R deploy:deploy /home/deploy/.ssh

# Allow SSH login
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Create SSH directory
mkdir -p /run/sshd

# Start SSH service
service ssh start

echo "Test server setup complete!"
echo "You can SSH to this server at localhost:2222"
echo "  ssh -p 2222 deploy@localhost"
echo "  Password: deploy"

# Keep container running
tail -f /dev/null
