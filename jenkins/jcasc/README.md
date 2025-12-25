# Jenkins Configuration as Code (JCasC)

Quản lý Jenkins jobs và folders bằng YAML. **Restart Jenkins để apply config tự động.**

## Cách hoạt động

1. Edit file `jenkins.yaml` → define folders và jobs
2. Restart Jenkins → config tự động được apply
3. Jobs và folders được tạo/update tự động

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

Hoặc sau khi jobs được tạo, có thể update Git URL từ Jenkins UI.

### 3. Restart Jenkins

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
3. Restart Jenkins: `docker compose restart jenkins`

## Workflow

```
Edit jenkins.yaml
    ↓
Restart Jenkins (docker compose restart jenkins)
    ↓
JCasC tự động load config
    ↓
Folders và Jobs được tạo/update
```

## Lưu ý

- ✅ **Restart Jenkins = Auto update** - Không cần làm gì thêm
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
- Update trong `jenkins.yaml` hoặc
- Vào job → Configure → update Git URL
