FROM jenkins/inbound-agent:latest

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV IDF_PATH=/opt/esp/idf

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    cmake \
    ninja-build \
    ccache \
    build-essential \
    libffi-dev \
    libssl-dev \
    libusb-1.0-0 \
    flex \
    bison \
    gperf \
    && rm -rf /var/lib/apt/lists/*\
    && ln -s /usr/bin/python3 /usr/bin/python

# Install ESP-IDF
RUN mkdir -p /opt/esp && \
    cd /opt/esp && \
    git clone --depth 1 -b v5.2 https://github.com/espressif/esp-idf.git idf && \
    cd idf && \
    git submodule update --init --recursive

# Install ESP-IDF Python environment as root (tools go to /root/.espressif)
RUN cd /opt/esp/idf && \
    ./install.sh esp32

# Fix git safe.directory warning for jenkins user
RUN git config --global --add safe.directory /opt/esp/idf

# Copy ESP-IDF tools to jenkins user home
RUN mkdir -p /home/jenkins/.espressif && \
    cp -r /root/.espressif/* /home/jenkins/.espressif/ && \
    chown -R jenkins:jenkins /home/jenkins/.espressif

# Source ESP-IDF environment by default
ENV PATH="/opt/esp/idf/tools:$PATH"

# Add ESP-IDF to bashrc for jenkins user
RUN echo 'source /opt/esp/idf/export.sh' >> /home/jenkins/.bashrc && \
    echo 'export IDF_PATH=/opt/esp/idf' >> /home/jenkins/.bashrc

USER jenkins

WORKDIR /home/jenkins/agent

