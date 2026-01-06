# Jenkins Configuration as Code (JCasC)

Quản lý Jenkins jobs và folders bằng YAML. **Restart Jenkins để apply config tự động.**

## Cách hoạt động

1. Edit file `jenkins.yaml` → define folders và jobs
2. Sync config to container (tự động hoặc manual)
3. Reload JCasC config → jobs được update tự động

## Setup

### 1. Install Plugins (Lần đầu)

Vào Jenkins UI:
- **Manage Jenkins** → **Manage Plugins**
- Tab **Available** → install:
  - ✅ **Configuration as Code** (JCasC)
  - ✅ **Job DSL**
  - ✅ **Folders**

Hoặc chạy script:
```bash
cd ats-ci-infra
./jenkins/jcasc/setup.sh
```

### 2. Update Git Repo URL

Edit `jenkins.yaml` và thay `https://github.com/your-org/ats-fw-esp32-demo.git` bằng URL thực tế của bạn.

**Lưu ý:** Volume mount không còn read-only, nên file trong container sẽ tự động sync với file local khi container restart.

### 3. Sync Config và Reload

**Option 1: Auto sync (recommended)**
```bash
cd ats-ci-infra
./jenkins/jcasc/sync-config.sh --restart
```

**Option 2: Manual sync**
```bash
# Copy config to container
./jenkins/jcasc/sync-config.sh

# Then reload in Jenkins UI:
# Manage Jenkins → Configuration as Code → Reload existing configuration
```

**Option 3: Restart container (auto sync)**
```bash
cd ats-ci-infra
docker compose restart jenkins
```

### 4. Verify

- Vào Jenkins UI → xem có folder `platforms/ESP32/` không
- Check jobs:
  - `platforms/ESP32/ats-fw-esp32-demo` (build)
  - `platforms/ESP32/ats-fw-esp32-demo-ESP32-test` (test)

## Cấu trúc

File `jenkins.yaml` define:
- **Folders**: `platforms/`, `platforms/ESP32/`, `platforms/RaspberryPi/`, `platforms/nRF52/`
- **Jobs**: Build và test jobs cho từng platform

## Thêm Platform Mới

1. Edit `jenkins.yaml`
2. Thêm folder và jobs mới vào `jobs.script`:
   ```yaml
   folder('platforms/NewPlatform') {
     displayName('New Platform')
   }
   
   pipelineJob('platforms/NewPlatform/build-job') {
     // job definition
   }
   ```
3. Sync và reload:
   ```bash
   ./jenkins/jcasc/sync-config.sh --restart
   ```

## Workflow

```
Edit jenkins.yaml (local)
    ↓
Sync to container (sync-config.sh)
    ↓
Restart Jenkins or Reload JCasC
    ↓
Folders và Jobs được tạo/update
```

## Helper Scripts

### sync-config.sh

Sync `jenkins.yaml` to container và reload config.

```bash
# Sync only (no reload)
./jenkins/jcasc/sync-config.sh

# Sync with reload instructions
./jenkins/jcasc/sync-config.sh --reload

# Sync and restart Jenkins
./jenkins/jcasc/sync-config.sh --restart
```

### fix-test-job.sh

Helper script để fix test job configuration issues.

## Lưu ý

- ✅ **Volume mount** - File tự động sync khi container restart (không còn read-only)
- ✅ **Version control** - File YAML có thể commit vào Git
- ✅ **Reproducible** - Dễ recreate Jenkins environment
- ⚠️ **Git URL** - Cần update trong `jenkins.yaml` hoặc Jenkins UI
- ⚠️ **Job DSL syntax** - Cần đúng syntax để tránh lỗi

## Troubleshooting

### Jobs không được tạo
- Check Jenkins logs: `docker logs jenkins-master`
- Vào **Manage Jenkins** → **Configuration as Code** → xem errors
- Check Job DSL syntax trong `jenkins.yaml`

### Folders không xuất hiện
- Đảm bảo plugin **Folders** đã được install
- Check Job DSL script có đúng syntax không

### Git URL không đúng
- Update trong `jenkins.yaml`
- Sync config: `./jenkins/jcasc/sync-config.sh --restart`
- Hoặc vào job → Configure → update Git URL manually

### Config không update sau khi sửa file
- Sync config: `./jenkins/jcasc/sync-config.sh --restart`
- Hoặc restart Jenkins: `docker compose restart jenkins`
- Reload JCasC: Jenkins UI → Configuration as Code → Reload

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more details.
