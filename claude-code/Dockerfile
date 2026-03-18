# Build stage
FROM agent-base AS builder

# Install build dependencies and Claude Code
RUN npm install -g @anthropic-ai/claude-code && \
  echo "Installed Claude Code version: $(claude --version)"

# Runtime stage
FROM agent-base

# Copy the installed Claude Code from builder
# We must use --chown to ensure the ubuntu user owns the copied files
COPY --from=builder --chown=ubuntu:ubuntu /home/ubuntu/.npm-global /home/ubuntu/.npm-global

# Display version information
RUN echo "" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m                   CLAUDE CODE VERSION                           \e[0m" && \
  echo "\e[34m=================================================================\e[0m" && \
  echo "\e[34m" && claude --version && \
  echo "\e[0m" && \
  echo ""

CMD ["claude"]
