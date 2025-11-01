# 🎯 Donation Campaign DApp - Celo Blockchain

Nền tảng quyên góp minh bạch trên Celo blockchain, hỗ trợ tạo chiến dịch, quyên góp bằng cUSD, theo dõi tiến độ và rút/hoàn tiền.

## ✨ Tính Năng

### A. Tạo Chiến Dịch (Create Campaign) ✅
- **Người tạo:** Tổ chức từ thiện, cá nhân hoặc dự án xã hội
- **Thông tin chiến dịch:**
  - Tên chiến dịch (name)
  - Mô tả chi tiết (description)
  - Mục tiêu số tiền (targetAmount) - tính bằng cUSD
  - Thời hạn (deadline) - Unix timestamp
  - Địa chỉ người thụ hưởng (beneficiary)
  - URL ảnh chiến dịch (imageURL)

### B. Quyên Góp (Donate) ✅
- **Người quyên góp:** Bất kỳ ai có cUSD
- **Quy trình:**
  1. Người dùng approve cUSD cho contract
  2. Gọi hàm `donate(campaignId, amount, name, message, isAnonymous)`
  3. Contract thực hiện transferFrom từ người gửi sang campaign
  4. Lưu lại thông tin donation on-chain

### C. Theo Dõi Tiến Độ (Track Progress) ✅
- **Công khai (ai cũng xem được):**
  - Tổng số tiền đã quyên góp
  - % hoàn thành mục tiêu
  - Số lượng người ủng hộ
  - Danh sách donation (ẩn nếu isAnonymous = true)
  - Thời gian còn lại đến deadline
- **Hàm:** `getCampaignDetails(id)` trả về tất cả thông tin trên
- **Events:** Cập nhật mỗi khi có donation

### D. Rút Tiền (Withdraw) ✅
1. **Manual Withdrawal (Rút thủ công):**
   - Chủ chiến dịch có thể rút tiền bất cứ lúc nào
   - Phù hợp cho chiến dịch cần chi phí liên tục

2. **Goal-based Withdrawal (Rút khi đạt mục tiêu):**
   - Chỉ được rút khi đạt 100% mục tiêu
   - Nếu hết thời hạn mà chưa đạt mục tiêu: donors có thể `refund()` để lấy lại tiền

## 🚀 Quick Start

### 1. Cài đặt

```bash
npm install
```

### 2. Cấu hình .env

```bash
PRIVATE_KEY=your_private_key_here
CELOSCAN_API_KEY=your_api_key_here
```

### 3. Compile

```bash
npm run compile
```

### 4. Test

```bash
npm run test
```

### 5. Deploy

```bash
# Deploy to Celo Sepolia testnet
npm run deploy:celoSepolia

# Hoặc deploy to Alfajores testnet
npm run deploy:alfajores
```

## 📖 Usage Examples

### Tạo Chiến Dịch

```javascript
const ethers = require("ethers");
const deadline = Math.floor(Date.now() / 1000) + 30 * 24 * 60 * 60; // 30 days

const tx = await donationCampaign.createCampaign(
  "Help Children Education",
  "Support education for underprivileged children",
  ethers.parseEther("5000"), // 5000 cUSD target
  deadline,
  beneficiaryAddress,
  "https://example.com/campaign-image.jpg"
);
```

### Quyên Góp

```javascript
// 1. Approve cUSD
await cUSD.approve(donationCampaignAddress, ethers.parseEther("100"));

// 2. Donate
await donationCampaign.donate(
  1, // campaignId
  ethers.parseEther("100"), // 100 cUSD
  "John Doe", // donor name
  "Keep up the good work!", // message
  false // not anonymous
);
```

### Theo Dõi Tiến Độ

```javascript
const [campaign, progressPercent, timeRemaining, donationCount] =
  await donationCampaign.getCampaignDetails(campaignId);

console.log(`Campaign: ${campaign.name}`);
console.log(`Progress: ${progressPercent}%`);
console.log(`Raised: ${ethers.formatEther(campaign.raisedAmount)} cUSD`);
console.log(`Time Remaining: ${timeRemaining} seconds`);
console.log(`Donors: ${campaign.donorCount}`);
```

### Rút Tiền

```javascript
// Manual withdrawal (bất cứ lúc nào)
await donationCampaign.connect(creator).withdraw(campaignId, false);

// Goal-based withdrawal (chỉ khi đạt 100%)
await donationCampaign.connect(creator).withdraw(campaignId, true);
```

### Hoàn Tiền

```javascript
// Refund khi chiến dịch thất bại (hết hạn nhưng chưa đạt mục tiêu)
await donationCampaign.refund(campaignId);
```

## 📁 Project Structure

```
.
├── src/
│   └── DonationCampaign.sol     # Main smart contract
├── scripts/
│   └── deploy.js                # Deployment script
├── test/
│   └── DonationCampaign.test.js # Test file
├── hardhat.config.js            # Hardhat configuration
├── package.json                 # Dependencies
├── HARDHAT_SETUP.md             # Setup guide
└── README_HARDHAT.md            # This file
```

## 🌐 Networks

| Network | Chain ID | RPC URL | Explorer | cUSD Address |
|---------|----------|---------|----------|--------------|
| Celo Sepolia | 44787 | https://forno.celo-sepolia.celo-testnet.org | https://celoscan.io | 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1 |
| Alfajores | 44787 | https://alfajores-forno.celo-testnet.org | https://alfajores.celoscan.io | 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1 |
| Mainnet | 42220 | https://forno.celo.org | https://celoscan.io | 0x765DE816845861e75A25fCA122bb6898B8B1282a |

## 🔐 Security

- ✅ Sử dụng OpenZeppelin SafeERC20 để transfer tokens an toàn
- ✅ Kiểm tra điều kiện trước khi rút tiền
- ✅ Chỉ cho phép creator rút tiền
- ✅ Refund chỉ hoạt động khi chiến dịch thất bại
- ✅ Events được emit cho mọi giao dịch quan trọng

## 📝 Smart Contract Functions

### Public Functions

- `createCampaign()` - Tạo chiến dịch mới
- `donate()` - Quyên góp vào chiến dịch
- `refund()` - Hoàn tiền khi chiến dịch thất bại
- `getCampaignDetails()` - Lấy thông tin và tiến độ chiến dịch
- `getCampaignDonations()` - Lấy danh sách donations
- `getDonorContribution()` - Lấy tổng đóng góp của donor
- `canRefund()` - Kiểm tra có thể refund không

### Creator Functions

- `withdraw(campaignId, isGoalBased)` - Rút tiền (manual hoặc goal-based)

## 🧪 Testing

```bash
# Chạy tất cả tests
npm test

# Chạy với coverage
npx hardhat coverage
```

## 📚 Documentation

- [HARDHAT_SETUP.md](./HARDHAT_SETUP.md) - Hướng dẫn setup chi tiết
- [Contract Code](./src/DonationCampaign.sol) - Source code đầy đủ

## 🔗 Links

- [Celo Documentation](https://docs.celo.org/)
- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Celo Faucet](https://faucet.celo.org/)

## 📄 License

MIT

---

**Developed for Celo Blockchain** 🌟
