#!/bin/bash

# Script to get contract address from deployment and set it in frontend .env

echo "=================================================="
echo "Contract Address Helper"
echo "=================================================="
echo ""

# Check if contract was deployed with Foundry
if [ -f "broadcast/DeployDonationPlatform.s.sol/44787/run-latest.json" ]; then
    echo "Found Foundry deployment files..."
    CONTRACT_ADDR=$(cat broadcast/DeployDonationPlatform.s.sol/44787/run-latest.json | grep -o '"contractAddress":"0x[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ ! -z "$CONTRACT_ADDR" ]; then
        echo "✅ Contract Address: $CONTRACT_ADDR"
        echo ""
        
        # Check if frontend .env exists
        if [ -f "frontend/.env" ]; then
            echo "Updating frontend/.env..."
            # Remove old VITE_CONTRACT_ADDRESS if exists
            sed -i.bak '/VITE_CONTRACT_ADDRESS/d' frontend/.env
            # Add new address
            echo "VITE_CONTRACT_ADDRESS=$CONTRACT_ADDR" >> frontend/.env
            echo "✅ Updated frontend/.env"
        else
            echo "Creating frontend/.env..."
            echo "VITE_CONTRACT_ADDRESS=$CONTRACT_ADDR" > frontend/.env
            echo "✅ Created frontend/.env"
        fi
        echo ""
        echo "⚠️  IMPORTANT: Restart your frontend dev server for changes to take effect!"
        exit 0
    fi
fi

# Check Hardhat deployments
if [ -d "deployments" ]; then
    DEPLOYMENT_FILE=$(find deployments -name "*.json" -type f | head -1)
    if [ ! -z "$DEPLOYMENT_FILE" ]; then
        echo "Found Hardhat deployment file: $DEPLOYMENT_FILE"
        CONTRACT_ADDR=$(grep -o '"contractAddress":"0x[^"]*"' "$DEPLOYMENT_FILE" | head -1 | cut -d'"' -f4)
        
        if [ ! -z "$CONTRACT_ADDR" ]; then
            echo "✅ Contract Address: $CONTRACT_ADDR"
            echo ""
            
            if [ -f "frontend/.env" ]; then
                echo "Updating frontend/.env..."
                sed -i.bak '/VITE_CONTRACT_ADDRESS/d' frontend/.env
                echo "VITE_CONTRACT_ADDRESS=$CONTRACT_ADDR" >> frontend/.env
                echo "✅ Updated frontend/.env"
            else
                echo "Creating frontend/.env..."
                echo "VITE_CONTRACT_ADDRESS=$CONTRACT_ADDR" > frontend/.env
                echo "✅ Created frontend/.env"
            fi
            echo ""
            echo "⚠️  IMPORTANT: Restart your frontend dev server for changes to take effect!"
            exit 0
        fi
    fi
fi

echo "❌ No deployment found!"
echo ""
echo "Please deploy the contract first:"
echo "  ./deploy.sh"
echo "  OR"
echo "  forge script script/DeployDonationPlatform.s.sol:DeployDonationPlatform --rpc-url alfajores --broadcast -vvvv"
echo ""
echo "After deployment, run this script again to update frontend/.env"

