#!/bin/bash
# Script to fix test job Git URL issue
# This script helps update the test job configuration manually

set -e

echo "🔧 Fixing Jenkins Test Job Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

JENKINS_CONTAINER="${JENKINS_CONTAINER:-jenkins-master}"

echo "📋 Options to fix test job:"
echo ""
echo "Option 1: Delete and recreate job (Recommended)"
echo "  - Delete job: Jenkins UI → platforms/ESP32/ats-fw-esp32-demo-ESP32-test → Delete"
echo "  - Restart Jenkins: docker compose restart jenkins"
echo "  - JCasC will recreate job with correct config"
echo ""
echo "Option 2: Manual update in Jenkins UI"
echo "  - Go to: Jenkins UI → platforms/ESP32/ats-fw-esp32-demo-ESP32-test → Configure"
echo "  - Pipeline section → Definition: Pipeline script from SCM"
echo "  - SCM: Git"
echo "  - Repository URL: git@github.com:PicoPiece/ats-fw-esp32-demo.git"
echo "  - Credentials: (leave empty if using SSH)"
echo "  - Branch: */main"
echo "  - Script Path: platforms/ESP32/Jenkinsfile.test"
echo "  - Save"
echo ""
echo "Option 3: Force reload JCasC"
echo "  - Go to: Jenkins UI → Manage Jenkins → Configuration as Code"
echo "  - Click: 'Reload existing configuration'"
echo "  - Or: 'Apply new configuration'"
echo ""

echo "🔍 Checking Jenkins container..."
if docker ps --format '{{.Names}}' | grep -q "^${JENKINS_CONTAINER}$"; then
    echo "✅ Jenkins container is running: ${JENKINS_CONTAINER}"
    echo ""
    echo "📝 To view Jenkins logs:"
    echo "   docker logs ${JENKINS_CONTAINER}"
    echo ""
    echo "🔄 To restart Jenkins:"
    echo "   docker compose restart jenkins"
else
    echo "⚠️  Jenkins container not found: ${JENKINS_CONTAINER}"
    echo "   Make sure Jenkins is running"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Script completed"

