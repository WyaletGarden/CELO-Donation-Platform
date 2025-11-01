const fs = require('fs');
const path = require('path');

// Copy ABI từ Hardhat artifacts
const artifactPath = path.join(__dirname, '../artifacts/src/DonationCampaign.sol/DonationCampaign.json');
const targetPath = path.join(__dirname, '../frontend/src/abi/DonationCampaign.json');

try {
  if (fs.existsSync(artifactPath)) {
    const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
    const abi = artifact.abi;
    
    // Đảm bảo thư mục tồn tại
    const abiDir = path.dirname(targetPath);
    if (!fs.existsSync(abiDir)) {
      fs.mkdirSync(abiDir, { recursive: true });
    }
    
    fs.writeFileSync(targetPath, JSON.stringify(abi, null, 2));
    console.log('✅ ABI copied from Hardhat artifacts');
    console.log(`   From: ${artifactPath}`);
    console.log(`   To: ${targetPath}`);
  } else {
    console.log('⚠️  Hardhat artifacts not found. Trying Foundry...');
    
    // Try Foundry out folder
    const foundryPath = path.join(__dirname, '../out/DonationCampaign.sol/DonationCampaign.json');
    if (fs.existsSync(foundryPath)) {
      const artifact = JSON.parse(fs.readFileSync(foundryPath, 'utf8'));
      const abi = artifact.abi;
      
      const abiDir = path.dirname(targetPath);
      if (!fs.existsSync(abiDir)) {
        fs.mkdirSync(abiDir, { recursive: true });
      }
      
      fs.writeFileSync(targetPath, JSON.stringify(abi, null, 2));
      console.log('✅ ABI copied from Foundry out');
      console.log(`   From: ${foundryPath}`);
      console.log(`   To: ${targetPath}`);
    } else {
      console.log('❌ ABI file not found. Please compile contracts first:');
      console.log('   For Hardhat: npm run compile');
      console.log('   For Foundry: forge build');
      process.exit(1);
    }
  }
} catch (error) {
  console.error('Error copying ABI:', error);
  process.exit(1);
}
