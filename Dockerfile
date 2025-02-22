FROM --platform=$BUILDPLATFORM ubuntu:22.04

LABEL maintainer="@k33g_org"

ENV TERM=xterm-256color

ARG TARGETOS
ARG TARGETARCH

ARG KUBECTL_VERSION=${KUBECTL_VERSION}
ARG HELM_VERSION=${HELM_VERSION}
ARG K9S_VERSION=${K9S_VERSION}

ARG GO_VERSION=${GO_VERSION}
ARG NODE_MAJOR=${NODE_MAJOR}

#ARG USER_NAME=${USER_NAME}
ARG USER_NAME=bob

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_COLLATE=C
ENV LC_CTYPE=en_US.UTF-8

# ------------------------------------
# Install Tools
# ------------------------------------
RUN <<EOF
apt-get update 
apt-get install -y curl wget bat sudo sshpass git exa mc zsh
ln -s /usr/bin/batcat /usr/bin/bat

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

apt-get clean autoclean
apt-get autoremove --yes
rm -rf /var/lib/{apt,dpkg,cache,log}/
EOF

# ------------------------------------
# Install Kubectl
# ------------------------------------
RUN <<EOF
curl -LO https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/${TARGETOS}/${TARGETARCH}/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
EOF

# ------------------------------------
# Install Helm
# ------------------------------------
RUN <<EOF
wget https://get.helm.sh/helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz
tar xvf helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz
mv ${TARGETOS}-${TARGETARCH}/helm /usr/local/bin
rm helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz
EOF

# ------------------------------------
# Install K9s
# ------------------------------------
RUN <<EOF
wget https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${TARGETARCH}.tar.gz
tar xvf k9s_Linux_${TARGETARCH}.tar.gz -C /usr/local/bin
rm k9s_Linux_${TARGETARCH}.tar.gz
EOF

# ------------------------------------
# Install Go
# ------------------------------------
RUN <<EOF

wget https://golang.org/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz
tar -xvf go${GO_VERSION}.linux-${TARGETARCH}.tar.gz
mv go /usr/local
rm go${GO_VERSION}.linux-${TARGETARCH}.tar.gz
EOF

# ------------------------------------
# Set Environment Variables for Go
# ------------------------------------
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/home/${USER_NAME}/go"
ENV GOROOT="/usr/local/go"

RUN <<EOF
go version
go install -v golang.org/x/tools/gopls@latest
go install -v github.com/ramya-rao-a/go-outline@latest
go install -v github.com/stamblerre/gocode@v1.0.0
go install -v github.com/mgechev/revive@v1.3.2
EOF

# ------------------------------------
# Install NodeJS
# ------------------------------------
RUN <<EOF
apt-get update && apt-get install -y ca-certificates curl gnupg
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update && apt-get install nodejs -y
EOF
    
# ------------------------------------
# Create a new user
# ------------------------------------
# Create new regular user `${USER_NAME}` and disable password and gecos for later
# --gecos explained well here: https://askubuntu.com/a/1195288/635348
RUN adduser --disabled-password --gecos '' ${USER_NAME}

#  Add new user `${USER_NAME}` to sudo
RUN adduser ${USER_NAME} sudo

# Ensure sudo group users are not asked for a password when using 
# sudo command by ammending sudoers file
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set the working directory
WORKDIR /home/${USER_NAME}

# Set the user as the owner of the working directory
RUN chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

ENV SHELL=/bin/zsh

RUN usermod -s /bin/zsh ${USER_NAME}

# Switch to the regular user
USER ${USER_NAME}

# Avoid the message about sudo
RUN touch ~/.sudo_as_admin_successful

COPY --chown=user:group .zshrc /home/${USER_NAME}/.zshrc

SHELL ["/bin/zsh", "-c"]