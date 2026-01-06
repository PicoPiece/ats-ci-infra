# Raspberry Pi Jenkins Agent Setup

> **Hướng dẫn setup Jenkins agent trên Raspberry Pi cho ATS node**

Hướng dẫn này giúp bạn setup Jenkins agent trên Raspberry Pi để chạy hardware tests cho ATS platform.

---

## 📋 Prerequisites

Trên Raspberry Pi cần có:

- **Docker** đã cài đặt và chạy
- **Docker Compose** (optional, nếu cần)
- **Network access** đến Jenkins master
- **Hardware access** (USB ports, GPIO) cho ESP32 testing

---

## 🚀 Quick Start

### Bước 1: Tạo Jenkins Agent Node

1. **Đăng nhập vào Jenkins UI** (trên Xeon server)
2. **Vào** `Manage Jenkins` → `Manage Nodes and Clouds`
3. **Click** `New Node`
4. **Điền thông tin:**
   - **Node name**: `raspi-ats-01` (hoặc tên bạn muốn)
   - **Type**: `Permanent Agent`
   - **Click** `OK`

5. **Cấu hình Node:**
   - **Remote root directory**: `/home/jenkins` (phải khớp với directory được mount vào agent container)
   -   **⚠️ QUAN TRỌNG**: Path này phải khớp với mount path trong container!
   -   Jenkins sẽ tạo workspaces dưới path này trên **host filesystem**.
   -   Docker containers có thể mount các host paths này.
   - **Labels**: `raspi-ats` (quan trọng - pipeline sẽ dùng label này)
   - **Usage**: `Only build jobs with label expressions matching this node`
   - **Launch method**: `Launch agent via Java Web Start` hoặc `Launch agent by connecting it to the master`
   - **Save**

### Bước 2: Lấy Agent Secret

1. **Vào node vừa tạo** (`raspi-ats-01`)
2. **Copy secret** từ một trong các nơi:
   - **Jenkins URL**: `https://jenkins.example.com/computer/raspi-ats-01/`
   - **Hoặc** click vào node → copy secret từ connection command
   - **Format**: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### Bước 3: Chạy Jenkins Agent Container

Trên Raspberry Pi, chạy lệnh sau:

```bash
# Sử dụng script có sẵn
./provision/raspi-agent/start-agent.sh \
  https://jenkins.example.com \
  raspi-ats-01 \
  YOUR_SECRET_HERE

# Hoặc chạy trực tiếp docker run
docker run -d --restart unless-stopped \
  --name jenkins-agent-raspi-ats-01 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/jenkins:/home/jenkins/agent \
  -e JENKINS_URL="https://jenkins.example.com" \
  -e JENKINS_AGENT_NAME="raspi-ats-01" \
  -e JENKINS_SECRET="YOUR_SECRET_HERE" \
  jenkins/inbound-agent:latest
```

**Lưu ý:**
- Thay `https://jenkins.example.com` bằng Jenkins URL thực tế
- Thay `YOUR_SECRET_HERE` bằng secret từ Bước 2
- Thay `raspi-ats-01` bằng node name bạn đã tạo

---

## 🔧 Manual Setup (Chi tiết)

### 1. Cài đặt Docker trên Raspberry Pi

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add pi user to docker group
sudo usermod -aG docker pi

# Logout and login again for group to take effect
```

### 2. Tạo thư mục workspace

```bash
# Create workspace directory on host
mkdir -p /home/jenkins
chmod 755 /home/jenkins
# Set ownership for container user (UID 1000)
sudo chown -R 1000:1000 /home/jenkins
```

**⚠️ QUAN TRỌNG**: Directory này sẽ được mount vào agent container và phải match với "Remote root directory" trong Jenkins node config.

### 3. Chạy Jenkins Agent Container

Sử dụng script `start-agent.sh` hoặc chạy trực tiếp:

```bash
docker run -d --restart unless-stopped \
  --name jenkins-agent-raspi-ats-01 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/jenkins:/home/jenkins/agent \
  -v /dev:/dev \
  -v /sys/class/gpio:/sys/class/gpio:ro \
  -v /dev/gpiomem:/dev/gpiomem \
  -e JENKINS_URL="https://jenkins.example.com" \
  -e JENKINS_AGENT_NAME="raspi-ats-01" \
  -e JENKINS_SECRET="YOUR_SECRET_HERE" \
  jenkins/inbound-agent:latest
