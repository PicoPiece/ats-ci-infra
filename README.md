# ATS CI Infrastructure

> **Jenkins, Prometheus, and Grafana infrastructure for Embedded Firmware Automation Test System**

This repository contains the CI/CD and observability infrastructure for the Embedded Firmware Automation Test System (ATS).

It provides:

- Jenkins-based pipeline orchestration
- Centralized firmware build and test dispatch
- Metrics collection via Prometheus
- Visualization via Grafana

All services are designed to run on a single Xeon server using Docker, while supporting multiple remote ATS nodes for hardware testing.

This infrastructure reflects how real embedded teams operate CI for firmware validation at scale.

---

## 📁 Repository Structure

```
ats-ci-infra/
├── README.md
├── docker-compose.yml
├── jenkins/
│   ├── jenkins_home/          # Jenkins data volume
│   ├── jcasc/                  # Configuration as Code
│   │   ├── jenkins.yaml
│   │   └── setup.sh
│   └── fw-build/
│       └── Dockerfile         # Custom build agent image
├── provision/
│   └── raspi-agent/          # Raspberry Pi agent setup
│       ├── README.md         # Setup guide
│       ├── start-agent.sh    # Agent startup script
│       └── Jenkinsfile.example  # Example test pipeline
├── prometheus/
│   └── prometheus.yml
└── grafana/
    ├── provisioning/
    └── dashboards/
```

---

## 🎯 Design Principles

This infrastructure follows a few strict rules:

- **Jenkins orchestrates, not executes hardware** (Jenkins is "dumb and replaceable")
- **Hardware access lives only on ATS nodes** (`ats-ats-node` owns all hardware interaction)
- **Build environments are reproducible**
- **Metrics and logs are first-class citizens**
- **Scaling ATS capacity must not require CI redesign**
- **Jenkins pipelines are simple** - they only fetch artifacts and run Docker containers

The goal is reliability, debuggability, and clarity — not complexity.

---

## 🏗️ Infrastructure Components

### 2.1 Jenkins

**Role:**

- Central CI orchestrator
- Receives GitHub webhooks
- Schedules jobs across agents

**Runs on:**

- Xeon server
- Docker container
- Persistent volumes for:
  - Jenkins home
  - Job configuration
  - Plugins

**Key responsibilities:**

- Trigger firmware builds
- Copy artifacts to ATS nodes (via workspace)
- Run `ats-node-test` Docker container on ATS nodes
- Archive test results
- **Jenkins does NOT:**
  - Detect USB ports
  - Know about GPIO pins
  - Execute flashing logic
  - Run test scripts directly

### 2.2 Jenkins Build Agents

**Role:**

- Build firmware and images
- Produce versioned artifacts

**Characteristics:**

- No hardware access
- Clean, reproducible environment
- Can be scaled horizontally if needed

Build agents run as Docker containers and are labeled accordingly (e.g. `fw-build`).

### 2.3 Prometheus

**Role:**

- Central metrics collector
- Scrapes metrics from all ATS nodes

**Metrics sources:**

- ATS test execution results
- Firmware version under test
- Test duration and failure rates

Prometheus runs as a Docker service on the Xeon server.

### 2.4 Grafana

**Role:**

- Visualization and analysis
- Firmware regression dashboards
- Release confidence indicators

Grafana reads from Prometheus and provides dashboards for:

- Pass/fail trends
- Stability over time
- OTA reliability

---

## 🚀 High-Level Deployment Model

All CI infrastructure runs on the Xeon server using Docker Compose.

```
Xeon Server
│
├── Jenkins Master (Docker)
├── Jenkins Build Agent(s) (Docker)
├── Prometheus (Docker)
└── Grafana (Docker)
```

**ATS Nodes** (Raspberry Pi / Mini PC) are not part of this Docker stack and connect remotely.

---

## 📦 Docker Compose Services

### Jenkins

- **Image:** `jenkins/jenkins:lts`
- Exposes web UI and agent ports
- Uses persistent volume for `/var/jenkins_home`
- Configuration as Code (JCasC) enabled

### Jenkins Build Agent

- **Custom image:** `ats-fw-build:esp32`
- Connected to Jenkins Master
- Labeled for firmware build tasks (`fw-build`)
- Pre-installed ESP-IDF toolchain

### Prometheus

