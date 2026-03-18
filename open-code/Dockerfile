# Build stage
FROM agent-base AS builder

# We act as 'ubuntu' user (inherited from base)
# Because we set NPM_CONFIG_PREFIX in base, this installs to /home/ubuntu/.npm-global
RUN npm install -g opencode-ai && \
  echo "Installed Open Code version: $(opencode --version)"

# Runtime stage
FROM agent-base

# Copy the installed global modules from builder
# We must use --chown to ensure the ubuntu user owns the copied files
COPY --from=builder --chown=ubuntu:ubuntu /home/ubuntu/.npm-global /home/ubuntu/.npm-global

# Display version information
RUN echo "" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m                   OPEN CODE VERSION                           \e[0m" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m" && opencode --version && \
  echo "\e[0m" && \
  echo ""

EXPOSE 3000-3010

CMD ["opencode"]