```

**Volume mounts giải thích:**
- `/var/run/docker.sock`: Cho phép agent chạy Docker containers
- `/home/pi/agent`: Workspace cho Jenkins jobs
- `/dev`, `/sys/class/gpio`, `/dev/gpiomem`: Hardware access cho ESP32 testing

### 4. Verify Agent Connection

1. **Vào Jenkins UI** → `Manage Nodes and Clouds`
2. **Kiểm tra node** `raspi-ats-01`:
   - Status phải là **green** (connected)
   - Nếu red, check logs: `docker logs jenkins-agent-raspi-ats-01`

---

## 🏷️ Labels và Usage

### Label Configuration

**Label quan trọng**: `raspi-ats`

Pipeline sẽ dùng label này để schedule jobs:

```groovy
agent { label 'raspi-ats' }
```

### Multiple Pi Nodes

Nếu có nhiều Pi nodes:

- **Node 1**: `raspi-ats-01` với label `raspi-ats`
- **Node 2**: `raspi-ats-02` với label `raspi-ats`
- **Node 3**: `raspi-ats-03` với label `raspi-ats`

Jenkins sẽ tự động distribute jobs across các nodes có cùng label.

---

## 🐳 Docker Image Requirements

### ATS Node Test Image

Pipeline cần image `ats-node-test:latest` để chạy tests. Có 2 cách:

#### Option 1: Pull from Registry (Recommended)

```bash
# On Pi, pull image before running tests
docker pull myregistry/ats-node-test:latest
```

**Setup:**
- Build pipeline (on Xeon) builds và push image: `docker push myregistry/ats-node-test:latest`
- Test pipeline (on Pi) pulls image trước khi chạy

#### Option 2: Build on Pi

```bash
# On Pi, build image from ats-ats-node repo
cd ats-ats-node/docker/ats-node-test
docker build -t ats-node-test:latest .
```

**Setup:**
- Clone `ats-ats-node` repo trên Pi
- Pipeline builds image trước khi chạy tests

---

## 🔍 Troubleshooting

### Agent không connect được

**Check logs:**
```bash
docker logs jenkins-agent-raspi-ats-01
```

**Common issues:**
- **Wrong JENKINS_URL**: Phải là full URL với protocol (https://)
- **Wrong secret**: Copy lại secret từ Jenkins UI
- **Network issue**: Pi phải reach được Jenkins master
- **Firewall**: Check firewall rules

### Agent connect nhưng jobs fail

**Check:**
- Docker socket permission: `ls -l /var/run/docker.sock`
- Workspace permission: `ls -ld /home/pi/agent`
- Hardware access: `ls -l /dev/ttyUSB*`

### Container không có quyền access hardware

**Fix:**
- Thêm `--privileged` flag (nếu chưa có)
- Check volume mounts: `/dev`, `/sys/class/gpio`
- Check user permissions: `groups` (phải có docker group)

---

## 📝 Example: Complete Setup Script

```bash
#!/bin/bash
set -e

JENKINS_URL="${1:-https://jenkins.example.com}"
AGENT_NAME="${2:-raspi-ats-01}"
AGENT_SECRET="${3:-}"

if [ -z "$AGENT_SECRET" ]; then
  echo "❌ Error: AGENT_SECRET is required"
  echo "Usage: $0 <JENKINS_URL> <AGENT_NAME> <AGENT_SECRET>"
  exit 1
fi

# Stop existing container if exists
docker stop jenkins-agent-${AGENT_NAME} 2>/dev/null || true
docker rm jenkins-agent-${AGENT_NAME} 2>/dev/null || true

# Create workspace directory
mkdir -p /home/pi/agent

# Run Jenkins agent
docker run -d --restart unless-stopped \
  --name jenkins-agent-${AGENT_NAME} \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/jenkins:/home/jenkins/agent \
  -v /dev:/dev \
  -v /sys/class/gpio:/sys/class/gpio:ro \
  -v /dev/gpiomem:/dev/gpiomem \
  -e JENKINS_URL="${JENKINS_URL}" \
  -e JENKINS_AGENT_NAME="${AGENT_NAME}" \
  -e JENKINS_SECRET="${AGENT_SECRET}" \
  jenkins/inbound-agent:latest

echo "✅ Jenkins agent started: jenkins-agent-${AGENT_NAME}"
echo "📋 Check status: docker logs jenkins-agent-${AGENT_NAME}"
```

---

## 🔗 Related Documentation

- **ATS Node Design**: [ats-platform-docs/architecture/ats-node-design.md](../../ats-platform-docs/architecture/ats-node-design.md)
- **Test Pipeline**: [ats-fw-esp32-demo/platforms/ESP32/Jenkinsfile.test](../../ats-fw-esp32-demo/platforms/ESP32/Jenkinsfile.test)
- **ATS Node Test Container**: [ats-ats-node/docker/ats-node-test/README.md](../../ats-ats-node/docker/ats-node-test/README.md)

---

## 👤 Author

**Hai Dang Son**  
Senior Embedded / Embedded Linux / IoT Engineer

