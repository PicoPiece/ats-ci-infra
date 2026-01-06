#!/usr/bin/env bash
# Interactive Setup Guide for Raspberry Pi Jenkins Agent
# This script guides you through the setup process

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Raspberry Pi Jenkins Agent Setup Guide"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if running on Raspberry Pi
if [ -f /proc/device-tree/model ] && grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
    echo "✅ Detected Raspberry Pi"
else
    echo "⚠️  Warning: This doesn't appear to be a Raspberry Pi"
    echo "   Continue anyway? (y/n)"
    read -r response
    if [ "$response" != "y" ]; then
        exit 0
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Prerequisites Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check Docker
if command -v docker > /dev/null 2>&1; then
    echo "✅ Docker is installed"
    if docker info > /dev/null 2>&1; then
        echo "✅ Docker is running"
    else
        echo "❌ Docker is not running"
        echo "   Start Docker with: sudo systemctl start docker"
        exit 1
    fi
else
    echo "❌ Docker is not installed"
    echo ""
    echo "Install Docker with:"
    echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "  sudo sh get-docker.sh"
    echo "  sudo usermod -aG docker \$USER"
    echo "  # Then logout and login again"
    exit 1
fi

# Check if user is in docker group
if groups | grep -q docker; then
    echo "✅ User is in docker group"
else
    echo "⚠️  Warning: User is not in docker group"
    echo "   Add user to docker group: sudo usermod -aG docker \$USER"
    echo "   Then logout and login again"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Setup Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Before running the agent, you need to:"
echo ""
echo "1️⃣  Create Jenkins Agent Node on Jenkins Master:"
echo "   - Go to Jenkins UI → Manage Jenkins → Manage Nodes and Clouds"
echo "   - Click 'New Node'"
echo "   - Node name: (e.g., raspi-ats-01)"
echo "   - Type: Permanent Agent"
echo "   - Remote root directory: ${HOME}/agent (or /home/pi/agent if using pi user)"
echo "   - Labels: raspi-ats (IMPORTANT!)"
echo "   - Usage: Only build jobs with label expressions matching this node"
echo "   - Launch method: Launch agent by connecting it to the master"
echo ""
echo "2️⃣  Get Agent Secret:"
echo "   - Go to the node you just created"
echo "   - Copy the secret from the connection command"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask if user wants to continue
echo "Have you completed steps 1 and 2? (y/n)"
read -r response
if [ "$response" != "y" ]; then
    echo ""
    echo "Please complete the steps above first, then run this script again."
    exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Agent Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get Jenkins URL
echo "Enter Jenkins URL (e.g., https://jenkins.example.com):"
read -r JENKINS_URL

if [ -z "$JENKINS_URL" ]; then
    echo "❌ Error: Jenkins URL is required"
    exit 1
fi

# Get Agent Name
echo "Enter Agent Name (e.g., raspi-ats-01):"
read -r AGENT_NAME

if [ -z "$AGENT_NAME" ]; then
    AGENT_NAME="raspi-ats-01"
    echo "Using default: $AGENT_NAME"
fi

# Get Agent Secret
echo "Enter Agent Secret:"
read -r AGENT_SECRET

if [ -z "$AGENT_SECRET" ]; then
    echo "❌ Error: Agent Secret is required"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting Jenkins Agent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_AGENT_SCRIPT="${SCRIPT_DIR}/start-agent.sh"

if [ ! -f "$START_AGENT_SCRIPT" ]; then
    echo "❌ Error: start-agent.sh not found at $START_AGENT_SCRIPT"
    exit 1
fi

# Run start-agent.sh
"$START_AGENT_SCRIPT" "$JENKINS_URL" "$AGENT_NAME" "$AGENT_SECRET"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Check Jenkins UI to verify agent is connected (green status)"
echo "2. View agent logs: docker logs -f jenkins-agent-${AGENT_NAME}"
echo "3. Test with a pipeline that uses label 'raspi-ats'"
echo ""
echo "For more information, see: README.md"

