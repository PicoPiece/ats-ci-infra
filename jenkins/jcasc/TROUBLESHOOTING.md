# Troubleshooting Jenkins JCasC Configuration

## Issue: Job Still Using Old Git URL After Config Update

### Symptoms
- Jenkins job still tries to checkout from old URL (e.g., `https://github.com/your-org/ats-fw-esp32-demo.git`)
- Error: `Authentication failed for 'https://github.com/your-org/...'`
- JCasC config has been updated but job doesn't reflect changes

### Root Cause
JCasC/Job DSL may not always update existing jobs. It primarily creates new jobs but may not overwrite existing ones completely.

### Solutions

#### Solution 1: Delete and Recreate Job (Recommended)

1. **Delete the job:**
   - Go to Jenkins UI
   - Navigate to: `platforms/ESP32/ats-fw-esp32-demo-ESP32-test`
   - Click **Delete** (or **Delete Project**)
   - Confirm deletion

2. **Restart Jenkins:**
   ```bash
   cd /home/picopiece/ats_center/ats-ci-infra
   docker compose restart jenkins
   ```

3. **Verify:**
   - Wait for Jenkins to restart (~30 seconds)
   - Check that job is recreated with correct URL
   - Job should now use: `git@github.com:PicoPiece/ats-fw-esp32-demo.git`

#### Solution 2: Manual Update in Jenkins UI

1. **Go to job configuration:**
   - Jenkins UI → `platforms/ESP32/ats-fw-esp32-demo-ESP32-test`
   - Click **Configure**

2. **Update Pipeline definition:**
   - Scroll to **Pipeline** section
   - **Definition**: `Pipeline script from SCM`
   - **SCM**: `Git`
   - **Repository URL**: `git@github.com:PicoPiece/ats-fw-esp32-demo.git`
   - **Credentials**: (leave empty if using SSH)
   - **Branch**: `*/main`
   - **Script Path**: `platforms/ESP32/Jenkinsfile.test`

3. **Update Parameters:**
   - Scroll to **Parameters** section
   - Update parameters to match `jenkins.yaml`:
     - `BUILD_JOB_NAME`: `platforms/ESP32/ats-fw-esp32-demo`
     - `BUILD_NUMBER`: (empty)
     - `ATS_NODE_LABEL`: `ats-node`
     - `ATS_NODE_TEST_IMAGE`: `ats-node-test:latest`
     - `TEST_REPO_URL`: `https://github.com/PicoPiece/ats-test-esp32-demo.git`
     - `TEST_REPO_BRANCH`: `main`

4. **Save**

#### Solution 3: Force Reload JCasC

1. **Go to Configuration as Code:**
   - Jenkins UI → **Manage Jenkins** → **Configuration as Code**

2. **Reload configuration:**
   - Click **Reload existing configuration**
   - Or click **Apply new configuration**

3. **Check logs:**
   ```bash
   docker logs jenkins-master | grep -i "configuration\|job\|error"
   ```

### Verification

After applying any solution, verify:

1. **Check job configuration:**
   - Go to job → Configure
   - Verify Git URL is correct: `git@github.com:PicoPiece/ats-fw-esp32-demo.git`

2. **Test job:**
   - Trigger a test build
   - Check console output
   - Should see: `Checking out git git@github.com:PicoPiece/ats-fw-esp32-demo.git`

3. **Check logs:**
   ```bash
   docker logs jenkins-master 2>&1 | tail -50
   ```

### Prevention

To avoid this issue in the future:

1. **Always use SSH URLs** in `jenkins.yaml` (consistent with other repos)
2. **Delete jobs before major config changes** if needed
3. **Test config changes** in a test Jenkins instance first
4. **Version control** `jenkins.yaml` to track changes

## Issue: SSH Host Key Verification Failed

### Symptoms
- Error: `Host key verification failed`
- Error: `Could not read from remote repository`
- Jenkins cannot clone from GitHub using SSH URLs

### Root Cause
Jenkins container doesn't have SSH keys configured or GitHub host key not in known_hosts.

### Solutions

#### Solution 1: Copy Existing SSH Key (Recommended)

If you already have an SSH key that's added to GitHub:

```bash
# Copy your SSH key to Jenkins container
docker cp ~/.ssh/id_rsa jenkins-master:/var/jenkins_home/.ssh/id_rsa
docker cp ~/.ssh/id_rsa.pub jenkins-master:/var/jenkins_home/.ssh/id_rsa.pub

# Set correct permissions
docker exec jenkins-master chown -R jenkins:jenkins /var/jenkins_home/.ssh
docker exec jenkins-master chmod 600 /var/jenkins_home/.ssh/id_rsa
docker exec jenkins-master chmod 644 /var/jenkins_home/.ssh/id_rsa.pub

# Add GitHub to known_hosts
docker exec jenkins-master bash -c "ssh-keyscan github.com >> /var/jenkins_home/.ssh/known_hosts"
docker exec jenkins-master chown jenkins:jenkins /var/jenkins_home/.ssh/known_hosts
```

#### Solution 2: Generate New SSH Key

```bash
# Generate new SSH key in Jenkins container
docker exec -u jenkins jenkins-master ssh-keygen -t ed25519 -C 'jenkins@ats-ci' -f /var/jenkins_home/.ssh/id_ed25519 -N ''

# Display public key
docker exec jenkins-master cat /var/jenkins_home/.ssh/id_ed25519.pub
```

Then:
1. Copy the public key output
2. Go to GitHub: **Settings** → **SSH and GPG keys** → **New SSH key**
3. Paste the public key and save

#### Solution 3: Use HTTPS with GitHub Token (Alternative)

If SSH setup is too complex, use HTTPS with GitHub Personal Access Token:

1. **Generate GitHub token:**
   - GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Generate new token with `repo` scope

2. **Add credentials in Jenkins:**
   - Jenkins UI → **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
   - Add new credential:
     - Kind: `Username with password`
     - Username: `your-github-username`
     - Password: `your-github-token`
     - ID: `github-token`

3. **Update jenkins.yaml:**
   ```yaml
   git {
     remote {
       url('https://github.com/PicoPiece/ats-fw-esp32-demo.git')
       credentials('github-token')  # Use credential ID
     }
   }
   ```

4. **Restart Jenkins:**
   ```bash
   docker compose restart jenkins
   ```

### Verification

Test SSH connection:
```bash
docker exec -u jenkins jenkins-master ssh -T git@github.com
```

Expected output:
```
Hi PicoPiece! You've successfully authenticated, but GitHub does not provide shell access.
```

### Helper Script

Use the setup script:
```bash
cd ats-ci-infra
./jenkins/jcasc/setup-ssh.sh
```

### Related Files

- `jenkins/jcasc/jenkins.yaml` - Main configuration file
- `jenkins/jcasc/README.md` - Setup guide
- `jenkins/jcasc/fix-test-job.sh` - Helper script
- `jenkins/jcasc/setup-ssh.sh` - SSH setup script

