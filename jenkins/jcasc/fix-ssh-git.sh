#!/bin/bash
# Fix SSH Git access for Jenkins
# This ensures Jenkins can use SSH to clone from GitHub

set -e

JENKINS_CONTAINER="${JENKINS_CONTAINER:-jenkins-master}"
SSH_DIR="/var/jenkins_home/.ssh"

echo "🔧 Fixing SSH Git access for Jenkins"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Jenkins container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${JENKINS_CONTAINER}$"; then
    echo "❌ Error: Jenkins container '${JENKINS_CONTAINER}' is not running"
    exit 1
fi

# Ensure SSH directory exists
echo "📁 Ensuring SSH directory exists..."
docker exec ${JENKINS_CONTAINER} mkdir -p ${SSH_DIR}
docker exec ${JENKINS_CONTAINER} chown -R jenkins:jenkins ${SSH_DIR}
docker exec ${JENKINS_CONTAINER} chmod 700 ${SSH_DIR}

# Copy SSH key if it exists locally
if [ -f ~/.ssh/id_ed25519 ]; then
    echo "📋 Copying SSH key from host..."
    docker cp ~/.ssh/id_ed25519 ${JENKINS_CONTAINER}:${SSH_DIR}/id_ed25519 2>/dev/null || true
    docker cp ~/.ssh/id_ed25519.pub ${JENKINS_CONTAINER}:${SSH_DIR}/id_ed25519.pub 2>/dev/null || true
    docker exec ${JENKINS_CONTAINER} chown jenkins:jenkins ${SSH_DIR}/id_ed25519 ${SSH_DIR}/id_ed25519.pub 2>/dev/null || true
    docker exec ${JENKINS_CONTAINER} chmod 600 ${SSH_DIR}/id_ed25519 2>/dev/null || true
    docker exec ${JENKINS_CONTAINER} chmod 644 ${SSH_DIR}/id_ed25519.pub 2>/dev/null || true
    echo "✅ SSH key copied"
fi

# Update known_hosts
echo "🔐 Updating known_hosts..."
docker exec ${JENKINS_CONTAINER} bash -c "ssh-keyscan github.com >> ${SSH_DIR}/known_hosts 2>/dev/null" || true
docker exec ${JENKINS_CONTAINER} chown jenkins:jenkins ${SSH_DIR}/known_hosts
docker exec ${JENKINS_CONTAINER} chmod 644 ${SSH_DIR}/known_hosts
echo "✅ known_hosts updated"

# Test SSH connection
echo ""
echo "🧪 Testing SSH connection..."
if docker exec -u jenkins ${JENKINS_CONTAINER} ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH connection successful!"
else
    echo "⚠️  SSH test failed, but continuing..."
fi

# Configure Git to use SSH
echo ""
echo "⚙️  Configuring Git for Jenkins user..."
docker exec -u jenkins ${JENKINS_CONTAINER} git config --global --add safe.directory '*' 2>/dev/null || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SSH Git setup completed"
echo ""
echo "📝 Note: If Jenkins still can't clone, you may need to:"
echo "   1. Configure SSH credentials in Jenkins UI"
echo "   2. Or use HTTPS with GitHub token instead"
echo "   3. Or ensure Jenkins Git plugin uses system SSH config"