- Scrapes ATS node metrics endpoints
- Stores time-series test data
- Exposes UI on port `9090`

### Grafana

- Visualizes test metrics
- Provides release confidence dashboards
- Exposes UI on port `3000`

---

## 🔄 Jenkins Pipeline Model

The Jenkins pipeline is structured into clear, isolated stages:

### Build Pipeline (`Jenkinsfile`)
1. **Source checkout**
2. **Firmware build**
3. **Artifact packaging** (firmware binary + `ats-manifest.yaml`)
4. **Git tagging** (local tag for versioning)
5. **Trigger test pipeline** (asynchronous, non-blocking)

### Test Pipeline (`Jenkinsfile.test`)
1. **Prepare workspace** (copy artifacts from build job, checkout test framework)
2. **Build ATS node test container** (`ats-node-test` from `ats-ats-node`)
3. **Run ATS tests** (single `docker run` command - container owns all hardware logic)
4. **Archive results** (JUnit XML, summary JSON, logs)

**Hardware tests always run on agents labeled `ats-node`.**
**Jenkins is "dumb" - it only orchestrates Docker containers.**

### Test Pipeline Integration

**Test pipelines are simple and "dumb":**

1. Copy artifacts (firmware binary + `ats-manifest.yaml`) from build job
2. Checkout test framework (`ats-test-esp32-demo`)
3. Build `ats-node-test` Docker container (from `ats-ats-node`)
4. Run container - container handles:
   - Manifest loading
   - Firmware flashing
   - Test runner invocation
   - Result generation
5. Archive results from `/results` directory

**Jenkins does not know about:**
- USB ports
- GPIO pins
- Test scripts
- Hardware detection

**All hardware logic lives in `ats-ats-node` Docker container.**

---

## 🔌 ATS Node Integration

ATS nodes connect to this infrastructure by:

- Running a Jenkins agent (native or privileged container)
- Exposing a `/metrics` HTTP endpoint
- Receiving firmware artifacts via Jenkins workspace or artifact transfer

**ATS nodes:**

- Do not build code
- Do not host CI services
- Execute only hardware-dependent tasks

### Setting Up Raspberry Pi Agents

See [provision/raspi-agent/README.md](provision/raspi-agent/README.md) for detailed instructions on:

- Creating Jenkins agent nodes
- Running Jenkins agent containers on Raspberry Pi
- Configuring labels and workspace
- Troubleshooting connection issues

**Quick start:**
```bash
./provision/raspi-agent/start-agent.sh \
  https://jenkins.example.com \
  raspi-ats-01 \
  YOUR_SECRET_HERE
```

**Example pipeline:** See [provision/raspi-agent/Jenkinsfile.example](provision/raspi-agent/Jenkinsfile.example) for a complete test pipeline that runs on Pi agents.

---

## 📊 Observability Strategy

### Metrics Collected

Examples:

- `ats_test_pass_total`
- `ats_test_fail_total`
- `ats_test_duration_seconds`
- `ats_ota_failure_total`
- `ats_fw_version`

### Usage

- Detect regressions early
- Compare firmware versions objectively
- Provide confidence before release

---

## 📈 Multi-ATS Scaling

This infrastructure supports multiple ATS nodes by design.

**To add a new ATS node:**

1. Provision Raspberry Pi / Mini PC
2. Install Jenkins agent
3. Assign `ats-node` label
4. Register metrics endpoint in Prometheus

**No Jenkins pipeline changes are required.**

---

## ✅ What This Repository Is (and Is Not)

### This repository is:

- CI backbone for firmware automation
- Production-style infrastructure
- Designed for real teams

### This repository is not:

- A cloud-native platform
- A testing framework
- A UI-focused product

---

## 🔗 Relationship to Other Repositories

This infrastructure supports the overall ATS platform by:

- **Building firmware** from `ats-fw-esp32-demo`
- **Dispatching build artifacts** to ATS nodes for hardware testing
- **Collecting and visualizing** test metrics defined in `ats-platform-docs`
- **Orchestrating test execution** via `ats-test-esp32-demo` framework

---

## 📊 Status

This infrastructure is under active development and will evolve as:

- More ATS nodes are added
- More firmware targets are integrated
- Test coverage expands

---

## 👤 Author

**Hai Dang Son**  
Senior Embedded / Embedded Linux / IoT Engineer
