# Dockerfile — Gentleman Agent development environment
# Multi-stage: build stage (deps) + runtime stage (slim)

# === BUILD STAGE ===
FROM mcr.microsoft.com/powershell:lts-7.4-ubuntu-22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    git \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS via NodeSource
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell modules
RUN pwsh -Command "Set-PSRepository PSGallery -InstallationPolicy Trusted; \
    Install-Module -Name PowerShellGet -Force -AllowClobber -Scope AllUsers; \
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope AllUsers"

# Install Python packages
RUN pip3 install --no-cache-dir --break-system-packages pre-commit

WORKDIR /workspace

# Copy dependency manifests first (layer caching)
COPY package*.json ./
RUN npm install --no-fund --no-audit

# === RUNTIME STAGE ===
FROM mcr.microsoft.com/powershell:lts-7.4-ubuntu-22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime dependencies (no build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Copy Node.js from builder
COPY --from=builder /usr/bin/node /usr/bin/node
COPY --from=builder /usr/lib/node_modules /usr/lib/node_modules

# Copy PowerShell modules from builder
COPY --from=builder /opt/microsoft/powershell/7 /opt/microsoft/powershell/7
COPY --from=builder /usr/local/share/powershell/Modules /usr/local/share/powershell/Modules

# Copy Python packages from builder
COPY --from=builder /usr/lib/python3/dist-packages /usr/lib/python3/dist-packages
COPY --from=builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages

# Copy pre-commit from builder
COPY --from=builder /usr/local/bin/pre-commit /usr/local/bin/pre-commit

WORKDIR /workspace

# Copy project files
COPY . .

# Fix permissions for vscode user
RUN chown -R vscode:vscode /workspace

# Switch to non-root user
USER vscode

# Default shell
CMD ["pwsh"]
