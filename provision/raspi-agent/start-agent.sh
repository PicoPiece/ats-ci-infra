#!/usr/bin/env bash
# Jenkins Agent Startup Script for Raspberry Pi
# Usage: ./start-agent.sh <JENKINS_URL> <AGENT_NAME> <AGENT_SECRET>

set -e

JENKINS_URL="${1:-https://jenkins.example.com}"
AGENT_NAME="${2:-raspi-ats-01}"
AGENT_SECRET="${3:-}"

# Validate required parameters
if [ -z "$AGENT_SECRET" ]; then
  echo "❌ Error: AGENT_SECRET is required"
  echo ""
  echo "Usage: $0 <JENKINS_URL> <AGENT_NAME> <AGENT_SECRET>"
  echo ""
  echo "Example:"
  echo "  $0 https://jenkins.example.com raspi-ats-01 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  echo ""
  echo "To get AGENT_SECRET:"
  echo "  1. Go to Jenkins UI → Manage Jenkins → Manage Nodes and Clouds"
  echo "  2. Click on your node (${AGENT_NAME})"
  echo "  3. Copy the secret from the connection command"
  exit 1
fi

CONTAINER_NAME="jenkins-agent-${AGENT_NAME}"
# Use current user's home directory for workspace, or allow override via JENKINS_WORKSPACE env var
WORKSPACE_DIR="${JENKINS_WORKSPACE:-${HOME}/agent}"

echo "🚀 Starting Jenkins Agent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Jenkins URL: ${JENKINS_URL}"
echo "Agent Name: ${AGENT_NAME}"
echo "Container: ${CONTAINER_NAME}"
echo "Workspace: ${WORKSPACE_DIR}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Error: Docker is not running"
  echo "   Please start Docker: sudo systemctl start docker"
  exit 1
fi

# Stop and remove existing container if exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "🛑 Stopping existing container: ${CONTAINER_NAME}"
  docker stop "${CONTAINER_NAME}" > /dev/null 2>&1 || true
  docker rm "${CONTAINER_NAME}" > /dev/null 2>&1 || true
  echo "✅ Existing container removed"
fi

# Create workspace directory
echo "📁 Creating workspace directory: ${WORKSPACE_DIR}"
mkdir -p "${WORKSPACE_DIR}"
chmod 755 "${WORKSPACE_DIR}"

# Check if jenkins/inbound-agent image exists
if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^jenkins/inbound-agent:latest$"; then
  echo "📦 Pulling jenkins/inbound-agent:latest image..."
  docker pull jenkins/inbound-agent:latest
fi

# Detect Docker binary location
DOCKER_BIN=$(which docker || echo "/usr/bin/docker")
if [ ! -f "$DOCKER_BIN" ]; then
    echo "⚠️  Warning: Docker binary not found at $DOCKER_BIN"
    echo "   Container may not be able to run Docker commands"
fi

# Detect Docker group GID for permission to access docker.sock
DOCKER_GID=$(getent group docker | cut -d: -f3 || echo "")
DOCKER_GROUP_ADD=""
if [ -n "$DOCKER_GID" ]; then
    DOCKER_GROUP_ADD="--group-add ${DOCKER_GID}"
    echo "📦 Docker group GID: ${DOCKER_GID}"
fi

# Run Jenkins agent container
echo "🐳 Starting Jenkins agent container..."
docker run -d --restart unless-stopped \
  --name "${CONTAINER_NAME}" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "${DOCKER_BIN}:/usr/bin/docker:ro" \
  ${DOCKER_GROUP_ADD} \
  -v "${WORKSPACE_DIR}:/home/agent" \
  -v /dev:/dev \
  -v /sys/class/gpio:/sys/class/gpio:ro \
  -v /dev/gpiomem:/dev/gpiomem \
  -e JENKINS_URL="${JENKINS_URL}" \
  -e JENKINS_AGENT_NAME="${AGENT_NAME}" \
  -e JENKINS_SECRET="${AGENT_SECRET}" \
  jenkins/inbound-agent:latest

# Wait a moment for container to start
sleep 2

# Check container status
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo ""
  echo "✅ Jenkins agent started successfully!"
  echo ""
  echo "📋 Container status:"
  docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  echo ""
  echo "📝 View logs:"
  echo "   docker logs -f ${CONTAINER_NAME}"
  echo ""
  echo "🛑 Stop agent:"
  echo "   docker stop ${CONTAINER_NAME}"
  echo ""
  echo "🔄 Restart agent:"
  echo "   docker restart ${CONTAINER_NAME}"
else
  echo ""
  echo "❌ Failed to start Jenkins agent container"
  echo ""
  echo "📝 Check logs:"
  echo "   docker logs ${CONTAINER_NAME}"
  exit 1
fi

