#!/bin/bash

# DeployDonationPlatform Deployment Script
# This script handles deployment to Celo networks with proper environment variable setup

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default network
NETWORK="${1:-alfajores}"
RPC_URL="${2:-https://alfajores-forno.celo-testnet.org}"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}DonationPlatform Deployment Script${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Check if .env file exists and load it
if [ -f .env ]; then
    echo -e "${YELLOW}Loading environment variables from .env file...${NC}"
    export $(grep -v '^#' .env | xargs)
else
    echo -e "${YELLOW}.env file not found. Using environment variables from shell.${NC}"
fi

# Check if PRIVATE_KEY is set
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY environment variable is not set!${NC}"
    echo ""
    echo "Please set PRIVATE_KEY in one of the following ways:"
    echo "  1. Create a .env file with: PRIVATE_KEY=0xYourPrivateKey"
    echo "  2. Export it in your shell: export PRIVATE_KEY=0xYourPrivateKey"
    echo ""
    echo "Example .env file:"
    echo "  PRIVATE_KEY=0x1234567890abcdef..."
    echo "  CELOSCAN_API_KEY=your_api_key_here  # Optional"
    exit 1
fi

# Validate PRIVATE_KEY format (should start with 0x and be 66 characters)
if [[ ! $PRIVATE_KEY =~ ^0x[a-fA-F0-9]{64}$ ]]; then
    echo -e "${RED}Error: PRIVATE_KEY format is invalid!${NC}"
    echo "Private key should:"
    echo "  - Start with '0x'"
    echo "  - Be 64 hexadecimal characters (66 total with 0x prefix)"
    exit 1
fi

echo -e "${GREEN}✓ PRIVATE_KEY is set${NC}"
echo -e "${GREEN}✓ Network: $NETWORK${NC}"
echo -e "${GREEN}✓ RPC URL: $RPC_URL${NC}"
echo ""

# Check if forge is installed
if ! command -v forge &> /dev/null; then
    echo -e "${RED}Error: forge command not found!${NC}"
    echo "Please install Foundry: https://book.getfoundry.sh/getting-started/installation"
    exit 1
fi

# Build the contract first
echo -e "${YELLOW}Building contracts...${NC}"
forge build
echo ""

# Check deployer balance
echo -e "${YELLOW}Checking deployer balance...${NC}"
DEPLOYER_ADDR=$(cast wallet address --private-key "$PRIVATE_KEY" 2>/dev/null || echo "")
if [ ! -z "$DEPLOYER_ADDR" ]; then
    BALANCE=$(cast balance "$DEPLOYER_ADDR" --rpc-url "$RPC_URL" 2>/dev/null || echo "0")
    echo -e "${GREEN}Deployer: $DEPLOYER_ADDR${NC}"
    echo -e "${GREEN}Balance: $(cast --to-unit "$BALANCE" ether 2>/dev/null || echo "$BALANCE") CELO${NC}"
    
    if [ "$BALANCE" = "0" ] || [ -z "$BALANCE" ]; then
        echo ""
        echo -e "${RED}⚠️  WARNING: Deployer account has insufficient funds!${NC}"
        echo -e "${YELLOW}Please get testnet CELO from:${NC}"
        echo -e "${CYAN}   https://faucet.celo.org/${NC}"
        echo -e "${CYAN}   OR${NC}"
        echo -e "${CYAN}   https://celo.org/developers/faucet${NC}"
        echo ""
        echo -e "${YELLOW}Send CELO to: $DEPLOYER_ADDR${NC}"
        echo ""
        read -p "Press Enter to continue anyway, or Ctrl+C to cancel..."
    fi
fi

# Run the deployment script
echo ""
echo -e "${YELLOW}Deploying DonationPlatform to $NETWORK...${NC}"
echo ""

forge script script/DeployDonationPlatform.s.sol:DeployDonationPlatform \
    --rpc-url "$RPC_URL" \
    --broadcast \
    -vvvv

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Deployment completed!${NC}"
echo -e "${GREEN}================================================${NC}"

