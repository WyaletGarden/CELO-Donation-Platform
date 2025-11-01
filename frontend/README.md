# Donation Campaign Frontend

Frontend React application để tương tác với Donation Campaign smart contract trên Celo blockchain.

## 🚀 Cài Đặt

```bash
cd frontend
npm install
```

## ⚙️ Cấu Hình

1. Copy contract ABI vào `src/abi/DonationCampaign.json`

   Để lấy ABI:
   ```bash
   # Từ Hardhat artifacts
   cp ../artifacts/src/DonationCampaign.sol/DonationCampaign.json src/abi/DonationCampaign.json
   
   # Hoặc từ Foundry out
   cp ../out/DonationCampaign.sol/DonationCampaign.json src/abi/DonationCampaign.json
   ```

2. Tạo file `.env` trong folder `frontend`:

```bash
VITE_CONTRACT_ADDRESS=0x...  # Địa chỉ contract sau khi deploy
```

## 🏃 Chạy Ứng Dụng

```bash
npm run dev
```

Ứng dụng sẽ chạy tại `http://localhost:3000`

## 📦 Build

```bash
npm run build
```

Files build sẽ nằm trong folder `dist/`

## 🔧 Tính Năng

- ✅ Kết nối MetaMask wallet
- ✅ Tự động chuyển sang Celo network
- ✅ Tạo chiến dịch quyên góp
- ✅ Quyên góp bằng cUSD
- ✅ Theo dõi tiến độ chiến dịch
- ✅ Rút tiền (Manual & Goal-based)
- ✅ Hoàn tiền khi chiến dịch thất bại
- ✅ Hiển thị danh sách donations
- ✅ UI/UX đẹp và responsive

## 📝 Lưu Ý

1. Đảm bảo đã deploy contract trước khi chạy frontend
2. Cần có cUSD trong ví để quyên góp
3. MetaMask phải được cài đặt và cấu hình Celo network

## 🎨 Tech Stack

- **React** - UI framework
- **Vite** - Build tool
- **ethers.js** - Ethereum/Celo interaction
- **React Icons** - Icons

## 📚 Scripts

- `npm run dev` - Chạy development server
- `npm run build` - Build cho production
- `npm run preview` - Preview build
