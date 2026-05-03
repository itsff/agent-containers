# Build stage
FROM agent-base AS builder

# Install Pi via official installer script
RUN curl -fsSL https://pi.dev/install.sh | sh && \
  echo "Installed Pi version: $(pi --version)"

# Runtime stage
FROM agent-base

# Copy the installed tooling from builder
COPY --from=builder --chown=ubuntu:ubuntu /home/ubuntu/.npm-global /home/ubuntu/.npm-global

# Display version information
RUN echo "" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m                           PI VERSION                            \e[0m" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m" && pi --version && \
  echo "\e[0m" && \
  echo ""

CMD ["pi"]
