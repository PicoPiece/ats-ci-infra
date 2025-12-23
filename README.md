# -ATS_Center-Ats-ci-infra

ats-ci-infra/
├── README.md
├── docker-compose.yml
├── jenkins/
│   ├── Jenkinsfile.demo
│   └── agents.md
├── prometheus/
│   └── prometheus.yml
└── grafana/
    └── dashboards/
    
# ATS CI Infrastructure
Overview
This repository contains the CI/CD and observability infrastructure for the Embedded Firmware Automation Test System (ATS).
It provides:
Jenkins-based pipeline orchestration
Centralized firmware build and test dispatch
Metrics collection via Prometheus
Visualization via Grafana
All services are designed to run on a single Xeon server using Docker, while supporting multiple remote ATS nodes for hardware testing.
This infrastructure reflects how real embedded teams operate CI for firmware validation at scale.

1. Design Principles
This infrastructure follows a few strict rules:
Jenkins orchestrates, not executes hardware
Hardware access lives only on ATS nodes
Build environments are reproducible
Metrics and logs are first-class citizens
Scaling ATS capacity must not require CI redesign
The goal is reliability, debuggability, and clarity — not complexity.

2. Infrastructure Components
   
    2.1 Jenkins
    Role
    Central CI orchestrator
    Receives GitHub webhooks
    Schedules jobs across agents
    Runs on
    Xeon server
    Docker container
    Persistent volumes for:
    Jenkins home
    Job configuration
    Plugins
    Key responsibilities
    Trigger firmware builds
    Dispatch artifacts to ATS nodes
    Collect test results
    Enforce pipeline logic
    
    2.2 Jenkins Build Agents
    Role
    Build firmware and images
    Produce versioned artifacts
    Characteristics
    No hardware access
    Clean, reproducible environment
    Can be scaled horizontally if needed
    Build agents run as Docker containers and are labeled accordingly (e.g. fw-build).
    
    2.3 Prometheus
    Role
    Central metrics collector
    Scrapes metrics from all ATS nodes
    Metrics sources
    ATS test execution results
    Firmware version under test
    Test duration and failure rates
    Prometheus runs as a Docker service on the Xeon server.
    
    2.4 Grafana
    Role
    Visualization and analysis
    Firmware regression dashboards
    Release confidence indicators
    Grafana reads from Prometheus and provides dashboards for:
    Pass/fail trends
    Stability over time
    OTA reliability

3. High-Level Deployment Model
  All CI infrastructure runs on the Xeon server using Docker Compose.
  Xeon Server
  │
  ├── Jenkins Master (Docker)
  ├── Jenkins Build Agent(s) (Docker)
  ├── Prometheus (Docker)
  └── Grafana (Docker)
  ATS Nodes (Raspberry Pi / Mini PC) are not part of this Docker stack and connect remotely.

4. Repository Structure
ats-ci-infra/
├── README.md
├── docker-compose.yml
├── jenkins/
│   ├── Jenkinsfile.demo
│   ├── agents.md
│   └── credentials.md
├── prometheus/
│   └── prometheus.yml
└── grafana/
    ├── dashboards/
    └── provisioning/

5. docker-compose Services
Jenkins
Image: jenkins/jenkins:lts
Exposes web UI and agent ports
Uses persistent volume for /var/jenkins_home
Jenkins Build Agent
Custom image or official Jenkins agent
Connected to Jenkins Master
Labeled for firmware build tasks
Prometheus
Scrapes ATS node metrics endpoints
Stores time-series test data
Grafana
Visualizes test metrics
Provides release confidence dashboards

6. Jenkins Pipeline Model
The Jenkins pipeline is structured into clear, isolated stages:
Source checkout
Firmware build
Artifact packaging
Dispatch to ATS node
Hardware test execution
Result collection and reporting
Hardware tests always run on agents labeled ats-node.

7. ATS Node Integration
ATS nodes connect to this infrastructure by:
Running a Jenkins agent (native or privileged container)
Exposing a /metrics HTTP endpoint
Receiving firmware artifacts via Jenkins workspace or artifact transfer
ATS nodes:
Do not build code
Do not host CI services
Execute only hardware-dependent tasks

8. Observability Strategy
Metrics Collected
Examples:
ats_test_pass_total
ats_test_fail_total
ats_test_duration_seconds
ats_ota_failure_total
ats_fw_version
Usage
Detect regressions early
Compare firmware versions objectively
Provide confidence before release

9. Multi-ATS Scaling
This infrastructure supports multiple ATS nodes by design.
To add a new ATS node:
Provision Raspberry Pi / Mini PC
Install Jenkins agent
Assign ats-node label
Register metrics endpoint in Prometheus
No Jenkins pipeline changes are required.

10. What This Repository Is (and Is Not)
This repository is:
CI backbone for firmware automation
Production-style infrastructure
Designed for real teams
This repository is not:
A cloud-native platform
A testing framework
A UI-focused product

11. Status
This infrastructure is under active development and will evolve as:
More ATS nodes are added
More firmware targets are integrated
Test coverage expands

Author
Hai Dang Son
Senior Embedded / Embedded Linux / IoT Engineer
