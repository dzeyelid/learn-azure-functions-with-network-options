FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    curl \
    dnsutils \
    git \
    gnupg \
    software-properties-common \
    vim \
  && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
  && rm -rf /var/lib/apt/lists/*

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
  apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
  apt-get update && apt-get install terraform && \
  rm -rf /var/lib/apt/lists/*

RUN mkdir -p /workspaces/repo

WORKDIR /workspaces/repo

COPY . /workspaces/repo

CMD tail -f /dev/null
