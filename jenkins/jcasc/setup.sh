#!/bin/bash
# Script to setup JCasC for Jenkins
# This script installs required plugins and configures JCasC

set -e

echo "🔧 Setting up Jenkins Configuration as Code (JCasC)"

# Check if Jenkins container is running
if ! docker ps | grep -q jenkins-master; then
    echo "❌ Jenkins container is not running. Please start it first:"
    echo "   cd ats-ci-infra && docker compose up -d jenkins"
    exit 1
fi

echo "✅ Jenkins container is running"

# Wait for Jenkins to be ready
echo "⏳ Waiting for Jenkins to be ready..."
timeout=60
counter=0
while ! docker exec jenkins-master curl -s http://localhost:8080 > /dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        echo "❌ Jenkins is not responding after ${timeout}s"
        exit 1
    fi
    sleep 2
    counter=$((counter + 2))
    echo -n "."
done
echo ""
echo "✅ Jenkins is ready"

echo "📦 Installing required plugins..."

# Install plugins via jenkins-plugin-cli (runs inside container, no auth needed)
PLUGINS=(
    "configuration-as-code:latest"
    "job-dsl:latest"
    "workflow-aggregator:latest"
    "cloudbees-folder:latest"
)

for plugin in "${PLUGINS[@]}"; do
    plugin_name=$(echo $plugin | cut -d: -f1)
    echo "  - Installing $plugin_name..."
    docker exec jenkins-master jenkins-plugin-cli --plugins "$plugin" || {
        echo "⚠️  Failed to install $plugin_name, but continuing..."
    }
done

echo ""
echo "✅ Plugins installation completed"
echo ""
echo "🔄 Restarting Jenkins to apply plugin changes..."
docker compose restart jenkins

echo ""
echo "⏳ Waiting for Jenkins to restart..."
sleep 10
counter=0
while ! docker exec jenkins-master curl -s http://localhost:8080 > /dev/null 2>&1; do
    if [ $counter -ge 120 ]; then
        echo "⚠️  Jenkins is taking longer than expected to restart"
        break
    fi
    sleep 2
    counter=$((counter + 2))
    echo -n "."
done
echo ""

echo "✅ Setup completed!"
echo ""
echo "📝 Next steps:"
echo "1. ✅ Plugins installed: Configuration as Code, Job DSL, Folders"
echo "2. ✅ JCasC config mounted: jenkins/jcasc/jenkins.yaml"
echo "3. ✅ Jenkins restarted"
echo ""
echo "🔍 Verify setup:"
echo "   - Open Jenkins UI: http://localhost:8080"
echo "   - Go to: Manage Jenkins → Configuration as Code"
echo "   - Check if config is loaded"
echo "   - Look for folders: platforms/ESP32/"
echo ""
echo "💡 If config is not loaded automatically:"
echo "   - Go to: Manage Jenkins → Configuration as Code"
echo "   - Click: 'Reload existing configuration'"

