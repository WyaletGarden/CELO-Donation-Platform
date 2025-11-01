# Donation Platform - Celo Deployment Guide

A simple donation platform smart contract for social impact projects on Celo network.

## Features

- ✅ Simple donate functionality - anyone can donate CELO
- ✅ Track donations per donor
- ✅ Owner can withdraw funds
- ✅ Event emissions for transparency
- ✅ Comprehensive test coverage

## Prerequisites

1. **Install Foundry**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Get Testnet CELO**
   - Visit [Celo Faucet](https://faucet.celo.org/)
   - Connect your wallet (MetaMask recommended)
   - Request testnet CELO (Alfajores testnet)

3. **Set up Environment Variables**
   ```bash
   # Copy the example file
   cp .env.example .env
   
   # Edit .env and add your private key
   # Get your private key from MetaMask: Account Details → Export Private Key
   ```

## Configuration

### 1. Get Your Private Key

**Important Security Note:** Never share your private key or commit it to version control!

- Open MetaMask
- Click on your account → Account Details → Export Private Key
- Copy your private key (starts with `0x`)

### 2. Update .env File

```bash
PRIVATE_KEY=0x your_private_key_here_without_spaces
CELOSCAN_API_KEY=your_celoscan_api_key_here  # Optional for verification
```

## Running Tests

Test the contract locally before deploying:

```bash
forge test -vvv
```

For more verbose output:

```bash
forge test -vvvv
```

## Deployment to Celo Alfajores Testnet

### Quick Start (Recommended)

**Using the deployment script (easiest):**
```bash
# Create a .env file first (see Configuration section above)
# Then simply run:
./deploy.sh
```

The script will:
- ✅ Automatically load environment variables from `.env` file
- ✅ Validate that PRIVATE_KEY is set and properly formatted
- ✅ Build the contracts
- ✅ Deploy to Alfajores testnet
- ✅ Provide clear error messages if something is missing

### Manual Deployment Steps

### Step 1: Build the Contract

```bash
forge build
```

### Step 2: Deploy to Alfajores Testnet

**Basic deployment (no verification):**
```bash
forge script script/DeployDonationPlatform.s.sol:DeployDonationPlatform \
    --rpc-url alfajores \
    --broadcast \
    --verify \
    -vvvv
```

**With environment variable for RPC:**
```bash
export PRIVATE_KEY=your_private_key_here
forge script script/DeployDonationPlatform.s.sol:DeployDonationPlatform \
    --rpc-url $ALFAJORES_RPC_URL \
    --broadcast \
    --verify \
    -vvvv
```

**Using .env file (recommended):**
```bash
source .env
forge script script/DeployDonationPlatform.s.sol:DeployDonationPlatform \
    --rpc-url alfajores \
    --broadcast \
    --verify \
    -vvvv
```

### Step 3: Verify Deployment

After deployment, you'll see output like:
```
================================================
DonationPlatform Deployed Successfully!
================================================
Contract Address: 0x...
Deployer Address: 0x...
Owner Address: 0x...
Network Chain ID: 44787
================================================
```

### Step 4: View on Celoscan

1. Go to [Celoscan Alfajores](https://alfajores.celoscan.io/)
2. Search for your contract address
3. Verify the contract source code (if you included `--verify`)

## Contract Verification (Optional)

To verify your contract on Celoscan:

```bash
forge verify-contract \
    <CONTRACT_ADDRESS> \
    src/DonationPlatform.sol:DonationPlatform \
    --chain-id 44787 \
    --etherscan-api-key $CELOSCAN_API_KEY \
    --compiler-version $(forge --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
```

## Interacting with the Contract

### Using Foundry Cast

**Donate:**
```bash
cast send <CONTRACT_ADDRESS> \
    "donate()" \
    --value 0.1ether \
    --rpc-url alfajores \
    --private-key $PRIVATE_KEY
```

**Check Balance:**
```bash
cast call <CONTRACT_ADDRESS> \
    "getBalance()(uint256)" \
    --rpc-url alfajores
```

**Withdraw (Owner only):**
```bash
cast send <CONTRACT_ADDRESS> \
    "withdraw()" \
    --rpc-url alfajores \
    --private-key $PRIVATE_KEY
```

### Using Remix IDE

1. Go to [Remix IDE](https://remix.ethereum.org/)
2. Connect to Alfajores testnet in MetaMask
3. Load your contract ABI from `out/DonationPlatform.sol/DonationPlatform.json`
4. Interact with functions through Remix UI

## Network Information

### Alfajores Testnet
- **Chain ID:** 44787
- **RPC URL:** https://alfajores-forno.celo-testnet.org
- **Explorer:** https://alfajores.celoscan.io/
- **Faucet:** https://faucet.celo.org/

### Celo Mainnet
- **Chain ID:** 42220
- **RPC URL:** https://forno.celo.org
- **Explorer:** https://celoscan.io/

## Contract Functions

### Public Functions

- `donate()` - Payable function to donate CELO
- `getBalance()` - View current contract balance
- `getDonationByDonor(address)` - Get donation amount by donor address
- `getTotalDonors()` - Get total number of unique donors
- `getAllDonors()` - Get array of all donor addresses

### Owner Functions

- `withdraw()` - Withdraw all funds to owner
- `transferOwnership(address)` - Transfer ownership to new address

### Events

- `DonationReceived(address indexed donor, uint256 amount, uint256 timestamp)`
- `FundsWithdrawn(address indexed owner, uint256 amount, uint256 timestamp)`
- `OwnershipTransferred(address indexed previousOwner, address indexed newOwner)`

## Security Notes

1. **Never share your private key**
2. **Always test on testnet first**
3. **Verify contract source code on explorer**
4. **Only withdraw funds you trust**
5. **Keep your `.env` file in `.gitignore`**

## Troubleshooting

### Error: "insufficient funds"
- Make sure your account has enough CELO for gas fees
- Get testnet CELO from [Celo Faucet](https://faucet.celo.org/)

### Error: "Only owner can withdraw"
- Make sure you're calling `withdraw()` from the owner address
- Check the owner address: `cast call <CONTRACT> "owner()(address)" --rpc-url alfajores`

### Verification fails
- Make sure your `CELOSCAN_API_KEY` is set correctly
- Check that compiler version matches
- Ensure contract was deployed with `--verify` flag

## References

- [Celo Documentation](https://docs.celo.org/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Celo Quickstart](https://docs.celo.org/build-on-celo/quickstart)
- [Remix with Celo](https://docs.celo.org/tooling/dev-environments/remix)

## License

MIT
