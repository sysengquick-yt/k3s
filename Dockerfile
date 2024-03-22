FROM mcr.microsoft.com/devcontainers/python:1-3.12-bullseye

# OCI labels
LABEL org.opencontainers.image.source=https://github.com/sysengquick/k3s
LABEL org.opencontainers.image.description="devcontainer image for building sysenquick k3s cluster"
LABEL org.opencontainers.image.licenses=Apache-2.0

# install poetry
RUN python3 -m pip install poetry~=1.8.2

# install poetry dependencies
WORKDIR /app

COPY poetry.lock pyproject.toml /app
RUN poetry config virtualenvs.create false && poetry install

# install collection requirements
COPY collections/requirements.yml /app
RUN su vscode -c "ansible-galaxy collection install -r requirements.yml"
RUN su vscode -c "ln -s /workspace/collections/sysengquick ~/.ansible/collections/ansible_collections/"

# enable git bash completion and preserve bash history
RUN su vscode -c "echo 'source /usr/share/bash-completion/completions/git' >> ~/.bashrc"
RUN su vscode -c "echo 'export HISTFILE=/bash_history/history.txt' >> ~/.bashrc"

# install iputils-ping and dnsutils
RUN apt-get update && apt-get install -y iputils-ping dnsutils

# install k3sup
ARG K3SUP_VERSION=0.13.5
RUN curl -sLS \
    https://github.com/alexellis/k3sup/releases/download/${K3SUP_VERSION}/k3sup \
    -o /usr/local/bin/k3sup \
    && chmod 755 /usr/local/bin/k3sup

# install kubectl
ARG KUBECTL_VERSION=v1.27
RUN mkdir -p -m 755 /etc/apt/keyrings
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBECTL_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
RUN echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/'${KUBECTL_VERSION}'/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update && apt-get install -y kubectl

# install helm
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
RUN apt-get update && apt-get install -y helm

# install helm repos for rancher
RUN su vscode -c "helm repo add rancher-stable https://releases.rancher.com/server-charts/stable"
RUN su vscode -c "helm repo add jetstack https://charts.jetstack.io"
RUN su vscode -c "helm repo update"
