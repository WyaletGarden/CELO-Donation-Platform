// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DonationPlatform} from "../src/DonationPlatform.sol";

/**
 * @title DeployDonationPlatform
 * @notice Deployment script for DonationPlatform contract on Celo network
 * @dev Usage: forge script script/DeployDonationPlatform.s.sol:DeployDonationPlatform --rpc-url alfajores --broadcast --verify -vvvv
 * 
 * cUSD Addresses:
 * - Alfajores Testnet: 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1
 * - Mainnet: 0x765DE816845861e75A25fCA122bb6898B8B1282a
 */
contract DeployDonationPlatform is Script {
    DonationPlatform public donationPlatform;

    // cUSD addresses for different networks
    address constant CUSD_ALFAJORES = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
    address constant CUSD_MAINNET = 0x765DE816845861e75A25fCA122bb6898B8B1282a;

    function run() external {
        // Get private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get cUSD address (default to Alfajores, can override via env)
        address cUSDAddress;
        try vm.envAddress("CUSD_ADDRESS") returns (address _cUSDAddress) {
            cUSDAddress = _cUSDAddress;
        } catch {
            // Auto-detect network
            if (block.chainid == 44787) { // Alfajores
                cUSDAddress = CUSD_ALFAJORES;
            } else if (block.chainid == 42220) { // Mainnet
                cUSDAddress = CUSD_MAINNET;
            } else {
                // Default to Alfajores for other networks
                cUSDAddress = CUSD_ALFAJORES;
            }
        }
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract with cUSD address
        donationPlatform = new DonationPlatform(cUSDAddress);

        // Stop broadcasting
        vm.stopBroadcast();

        // Log deployment information
        console.log("================================================");
        console.log("DonationPlatform Deployed Successfully!");
        console.log("================================================");
        console.log("Contract Address:", address(donationPlatform));
        console.log("Deployer Address:", vm.addr(deployerPrivateKey));
        console.log("cUSD Token Address:", address(donationPlatform.cUSD()));
        console.log("Network Chain ID:", block.chainid);
        console.log("Total Campaigns:", donationPlatform.getTotalCampaigns());
        console.log("================================================");
    }
}
