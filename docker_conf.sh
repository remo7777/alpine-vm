#!/bin/ash

# Define the paths to the configuration files
SSH_CONFIG="/etc/ssh/sshd_config"
DOCKER_CONFIG="/etc/docker/daemon.json"

# Update SSH configuration
if [ -f "$SSH_CONFIG" ]; then
    echo "Configuring $SSH_CONFIG..."

    # Ensure PasswordAuthentication is set to 'yes'
    if ! grep -q '^PasswordAuthentication yes' "$SSH_CONFIG"; then
        sed -i -E 's/^#\s*PasswordAuthentication.*/PasswordAuthentication yes/' "$SSH_CONFIG"
        if ! grep -q '^PasswordAuthentication yes' "$SSH_CONFIG"; then
            echo 'PasswordAuthentication yes' >> "$SSH_CONFIG"
        fi
        echo "PasswordAuthentication set to 'yes'."
    fi

    # Ensure PermitRootLogin is set to 'yes'
    if ! grep -q '^PermitRootLogin yes' "$SSH_CONFIG"; then
        sed -i -E 's/^#\s*PermitRootLogin.*/PermitRootLogin yes/' "$SSH_CONFIG"
        if ! grep -q '^PermitRootLogin yes' "$SSH_CONFIG"; then
            echo 'PermitRootLogin yes' >> "$SSH_CONFIG"
        fi
        echo "PermitRootLogin set to 'yes'."
    fi

    # Ensure Port is set to '22'
    if ! grep -q '^Port 22' "$SSH_CONFIG"; then
        sed -i -E 's/^#\s*Port.*/Port 22/' "$SSH_CONFIG"
        if ! grep -q '^Port 22' "$SSH_CONFIG"; then
            echo 'Port 22' >> "$SSH_CONFIG"
        fi
        echo "Port set to '22'."
    fi

    # Restart SSH service to apply changes
    echo "Restarting SSH service..."
    rc-service sshd restart

    echo "SSH configuration updated successfully."
else
    echo "Error: $SSH_CONFIG not found."
    exit 1
fi

# Install Docker
echo "Installing Docker..."
apk add --no-cache docker

# Create Docker configuration directory
mkdir -p /etc/docker

# Create Docker daemon.json
cat <<EOF > "$DOCKER_CONFIG"
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"],
  "iptables": false
}
EOF

# Start Docker service
echo "Starting Docker service..."
rc-update add docker default
rc-service docker start

echo "Docker installed and configured successfully."
