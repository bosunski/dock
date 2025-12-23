#!/bin/bash
# Script to test Ansible playbooks locally

set -e

echo "🧪 Starting local test environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start test server
echo "🚀 Starting test server container..."
docker-compose -f docker-compose.test.yml up -d

# Wait for SSH to be ready
echo "⏳ Waiting for SSH server to be ready..."
sleep 10

# Remove old host key if exists
ssh-keygen -R "[localhost]:2222" 2>/dev/null || true

max_attempts=60  # Increase to 60 attempts (2 minutes)
attempt=0
while true; do
    attempt=$((attempt + 1))
    if [ $attempt -gt $max_attempts ]; then
        echo "❌ SSH server did not start in time"
        docker-compose -f docker-compose.test.yml logs
        exit 1
    fi
    
    # Test actual SSH connection, not just port availability
    if ssh -i ~/.ssh/dock_test_rsa -p 2222 -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o ConnectTimeout=5 deploy@localhost exit 2>/dev/null; then
        break
    fi
    
    # If key auth fails, try password (first time)
    if [ $attempt -eq 5 ]; then
        echo "   Setting up SSH key authentication..."
        # Use expect or manual SSH key copy since sshpass might not be available
        if command -v sshpass &> /dev/null; then
            sshpass -p "deploy" ssh-copy-id -i ~/.ssh/dock_test_rsa.pub -p 2222 -o StrictHostKeyChecking=no deploy@localhost 2>/dev/null || true
        else
            # Manual method without sshpass
            cat ~/.ssh/dock_test_rsa.pub | docker exec -i dock-test-server bash -c "mkdir -p /home/deploy/.ssh && cat >> /home/deploy/.ssh/authorized_keys && chmod 700 /home/deploy/.ssh && chmod 600 /home/deploy/.ssh/authorized_keys && chown -R deploy:deploy /home/deploy/.ssh"
        fi
    fi
    
    echo "   Attempt $attempt/$max_attempts..."
    sleep 2
done

echo "✅ Test server is ready!"

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/dock_test_rsa ]; then
    echo "🔑 Generating SSH key for testing..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/dock_test_rsa -N "" -C "dock-test"
fi

# Run Ansible playbook
echo "🎭 Running Ansible playbook..."
cd infra
ansible-playbook -i inventory/hosts.yml playbook.yml --limit local -v

echo ""
echo "✨ Ansible playbook completed successfully!"

# Use the generated SSH key
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i inventory/hosts.yml playbook.yml --limit local \
  --private-key ~/.ssh/dock_test_rsa \
 
echo "📊 Test server status:"
docker ps --filter name=dock-test-server --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "🔧 Useful commands:"
echo "  SSH to test server:    ssh -i ~/.ssh/dock_test_rsa -p 2222 deploy@localhost"
echo "  View logs:             docker-compose -f docker-compose.test.yml logs -f"
echo "  Stop test server:      docker-compose -f docker-compose.test.yml down"
echo "  Clean up everything:   docker-compose -f docker-compose.test.yml down -v"
