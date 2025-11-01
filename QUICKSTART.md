# Quick Start Guide - Deploy to Celo Testnet

## Step-by-Step Deployment

### 1. Get Testnet CELO
Visit https://faucet.celo.org/ and get free testnet CELO

### 2. Create .env file
```bash
# Create .env file in project root
PRIVATE_KEY=0x_your_private_key_here
CELOSCAN_API_KEY=your_api_key  # Optional for verification
```

### 3. Run Tests (Optional but Recommended)
```bash
forge test -vv
```

### 4. Deploy to Alfajores Testnet

**Windows PowerShell:**
```powershell
$env:PRIVATE_KEY="your_private_key_here"
forge script script/DeployDonationPlatform.s.sol:DeployDonationPlatform --rpc-url alfajores --broadcast --verify -vvvv
```

**Linux/Mac:**
```bash
export PRIVATE_KEY=your_private_key_here
forge script script/DeployDonationPlatform.s.sol:DeployDonationPlatform --rpc-url alfajores --broadcast --verify -vvvv
```

### 5. Verify Deployment
After deployment, you'll see:
- Contract Address
- Deployer Address  
- Owner Address
- Chain ID: 44787 (Alfajores)

View your contract on: https://alfajores.celoscan.io/

## Contract Functions

**To Donate:**
```bash
cast send <CONTRACT_ADDRESS> "donate()" --value 0.1ether --rpc-url alfajores --private-key $PRIVATE_KEY
```

**To Check Balance:**
```bash
cast call <CONTRACT_ADDRESS> "getBalance()(uint256)" --rpc-url alfajores
```

**To Withdraw (Owner Only):**
```bash
cast send <CONTRACT_ADDRESS> "withdraw()" --rpc-url alfajores --private-key $PRIVATE_KEY
```

## Troubleshooting

**Error: insufficient funds**
→ Get more testnet CELO from https://faucet.celo.org/

**Error: Only owner can withdraw**
→ Make sure you're using the owner's private key

**Need Help?**
→ See DEPLOYMENT.md for detailed documentation
