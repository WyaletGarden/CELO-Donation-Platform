# 🚀 Quick Start - Khởi Chạy Frontend

## ✅ Đã Hoàn Thành

1. ✅ Dependencies đã được cài đặt
2. ✅ ABI đã được copy từ contract
3. ✅ Frontend đang chạy

## 🌐 Truy Cập

Frontend đang chạy tại:
- **Local:** http://localhost:3000
- Mở trình duyệt và truy cập địa chỉ trên

## ⚙️ Cấu Hình Contract Address

**Quan trọng:** Bạn cần cập nhật địa chỉ contract trong file `frontend/.env`:

```bash
VITE_CONTRACT_ADDRESS=0x...  # Địa chỉ contract sau khi deploy
```

### Lấy Contract Address:

1. **Sau khi deploy với Hardhat:**
   ```bash
   npm run deploy:celoSepolia
   # Hoặc
   npm run deploy:alfajores
   ```
   Contract address sẽ hiển thị trong console

2. **Hoặc kiểm tra file:**
   - `deployments/celoSepolia.json`
   - `deployments/alfajores.json`

3. **Copy address và paste vào `frontend/.env`**

## 🔄 Restart Frontend

Nếu bạn đã cập nhật `.env`, restart frontend:

```powershell
# Dừng frontend (Ctrl+C trong terminal)
# Sau đó chạy lại:
cd frontend
npm run dev
```

## 📝 Lưu Ý

- ⚠️ Nếu chưa deploy contract, frontend sẽ không thể tương tác với contract
- ⚠️ Đảm bảo MetaMask đã được cài đặt
- ⚠️ Cần kết nối với Celo Alfajores testnet
- ⚠️ Cần có cUSD trong ví để quyên góp

## 🎯 Các Bước Tiếp Theo

1. Deploy contract lên Celo testnet (nếu chưa deploy)
2. Cập nhật `VITE_CONTRACT_ADDRESS` trong `.env`
3. Mở http://localhost:3000 trong trình duyệt
4. Kết nối MetaMask
5. Tạo chiến dịch hoặc quyên góp!

## 🐛 Troubleshooting

**Frontend không load:**
- Kiểm tra port 3000 có bị chiếm không
- Xem console log để tìm lỗi

**Cannot connect to contract:**
- Kiểm tra `VITE_CONTRACT_ADDRESS` đã đúng chưa
- Đảm bảo contract đã được deploy

**MetaMask không connect:**
- Đảm bảo MetaMask extension đã được cài
- Kiểm tra network có phải Celo Alfajores không
