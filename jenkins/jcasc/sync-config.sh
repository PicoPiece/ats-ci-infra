#!/bin/bash
# Sync jenkins.yaml to container and reload JCasC config
# Usage: ./sync-config.sh [--reload]

set -e

JENKINS_CONTAINER="${JENKINS_CONTAINER:-jenkins-master}"
CONFIG_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${CONFIG_DIR}/jenkins.yaml"
CONTAINER_CONFIG="/var/jenkins_home/casc/jenkins.yaml"

echo "🔄 Syncing Jenkins JCasC configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if Jenkins container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${JENKINS_CONTAINER}$"; then
    echo "❌ Error: Jenkins container '${JENKINS_CONTAINER}' is not running"
    echo "   Start it first: docker compose up -d jenkins"
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: Config file not found: ${CONFIG_FILE}"
    exit 1
fi

# Copy config file to container
echo "📋 Copying jenkins.yaml to container..."
docker cp "$CONFIG_FILE" "${JENKINS_CONTAINER}:${CONTAINER_CONFIG}"

# Verify copy
if docker exec "${JENKINS_CONTAINER}" test -f "${CONTAINER_CONFIG}"; then
    echo "✅ Config file copied successfully"
else
    echo "❌ Error: Failed to copy config file"
    exit 1
fi

# Reload JCasC if requested
if [ "$1" = "--reload" ]; then
    echo ""
    echo "🔄 Reloading JCasC configuration..."
    echo "   Go to Jenkins UI → Manage Jenkins → Configuration as Code"
    echo "   Click 'Reload existing configuration'"
    echo ""
    echo "   Or restart Jenkins: docker compose restart jenkins"
elif [ "$1" = "--restart" ]; then
    echo ""
    echo "🔄 Restarting Jenkins to reload config..."
    cd "$(dirname "$CONFIG_DIR")/.."
    docker compose restart jenkins
    echo "✅ Jenkins restarted. Wait ~30 seconds for it to start."
else
    echo ""
    echo "📝 Next steps:"
    echo "   1. Reload JCasC: Jenkins UI → Manage Jenkins → Configuration as Code → Reload"
    echo "   2. Or restart Jenkins: docker compose restart jenkins"
    echo ""
    echo "💡 Tip: Use --reload flag to get reload instructions"
    echo "   Or use --restart flag to automatically restart Jenkins"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Sync completed"

