#!/bin/bash
# Setup SSH keys for Jenkins to access GitHub
# This script helps configure SSH access for Jenkins container

set -e

JENKINS_CONTAINER="${JENKINS_CONTAINER:-jenkins-master}"
JENKINS_HOME="/var/jenkins_home"
SSH_DIR="${JENKINS_HOME}/.ssh"

echo "🔑 Setting up SSH keys for Jenkins GitHub access"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${JENKINS_CONTAINER}$"; then
    echo "❌ Error: Jenkins container '${JENKINS_CONTAINER}' is not running"
    echo "   Start it first: docker compose up -d jenkins"
    exit 1
fi

echo "📋 Options to setup SSH:"
echo ""
echo "Option 1: Copy existing SSH key (Recommended if you have one)"
echo "  - Your SSH key should be at: ~/.ssh/id_rsa or ~/.ssh/id_ed25519"
echo "  - Run:"
echo "    docker cp ~/.ssh/id_rsa ${JENKINS_CONTAINER}:${SSH_DIR}/id_rsa"
echo "    docker cp ~/.ssh/id_rsa.pub ${JENKINS_CONTAINER}:${SSH_DIR}/id_rsa.pub"
echo "    docker exec ${JENKINS_CONTAINER} chown -R jenkins:jenkins ${SSH_DIR}"
echo "    docker exec ${JENKINS_CONTAINER} chmod 600 ${SSH_DIR}/id_rsa"
echo "    docker exec ${JENKINS_CONTAINER} chmod 644 ${SSH_DIR}/id_rsa.pub"
echo ""
echo "Option 2: Generate new SSH key"
echo "  - Run:"
echo "    docker exec -u jenkins ${JENKINS_CONTAINER} mkdir -p ${SSH_DIR}"
echo "    docker exec -u jenkins ${JENKINS_CONTAINER} ssh-keygen -t ed25519 -C 'jenkins@ats-ci' -f ${SSH_DIR}/id_ed25519 -N ''"
echo "  - Then add public key to GitHub:"
echo "    docker exec ${JENKINS_CONTAINER} cat ${SSH_DIR}/id_ed25519.pub"
echo ""
echo "Option 3: Use HTTPS with GitHub token (Alternative)"
echo "  - Change jenkins.yaml to use HTTPS URLs"
echo "  - Add GitHub credentials in Jenkins UI"
echo ""

# Create SSH directory
echo "📁 Creating SSH directory..."
docker exec ${JENKINS_CONTAINER} mkdir -p ${SSH_DIR}
docker exec ${JENKINS_CONTAINER} chown -R jenkins:jenkins ${SSH_DIR}
docker exec ${JENKINS_CONTAINER} chmod 700 ${SSH_DIR}

# Add GitHub to known_hosts
echo "🔐 Adding GitHub to known_hosts..."
docker exec ${JENKINS_CONTAINER} bash -c "ssh-keyscan github.com >> ${SSH_DIR}/known_hosts 2>/dev/null" || true
docker exec ${JENKINS_CONTAINER} chown jenkins:jenkins ${SSH_DIR}/known_hosts
docker exec ${JENKINS_CONTAINER} chmod 644 ${SSH_DIR}/known_hosts

echo ""
echo "✅ SSH directory created: ${SSH_DIR}"
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Copy your SSH key to Jenkins container:"
echo "   docker cp ~/.ssh/id_rsa ${JENKINS_CONTAINER}:${SSH_DIR}/id_rsa"
echo "   docker cp ~/.ssh/id_rsa.pub ${JENKINS_CONTAINER}:${SSH_DIR}/id_rsa.pub"
echo "   docker exec ${JENKINS_CONTAINER} chown -R jenkins:jenkins ${SSH_DIR}"
echo "   docker exec ${JENKINS_CONTAINER} chmod 600 ${SSH_DIR}/id_rsa"
echo ""
echo "2. Or generate new key:"
echo "   docker exec -u jenkins ${JENKINS_CONTAINER} ssh-keygen -t ed25519 -C 'jenkins@ats-ci' -f ${SSH_DIR}/id_ed25519 -N ''"
echo "   docker exec ${JENKINS_CONTAINER} cat ${SSH_DIR}/id_ed25519.pub"
echo "   # Add this public key to GitHub: Settings → SSH and GPG keys → New SSH key"
echo ""
echo "3. Test SSH connection:"
echo "   docker exec -u jenkins ${JENKINS_CONTAINER} ssh -T git@github.com"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup script completed"

