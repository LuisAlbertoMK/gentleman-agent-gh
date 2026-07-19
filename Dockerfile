# Dockerfile — Gentleman Agent development environment
# Provides PowerShell 7.6+, Node.js 20, Python 3, Git
FROM mcr.microsoft.com/powershell:lts-7.4-ubuntu-22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies (no curl|bash — use apt only)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    git \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS via NodeSource (no curl|bash — use gpg key + apt)
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

# Install Python packages (use pipx to avoid system conflicts)
RUN pip3 install --no-cache-dir --break-system-packages pre-commit

# Set working directory
WORKDIR /workspace

# Copy project files
COPY . .

# Fix permissions for vscode user
RUN chown -R vscode:vscode /workspace

# Install npm dev dependencies (fail loudly on errors)
RUN npm install --no-fund --no-audit

# Default shell
CMD ["pwsh"]
