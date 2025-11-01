const hre = require("hardhat");
const fs = require("fs");

// cUSD addresses
const CUSD_ADDRESSES = {
  celoSepolia: "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1", // Same as Alfajores
  alfajores: "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1",
  mainnet: "0x765DE816845861e75A25fCA122bb6898B8B1282a",
};

async function main() {
  const network = hre.network.name;
  console.log(`\n🚀 Deploying to ${network}...\n`);

  // Get cUSD address for the network
  const cUSDAddress = CUSD_ADDRESSES[network] || CUSD_ADDRESSES.alfajores;
  console.log(`📍 Using cUSD address: ${cUSDAddress}\n`);

  // Get the deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log(`👤 Deploying contracts with account: ${deployer.address}`);
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log(`💰 Account balance: ${hre.ethers.formatEther(balance)} ETH\n`);

  // Deploy DonationCampaign contract
  console.log("📝 Deploying DonationCampaign...");
  const DonationCampaign = await hre.ethers.getContractFactory("DonationCampaign");
  const donationCampaign = await DonationCampaign.deploy(cUSDAddress);

  await donationCampaign.waitForDeployment();
  const donationCampaignAddress = await donationCampaign.getAddress();

  console.log(`✅ DonationCampaign deployed to: ${donationCampaignAddress}\n`);

  // Save deployment info
  const deploymentInfo = {
    network,
    contractAddress: donationCampaignAddress,
    cUSDAddress: cUSDAddress,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    blockNumber: await hre.ethers.provider.getBlockNumber(),
  };

  // Save to file
  const deploymentsDir = "./deployments";
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }

  fs.writeFileSync(
    `${deploymentsDir}/${network}.json`,
    JSON.stringify(deploymentInfo, null, 2)
  );

  console.log("📄 Deployment info saved to:", `${deploymentsDir}/${network}.json\n`);

  // Verify contract if on testnet/mainnet
  if (network !== "hardhat" && process.env.CELOSCAN_API_KEY) {
    console.log("⏳ Waiting for block confirmations...");
    await donationCampaign.deploymentTransaction()?.wait(6);

    console.log("🔍 Verifying contract on Celoscan...");
    try {
      await hre.run("verify:verify", {
        address: donationCampaignAddress,
        constructorArguments: [cUSDAddress],
      });
      console.log("✅ Contract verified!\n");
    } catch (error) {
      console.log("⚠️  Verification failed:", error.message);
    }
  }

  console.log("\n" + "=".repeat(60));
  console.log("📋 DEPLOYMENT SUMMARY");
  console.log("=".repeat(60));
  console.log(`Network: ${network}`);
  console.log(`Contract: DonationCampaign`);
  console.log(`Address: ${donationCampaignAddress}`);
  console.log(`cUSD Token: ${cUSDAddress}`);
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Explorer: https://${network === "celoSepolia" ? "celoscan.io" : "alfajores.celoscan.io"}/address/${donationCampaignAddress}`);
  console.log("=".repeat(60) + "\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
