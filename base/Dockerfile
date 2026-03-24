FROM node:23-slim AS nodejs

FROM ubuntu:24.04

ARG HOST_UID=1000
ARG HOST_GID=1000
ARG LOCAL_TOOLS="git curl jq ripgrep neovim nano make zip unzip openssh-client wget tree imagemagick ca-certificates gnupg procps mc tig build-essential python3 python3-pip wl-clipboard xclip xsel"

# Copy Node.js 23.x toolchain from the official image
COPY --from=nodejs /usr/local/ /usr/local/

# 1. Install system dependencies and language SDKs (as root)
RUN apt-get update && \
  apt-get install -y --no-install-recommends ca-certificates curl gnupg wget && \
  wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb && \
  dpkg -i /tmp/packages-microsoft-prod.deb && \
  rm -f /tmp/packages-microsoft-prod.deb && \
  apt-get update && \
  apt-get install -y --no-install-recommends ${LOCAL_TOOLS} libboost-all-dev openjdk-21-jdk dotnet-sdk-10.0 && \
  ln -sf /usr/bin/nvim /usr/local/bin/vim && \
  rm -rf /var/lib/apt/lists/*

# Install Bun by copying from the official image
# This installs bun globally to /usr/local/bin so it is available to everyone
COPY --from=oven/bun:1 /usr/local/bin/bun /usr/local/bin/bun
# Create the bunx symlink (standard practice)
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx

# Install tod (One Dev CLI / MCP binary)
COPY bin/tod /usr/local/bin/tod
RUN chmod +x /usr/local/bin/tod

# Install Playwright system dependencies for Chromium (required by agent-browser)
RUN npx playwright install-deps chromium

# 2. Create and configure the 'ubuntu' user
RUN if getent group ubuntu >/dev/null 2>&1; then \
    groupmod -o --gid ${HOST_GID} ubuntu; \
  else \
    groupadd -o --gid ${HOST_GID} ubuntu; \
  fi && \
  if id -u ubuntu >/dev/null 2>&1; then \
    usermod -o --uid ${HOST_UID} --gid ${HOST_GID} --home /home/ubuntu --shell /bin/bash ubuntu; \
  else \
    useradd -o --uid ${HOST_UID} --gid ${HOST_GID} --create-home --home-dir /home/ubuntu --shell /bin/bash ubuntu; \
  fi

# 3. Configure app directory ownership
WORKDIR /app
RUN chown -R ubuntu:ubuntu /app

# 4. Switch to 'ubuntu' user for config setup
USER ubuntu

# 5. Configure NPM global location for the 'ubuntu' user
# This allows npm install -g without root permissions
ENV NPM_CONFIG_PREFIX=/home/ubuntu/.npm-global
ENV PATH=$NPM_CONFIG_PREFIX/bin:$PATH

# Configure Bun global location for 'ubuntu' user
# This ensures 'bun install -g' works without root and saves to the user home
ENV BUN_INSTALL=/home/ubuntu/.bun
ENV PATH=$BUN_INSTALL/bin:$PATH

RUN mkdir -p /home/ubuntu/.npm-global && \
  mkdir -p /home/ubuntu/.config && \
  mkdir -p /home/ubuntu/.local && \
  mkdir -p /home/ubuntu/.bun/bin

# 6. Install agent-browser (headless browser automation CLI for AI agents)
# Downloads Chromium browser to user's cache
RUN npm install -g agent-browser && \
  agent-browser install

# 7. Bash Configuration
# Add the path export to bashrc so interactive shells pick it up
RUN echo "export PATH=${NPM_CONFIG_PREFIX}/bin:${BUN_INSTALL}/bin:\$PATH" >> /home/ubuntu/.bashrc

# Provide common aliases for all users
USER root
COPY ./.bash_aliases /etc/bash_aliases
RUN if ! grep -q '/etc/bash_aliases' /etc/bash.bashrc; then \
    echo 'if [ -f /etc/bash_aliases ]; then . /etc/bash_aliases; fi' >> /etc/bash.bashrc; \
  fi

# 8. Copy aliases to the 'ubuntu' user's home
USER ubuntu
COPY --chown=ubuntu:ubuntu ./.bash_aliases /home/ubuntu/.bash_aliases
RUN echo "if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi" >> /home/ubuntu/.bashrc

CMD ["/bin/bash"]
