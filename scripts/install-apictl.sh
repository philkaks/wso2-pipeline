#!/bin/bash
# Install WSO2 API Controller (apictl) v4.3.0
# Run this script on the server where GitHub self-hosted runners execute

set -e

APICTL_VERSION="4.3.0"
DOWNLOAD_URL="https://github.com/wso2/product-apim-tooling/releases/download/v${APICTL_VERSION}/apictl-${APICTL_VERSION}-linux-x64.tar.gz"

echo "Installing apictl v${APICTL_VERSION}..."

# Download
curl -L "${DOWNLOAD_URL}" -o /tmp/apictl.tar.gz

# Extract
cd /tmp
tar -xvf apictl.tar.gz

# Install
sudo mv apictl /usr/local/bin/
sudo chmod +x /usr/local/bin/apictl

# Cleanup
rm -f /tmp/apictl.tar.gz

# Verify installation
echo "Verifying installation..."
apictl version

echo "apictl installed successfully!"
